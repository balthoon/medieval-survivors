## Fires every equipped weapon, each on its own cadence and at its own target.
##
## The player carries up to three weapons. Each one carries an independent
## cooldown and picks the nearest enemy inside its own range, so a dagger, a
## hammer and a bow all attack in the same frame against different targets.
## Melee weapons get a [WeaponView]; projectile weapons spawn [Projectile]s.
class_name WeaponSystem
extends Node

## Emitted after every resolved hit, with the crit flag, the damage dealt and
## the impact position.
signal hit_landed(is_crit: bool, amount: float, at: Vector2)

## Player statistics, including the equipment multipliers. Set by setup().
var stats: Stats = null
## Equipped weapons and equipment. Set by setup().
var inventory: Inventory = null
## The node melee views attach to and weapons fire from. Set by setup().
var player: Player = null
## Source of enemies and their positions. Set by setup().
var enemy_manager: EnemyManager = null
## Container the fired bolts are added to. Set by setup().
var projectile_layer: Node2D = null
## Shared roll source, so crits stay deterministic under a seeded RNG.
var rng: RandomNumberGenerator = null
## Floating damage numbers and death shards. Assigned by main.gd after setup().
var fx: Fx = null
## One-shot sound effects. Assigned by main.gd after setup().
var sfx: Sfx = null

## Angular gap between two idle weapons, in radians. Without it the carried
## weapons all overlap on the same angle and only the longest one is seen.
const FAN_SPACING := 0.28

## Fraction of a melee swing after which its damage lands. Delaying the hit lets
## the blade visibly travel before the numbers and the knockback appear.
const IMPACT_FRACTION := 0.45

## Seconds until each weapon may fire again, indexed like inventory.weapons.
var _cooldowns: Array[float] = []
## Drawn view per weapon, null for projectile weapons.
var _views: Array[WeaponView] = []
## Bolts currently in flight.
var _projectiles: Array[Projectile] = []
## Melee hits waiting for their impact frame; each entry holds the weapon, the
## locked angle, the reach and the seconds left.
var _pending_hits: Array[Dictionary] = []


## Wires the system. Call once at run start, after the player and the enemy
## manager exist.
func setup(
	run_stats: Stats,
	run_inventory: Inventory,
	run_player: Player,
	run_enemy_manager: EnemyManager,
	run_projectile_layer: Node2D,
	run_rng: RandomNumberGenerator
) -> void:
	stats = run_stats
	inventory = run_inventory
	player = run_player
	enemy_manager = run_enemy_manager
	projectile_layer = run_projectile_layer
	rng = run_rng
	refresh()


## Rebuilds the drawn views and the cooldown array. Call after the inventory
## changes: a new weapon must get a view and its own timer.
func refresh() -> void:
	if inventory == null or player == null or stats == null:
		return

	for view in _views:
		if view != null and is_instance_valid(view):
			view.queue_free()
	_views.clear()

	var old_cooldowns := _cooldowns.duplicate()
	_cooldowns.clear()

	for index in inventory.weapons.size():
		var weapon := inventory.weapons[index]
		_cooldowns.append(_remaining_for(index, old_cooldowns))
		if weapon != null and weapon.kind == "melee":
			var view := WeaponView.new()
			view.setup(weapon, stats.weapon_range(weapon))
			player.add_child(view)
			_views.append(view)
		else:
			_views.append(null)


## Advances every cooldown, aims every view, and fires whatever is ready.
func step(delta: float) -> void:
	if stats == null or inventory == null or player == null or player.stats == null:
		return

	_step_projectiles(delta)
	_step_pending_hits(delta)

	for index in inventory.weapons.size():
		var weapon := inventory.weapons[index]
		if weapon == null:
			continue
		if index >= _cooldowns.size():
			_cooldowns.resize(inventory.weapons.size())
		_cooldowns[index] = maxf(_cooldowns[index] - delta, 0.0)

		var view: WeaponView = _views[index] if index < _views.size() else null
		if view != null:
			view.set_facing(player.facing + _fan_offset(index))
			view.step(delta)

		if enemy_manager == null:
			continue
		var reach := stats.weapon_range(weapon)
		var target := enemy_manager.nearest_within(player.position, reach)
		if target == null or _cooldowns[index] > 0.0:
			continue

		_cooldowns[index] = 1.0 / stats.weapon_attacks_per_second(weapon)
		var angle := (target.position - player.position).angle()
		if weapon.kind == "projectile":
			_fire_projectile(weapon, angle)
		else:
			_swing(weapon, angle, reach, view)


## Seconds of cooldown left on a weapon, in seconds. Zero when ready. Used by
## the HUD to draw the recharge bars.
func cooldown_seconds(index: int) -> float:
	if index < 0 or index >= _cooldowns.size():
		return 0.0
	return maxf(_cooldowns[index], 0.0)


