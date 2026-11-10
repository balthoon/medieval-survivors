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

## Emitted exactly once each time a weapon actually fires, with the angle it fired
## along. The player uses it to lean the body into every swing and every shot.
signal attack_started(angle: float)

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

## Shortest cooldown the dagger's execution refund may set. The floor keeps the
## refund independent of the frame rate, exactly like the boss slam cooldown.
const EXECUTION_MIN_COOLDOWN := 1.0 / 60.0

## Seconds until each weapon may fire again, indexed like inventory.weapons.
var _cooldowns: Array[float] = []
## Drawn view per weapon, null for projectile and orbit weapons.
var _views: Array[WeaponView] = []
## Orbiting moon per weapon, null for every other mechanic.
var _orbits: Array[OrbitBlade] = []
## Bolts currently in flight.
var _projectiles: Array[Projectile] = []
## Censers in flight or burning their fuse.
var _censer_bombs: Array[CenserBomb] = []
## Melee hits waiting for their impact frame; each entry holds the weapon, the
## inventory index, the locked angle, the reach and the seconds left.
var _pending_hits: Array[Dictionary] = []
## Unknown mechanic tokens already warned about, so a typo warns once rather
## than once per frame.
var _warned_mechanics: Dictionary = {}


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


## Rebuilds the drawn views, the orbit moons and the cooldown array. Call after
## the inventory changes: a new weapon must get its own visual and timer.
func refresh() -> void:
	if inventory == null or player == null or stats == null:
		return

	for view in _views:
		if view != null and is_instance_valid(view):
			view.queue_free()
	_views.clear()
	for orbit in _orbits:
		if orbit != null and is_instance_valid(orbit):
			orbit.queue_free()
	_orbits.clear()

	var old_cooldowns := _cooldowns.duplicate()
	_cooldowns.clear()

	for index in inventory.weapons.size():
		var weapon := inventory.weapons[index]
		_cooldowns.append(_remaining_for(index, old_cooldowns))
		_views.append(null)
		_orbits.append(null)
		if weapon == null:
			continue

		_warn_unknown_mechanic(weapon)
		if weapon.mechanic == &"orbit":
			var orbit := OrbitBlade.new()
			orbit.setup(weapon, stats, rng, player, enemy_manager)
			orbit.hit_landed.connect(_on_extra_hit_landed.bind(weapon))
			player.add_child(orbit)
			_orbits[index] = orbit
		elif weapon.kind == "melee":
			var view := WeaponView.new()
			view.setup(weapon, stats.weapon_range(weapon))
			player.add_child(view)
			_views[index] = view


## Advances every cooldown, aims every view, and fires whatever is ready.
func step(delta: float) -> void:
	if stats == null or inventory == null or player == null or player.stats == null:
		return

	_step_projectiles(delta)
	_step_censer_bombs(delta)
	_step_pending_hits(delta)
	_step_orbits(delta)

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

		# The orbit moon is struck on contact by OrbitBlade.step(); it has no
		# cadence and no target of its own.
		if weapon.mechanic == &"orbit":
			continue
		if enemy_manager == null:
			continue
		var reach := stats.weapon_range(weapon)
		var target := enemy_manager.nearest_within(player.position, reach)
		if target == null or _cooldowns[index] > 0.0:
			continue

		_cooldowns[index] = 1.0 / stats.weapon_attacks_per_second(weapon)
		var angle := (target.position - player.position).angle()
		# One emission per shot that actually fires: every branch below has just
		# paid this weapon's cooldown. The orbit moon never reaches this point.
		attack_started.emit(angle)
		if weapon.mechanic == &"fuse":
			_throw_censer(weapon, target, reach)
		elif weapon.kind == "projectile":
			_fire_projectile(weapon, angle)
		else:
			_swing(weapon, angle, reach, view, index)


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
## stand when the blade actually lands. The inventory index travels with the
## hit so the dagger's execution refund can reach the right cooldown.
func _swing(
	weapon: WeaponData, angle: float, reach: float, view: WeaponView, index: int
) -> void:
	if view != null:
		view.start_swing(angle)
	_pending_hits.append({
		"weapon": weapon,
		"index": index,
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
## enemy that walked out of it is spared and one that walked in is hit. The
## weapon's own mechanic runs per victim: stagger delays a windup, lifesteal
## returns part of the health actually removed, and an execution kill refunds
## the dagger's cooldown.
func _resolve_melee_hit(pending: Dictionary) -> void:
	if stats == null or player == null or enemy_manager == null:
		return
	var weapon: WeaponData = pending["weapon"]
	if weapon == null:
		return

	var index := int(pending.get("index", -1))
	var angle := float(pending["angle"])
	var reach := float(pending["reach"])
	# A 360° sweep is a full circle, not a half-angle comparison: Vector2.angle_to
	# returns a float32-rounded PI, a hair larger than deg_to_rad(180), which would
	# otherwise exclude an enemy standing exactly behind the player.
	var half_angle := PI if weapon.arc_degrees >= 360.0 else deg_to_rad(weapon.arc_degrees * 0.5)
	var targets := enemy_manager.query_arc(player.position, angle, reach, half_angle)
	var hit_this_swing: Array[Enemy] = []
	for enemy in targets:
		var hp_before := enemy.hp
		var hit := DamageCalc.roll(stats, weapon, rng)
		var amount := float(hit["amount"])
		var is_crit := bool(hit["is_crit"])
		var killed := enemy.take_damage(amount, is_crit)
		enemy.apply_knockback(player.position, weapon.knockback)
		hit_this_swing.append(enemy)

		if weapon.mechanic == &"stagger":
			enemy.interrupt_windup(weapon.stagger_seconds)
		elif weapon.mechanic == &"lifesteal" and not _is_elite(enemy):
			var dealt := minf(amount, hp_before)
			player.heal(dealt * weapon.lifesteal_ratio)
		elif (
			killed
			and weapon.mechanic == &"execution"
			and weapon.execution_floor > 0.0
			and index >= 0
			and index < _cooldowns.size()
		):
			_cooldowns[index] = maxf(weapon.execution_floor, EXECUTION_MIN_COOLDOWN)

		if fx != null:
			fx.spawn_number(enemy.position, amount, is_crit)
		if sfx != null:
			sfx.play(_impact_sound(weapon, is_crit))
		hit_landed.emit(is_crit, amount, enemy.position)

	if weapon.mechanic == &"chain":
		_resolve_chain(weapon, hit_this_swing)


## Sends one chain jump per initial victim, each hop from the previous target.
## Dead enemies and enemies already hit by this cast are never candidates
## (GDD edge case E1).
func _resolve_chain(weapon: WeaponData, initial_hits: Array[Enemy]) -> void:
	if weapon.chain_jumps <= 0 or weapon.chain_jump_radius <= 0.0:
		return
	# Snapshot the initial victims: the hit set grows with every hop, and the
	# chain must not start a fresh cast from an enemy it just reached.
	for source in initial_hits.duplicate():
		_chain_from(weapon, source, 0, initial_hits)


## Resolves jump number [param jump] (one-based) from [param source] and
## recurses into the next hop until the count runs out or no candidate remains.
func _chain_from(
	weapon: WeaponData, source: Enemy, jump: int, hit_set: Array[Enemy]
) -> void:
	if jump >= weapon.chain_jumps or enemy_manager == null or source == null:
		return

	var next: Enemy = null
	var best := INF
	for candidate in enemy_manager.query_circle(source.position, weapon.chain_jump_radius):
		if candidate == null or candidate.hp <= 0.0 or hit_set.has(candidate):
			continue
		var distance := source.position.distance_squared_to(candidate.position)
		if distance < best:
			best = distance
			next = candidate
	if next == null:
		return

	var rank := jump + 1
	var hit := DamageCalc.roll(stats, weapon, rng)
	var amount := float(hit["amount"]) * pow(weapon.chain_falloff, rank)
	var is_crit := bool(hit["is_crit"])
	next.take_damage(amount, is_crit)
	next.apply_knockback(source.position, weapon.knockback)
	hit_set.append(next)

	if fx != null:
		fx.spawn_number(next.position, amount, is_crit)
	if sfx != null:
		sfx.play(_impact_sound(weapon, is_crit))
	hit_landed.emit(is_crit, amount, next.position)

	_chain_from(weapon, next, rank, hit_set)


## Throws one censer at the target's current position. With no target it lands
## at the end of the weapon's reach along the player's facing (edge case E11).
func _throw_censer(weapon: WeaponData, target: Enemy, reach: float) -> void:
	if projectile_layer == null or player == null:
		return
	var landing := player.position + Vector2.RIGHT.rotated(player.facing) * reach
	if target != null:
		landing = target.position
	var bomb := CenserBomb.create(weapon, player.position, landing)
	bomb.detonated.connect(_on_censer_detonated.bind(weapon))
	projectile_layer.add_child(bomb)
	_censer_bombs.append(bomb)


## Moves every censer and frees the spent ones.
func _step_censer_bombs(delta: float) -> void:
	var still_burning: Array[CenserBomb] = []
	for bomb in _censer_bombs:
		if bomb == null or not is_instance_valid(bomb):
			continue
		if bomb.step(delta):
			bomb.queue_free()
			continue
		still_burning.append(bomb)
	_censer_bombs = still_burning


## Applies one detonation: a single crit roll shared by every victim in the
## blast (GDD F11), then one hit per living enemy inside the radius. The blast
## radius is not multiplied by range_mult (edge case E20).
func _on_censer_detonated(at: Vector2, radius: float, weapon: WeaponData) -> void:
	if stats == null or enemy_manager == null or weapon == null:
		return
	var hit := DamageCalc.roll(stats, weapon, rng)
	var amount := float(hit["amount"])
	var is_crit := bool(hit["is_crit"])
	for enemy in enemy_manager.query_circle(at, radius):
		enemy.take_damage(amount, is_crit)
		enemy.apply_knockback(at, weapon.knockback)
		if fx != null:
			fx.spawn_number(enemy.position, amount, is_crit)
		hit_landed.emit(is_crit, amount, enemy.position)
	if sfx != null:
		sfx.play(_impact_sound(weapon, is_crit))


## Advances every orbiting moon.
func _step_orbits(delta: float) -> void:
	for orbit in _orbits:
		if orbit != null and is_instance_valid(orbit):
			orbit.step(delta)


## Reports one orbit contact once the moon has resolved it, mirroring the
## projectile callback so numbers, sound and hitstop stay in this class.
func _on_extra_hit_landed(
	is_crit: bool, amount: float, at: Vector2, weapon: WeaponData
) -> void:
	if fx != null:
		fx.spawn_number(at, amount, is_crit)
	if sfx != null and weapon != null:
		sfx.play(_impact_sound(weapon, is_crit))
	hit_landed.emit(is_crit, amount, at)


## True when [param enemy] is a boss: lifesteal and stagger both refuse elites.
func _is_elite(enemy: Enemy) -> bool:
	if enemy == null or enemy.data == null:
		return false
	return enemy.data.is_elite


## Warns once when a weapon carries a token absent from [constant
## WeaponData.MECHANICS]. The weapon is then treated as `cleave` (edge case
## E18), so a typo never makes a weapon inert.
func _warn_unknown_mechanic(weapon: WeaponData) -> void:
	if weapon.has_known_mechanic() or _warned_mechanics.has(weapon.mechanic):
		return
	_warned_mechanics[weapon.mechanic] = true
	push_warning(
		"WeaponSystem: unknown mechanic '%s' on '%s' — treated as cleave"
		% [weapon.mechanic, weapon.id]
	)


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