## Fraction of a weapon's cadence still to wait, in 0..1. Used by the HUD.
func cooldown_ratio(index: int) -> float:
	if stats == null or inventory == null:
		return 0.0
	if index < 0 or index >= inventory.weapons.size():
		return 0.0
	var weapon := inventory.weapons[index]
	if weapon == null:
		return 0.0
	var interval := 1.0 / stats.weapon_attacks_per_second(weapon)
	if interval <= 0.0:
		return 0.0
	return clampf(cooldown_seconds(index) / interval, 0.0, 1.0)


## Starts one melee swing. Damage is not applied here: the hit is queued and
## resolved at IMPACT_FRACTION through the swing, against wherever the enemies
## stand when the blade actually lands.
func _swing(weapon: WeaponData, angle: float, reach: float, view: WeaponView) -> void:
	if view != null:
		view.start_swing(angle)
	_pending_hits.append({
		"weapon": weapon,
		"angle": angle,
		"reach": reach,
		"time_left": weapon.swing_duration * IMPACT_FRACTION,
	})


## Spawns one bolt along [param angle].
func _fire_projectile(weapon: WeaponData, angle: float) -> void:
	if projectile_layer == null:
		return
	var bolt := Projectile.create(
		weapon, stats, rng, player.position, Vector2.RIGHT.rotated(angle)
	)
	bolt.hit_resolved.connect(_on_projectile_hit_resolved.bind(weapon))
	projectile_layer.add_child(bolt)
	_projectiles.append(bolt)


## Advances every queued melee hit and resolves the ones whose impact frame has
## arrived.
func _step_pending_hits(delta: float) -> void:
	if _pending_hits.is_empty():
		return

	var still_pending: Array[Dictionary] = []
	for pending in _pending_hits:
		pending["time_left"] = float(pending["time_left"]) - delta
		if float(pending["time_left"]) > 0.0:
			still_pending.append(pending)
		else:
			_resolve_melee_hit(pending)
	_pending_hits = still_pending


## Resolves one queued swing: the cone is queried again at impact time, so an
## enemy that walked out of it is spared and one that walked in is hit.
func _resolve_melee_hit(pending: Dictionary) -> void:
	if stats == null or player == null or enemy_manager == null:
		return
	var weapon: WeaponData = pending["weapon"]
	if weapon == null:
		return

	var angle := float(pending["angle"])
	var reach := float(pending["reach"])
	var half_angle := deg_to_rad(weapon.arc_degrees * 0.5)
	var targets := enemy_manager.query_arc(player.position, angle, reach, half_angle)
	for enemy in targets:
		var hit := DamageCalc.roll(stats, weapon, rng)
		var amount := float(hit["amount"])
		var is_crit := bool(hit["is_crit"])
		enemy.take_damage(amount, is_crit)
		enemy.apply_knockback(player.position, weapon.knockback)
		if fx != null:
			fx.spawn_number(enemy.position, amount, is_crit)
		if sfx != null:
			sfx.play(_impact_sound(weapon, is_crit))
		hit_landed.emit(is_crit, amount, enemy.position)


## Reports one projectile hit once the bolt has resolved it: floating number,
## impact sound and the hit_landed signal. The weapon is bound at connect time,
## because the signal itself only carries the damage.
func _on_projectile_hit_resolved(
	amount: float, is_crit: bool, at: Vector2, weapon: WeaponData
) -> void:
	if fx != null:
		fx.spawn_number(at, amount, is_crit)
	if sfx != null and weapon != null:
		sfx.play(_impact_sound(weapon, is_crit))
	hit_landed.emit(is_crit, amount, at)


## Sound id for one impact: crits ring, heavy weapons thud, everything else taps.
func _impact_sound(weapon: WeaponData, is_crit: bool) -> String:
	if is_crit:
		return "hit_crit"
	if weapon != null and weapon.damage >= 20.0:
		return "hit_heavy"
	return "hit_light"


## Moves every bolt and frees the spent ones.
func _step_projectiles(delta: float) -> void:
	var still_flying: Array[Projectile] = []
	for bolt in _projectiles:
		if bolt == null or not is_instance_valid(bolt):
			continue
		if bolt.step(delta, enemy_manager):
			bolt.queue_free()
			continue
		still_flying.append(bolt)
	_projectiles = still_flying


## Idle angle offset of one weapon, so several carried weapons fan out around the
## facing instead of drawing on top of each other.
func _fan_offset(index: int) -> float:
	if inventory == null or inventory.weapons.size() <= 1:
		return 0.0
	var count := float(inventory.weapons.size())
	return (float(index) - (count - 1.0) * 0.5) * FAN_SPACING


## Cooldown left on a weapon before a refresh, so gaining a weapon does not reset
## the timers of the ones already carried.
func _remaining_for(index: int, previous: Array[float]) -> float:
	if index < previous.size():
		return previous[index]
	return 0.0
