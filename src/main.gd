## Owns one run of Medieval Survivors.
##
## Reads the data resources, drives the player from polled input, runs the
## weapons, enemies and waves, collects XP, offers level-up choices and handles
## death and restart. Input is polled rather than mapped: the slice deliberately
## ships no InputMap.
extends Node2D

## Path of the hero class used by the run.
const CLASS_PATH := "res://data/classes/chevalier.tres"
## Path of the wave tuning resource.
const WAVE_PATH := "res://data/waves/base_wave.tres"
## Enemy archetypes available to the spawner.
const ENEMY_PATHS := [
	"res://data/enemies/squelette.tres",
	"res://data/enemies/loup_maudit.tres",
	"res://data/enemies/orc.tres",
]
## The boss spawned on every boss wave. Never added to the normal spawn pool, so
## the horde can never field one.
const BOSS_PATH := "res://data/enemies/seigneur_squelette.tres"
## Weapon resources offered on level up, starting weapon included.
const WEAPON_PATHS := [
	"res://data/weapons/epee_longue.tres",
	"res://data/weapons/dague.tres",
	"res://data/weapons/marteau.tres",
	"res://data/weapons/arc_court.tres",
]
## Equipment resources offered on level up.
const EQUIPMENT_PATHS := [
	"res://data/equipment/casque_fer.tres",
	"res://data/equipment/casque_ancien.tres",
	"res://data/equipment/plastron_cuir.tres",
	"res://data/equipment/plastron_mailles.tres",
	"res://data/equipment/bottes_cuir.tres",
	"res://data/equipment/bottes_rapides.tres",
	"res://data/equipment/gants_fer.tres",
	"res://data/equipment/gants_precis.tres",
	"res://data/equipment/anneau_argent.tres",
	"res://data/equipment/anneau_rubis.tres",
	"res://data/equipment/amulette_lune.tres",
	"res://data/equipment/amulette_sang.tres",
]
## Upgrade resources offered on level up.
const UPGRADE_PATHS := [
	"res://data/upgrades/degats.tres",
	"res://data/upgrades/cadence.tres",
	"res://data/upgrades/vitalite.tres",
	"res://data/upgrades/vitesse.tres",
	"res://data/upgrades/precision.tres",
]

## Flat XP cost of the first level curve step.
const XP_BASE := 5
## Extra XP per level added to the curve.
const XP_PER_LEVEL := 4
## Seconds an enemy must wait after dealing contact damage.
const CONTACT_COOLDOWN := 1.0
## How many choices a level up offers.
const UPGRADE_OFFER_COUNT := 3
## Deadzone applied to the joypad movement axes.
const JOY_AXIS_DEADZONE := 0.25
## Relative weight of a new-weapon choice against a stat or equipment choice.
const WEAPON_OFFER_WEIGHT := 1.4
## Relative weight of a common piece of equipment against a stat or weapon choice.
const EQUIPMENT_OFFER_WEIGHT := 0.9
## Rerolls the player starts the run with.
const REROLL_BASE := 2
## Levels that grant one extra reroll.
const REROLL_LEVELS := [10, 20]
## Duration of the camera shake when the player is hit, in seconds.
const SHAKE_DURATION := 0.18
## Peak offset of the camera shake, in pixels.
const SHAKE_STRENGTH := 4.0
## Hitstop applied on a critical hit, in seconds.
const CRIT_HITSTOP := 0.055
## Hitstop applied on a heavy hit, in seconds.
const HEAVY_HITSTOP := 0.04
## Hitstop applied when the level-up panel opens, in seconds.
const LEVEL_UP_HITSTOP := 0.12
## Minimum damage of a hit treated as heavy for hitstop purposes.
const HEAVY_HIT_DAMAGE := 22.0
## Minimum real-time gap between two hitstops, in seconds.
const HITSTOP_REST := 0.3
## Time scale during a hitstop. Small but not zero, so the scene keeps stepping.
const HITSTOP_SCALE := 0.05
## Colour of the ring drawn when the level-up panel opens.
const LEVEL_UP_COLOR := Color(0.85, 0.65, 0.15)
## Health multiplier granted to a boss per tier above the first.
const BOSS_HP_PER_TIER := 0.9
## Damage multiplier granted to a boss per tier above the first.
const BOSS_DAMAGE_PER_TIER := 0.35
## Relative weight of a weapon in the boss loot panel.
const BOSS_LOOT_WEAPON_WEIGHT := 3.0
## Relative weight of a piece of equipment in the boss loot panel.
const BOSS_LOOT_EQUIPMENT_WEIGHT := 2.5
## Title of the panel opened by a boss death.
const BOSS_LOOT_TITLE := "Butin du boss"
## Colour of the impact ring drawn where a slam lands.
const BOSS_SLAM_COLOR := Color(0.75, 0.20, 0.14)
## Duration of the camera shake when a slam lands, in seconds.
const BOSS_SLAM_SHAKE_DURATION := 0.3
## Peak offset of the camera shake when a slam lands, in pixels.
const BOSS_SLAM_SHAKE_STRENGTH := 7.0

## True while the level-up panel is open. Manual pause: the scene tree is never
## paused, so the HUD keeps receiving input.
var is_paused := false

var _player: Player = null
var _enemy_manager: EnemyManager = null
var _spawner: Spawner = null
var _hud: HUD = null
var _weapon_system: WeaponSystem = null
var _projectiles: Node2D = null
var _fx: Fx = null
var _sfx: Sfx = null
var _camera: Camera2D = null
var _wave_director := WaveDirector.new()
var _rng := RandomNumberGenerator.new()
## Separate roll source for cosmetic effects (camera shake), so consuming a
## random number for a shake can never change the next crit roll.
var _fx_rng := RandomNumberGenerator.new()
var _inventory := Inventory.new()

var _enemy_pool: Array[EnemyData] = []
var _boss_data: EnemyData = null
var _upgrades: Array[UpgradeData] = []
var _weapon_pool: Array[WeaponData] = []
var _equipment_pool: Array[EquipmentData] = []
var _pending_choices: Array[Offer] = []
## True while the open panel is the boss loot panel, so a reroll rebuilds loot
## and not level-up choices.
var _boss_loot_open := false
## The living boss of the current run, or null when none is alive.
var _boss: Enemy = null

## Class statistics plus every stat upgrade taken. Equipment is applied on top
## of a copy of this, so replacing a piece never double-counts its modifiers.
var _base_stats: Stats = null

var _level := 1
var _xp := 0.0
var _xp_needed := 0.0
var _rerolls := REROLL_BASE
var _dead := false

var _shake_time := 0.0
var _shake_total := 0.0
var _shake_strength := 0.0
var _hitstop_active := false
var _hitstop_ready_at := 0

@onready var _enemies: Node2D = $Enemies
@onready var _pickups: Node2D = $Pickups


func _ready() -> void:
	# The mute shortcut must fire even while a HUD button holds focus.
	set_process_unhandled_key_input(true)
	_player = $Player as Player
	_enemy_manager = $EnemyManager as EnemyManager
	_spawner = $Spawner as Spawner
	_hud = $HUD as HUD
	_weapon_system = $WeaponSystem as WeaponSystem
	_projectiles = $Projectiles as Node2D
	_fx = $Fx as Fx
	_sfx = $Sfx as Sfx
	_camera = $Camera as Camera2D
	if _camera != null:
		_camera.make_current()

	_rng.randomize()
	_fx_rng.randomize()
	_load_data()

	var class_data := load(CLASS_PATH) as ClassData
	if class_data != null:
		_player.setup(class_data)
		_inventory.setup_starting(class_data.weapon)
	_base_stats = _player.stats
	_recompute_stats()

	_weapon_system.setup(
		_player.stats, _inventory, _player, _enemy_manager, _projectiles, _rng
	)
	_weapon_system.fx = _fx
	_weapon_system.sfx = _sfx
	_weapon_system.hit_landed.connect(_on_hit_landed)

	var wave_data := load(WAVE_PATH) as WaveData
	_wave_director.setup(wave_data)
	_wave_director.spawn_tick.connect(_on_spawn_tick)
	_wave_director.wave_started.connect(_on_wave_started)
	_wave_director.wave_ended.connect(_on_wave_ended)

	_player.died.connect(_on_player_died)
	_hud.upgrade_chosen.connect(_on_upgrade_chosen)
	_hud.reroll_requested.connect(_on_reroll_requested)

	_xp_needed = xp_to_next(_level)

	_hud.hide_dead()
	_refresh_hud()


func _process(delta: float) -> void:
	# Runs before the early returns so a shake always decays back to centre,
	# even on the frame the player dies or the level-up panel opens.
	_update_camera(delta)

	if _dead:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	if is_paused:
		return

	var move_dir := _read_move_dir()
	_player.step_movement(move_dir, delta)
	_player.step(delta)
	_update_facing(move_dir)
	_weapon_system.step(delta)
	_enemy_manager.step_all(_player.position, delta)
	_update_contact_damage(delta)
	_collect_pickups(delta)
	_wave_director.tick(delta)
	_refresh_hud()
	_check_level_up()


## XP required to reach the next level from [param for_level]. The first step is
## deliberately cheap, so the first choice lands during wave 1 rather than at the
## end of it.
func xp_to_next(for_level: int) -> float:
	return float(XP_BASE + (for_level - 1) * XP_PER_LEVEL)


func _load_data() -> void:
	for path in ENEMY_PATHS:
		var enemy_data := load(path) as EnemyData
		if enemy_data != null:
			_enemy_pool.append(enemy_data)

	_boss_data = load(BOSS_PATH) as EnemyData
	if _boss_data == null:
		push_warning("main: no boss at %s — boss waves will be empty" % BOSS_PATH)

	for path in UPGRADE_PATHS:
		var upgrade := load(path) as UpgradeData
		if upgrade != null:
			_upgrades.append(upgrade)

	for path in WEAPON_PATHS:
		var weapon := load(path) as WeaponData
		if weapon != null:
			_weapon_pool.append(weapon)

	for path in EQUIPMENT_PATHS:
		var item := load(path) as EquipmentData
		if item != null:
			_equipment_pool.append(item)


func _read_move_dir() -> Vector2:
	var dir := Vector2.ZERO
	# Physical keys, not logical ones: WASD must mean the same four keys on every
	# layout. On an AZERTY keyboard that is ZQSD; with logical keycodes Q and Z
	# would stay dead, because the key labelled Q there is where A sits on QWERTY.
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	var joy := Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	if joy.length() > JOY_AXIS_DEADZONE:
		dir += joy

	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


## Aims the player at the nearest living enemy every frame, wherever it stands in
## the arena — the carried weapons always face the closest threat, not just what
## is already inside their range. Only when nothing is alive does it fall back to
## the movement direction; standing still then keeps the last facing.
func _update_facing(move_dir: Vector2) -> void:
	if _player.stats == null:
		return

	var nearest := _enemy_manager.nearest_to(_player.position)
	if nearest != null:
		_player.aim_at(nearest.position)
		return

	_player.face_direction(move_dir)


## Rebuilds the live stats: class plus upgrades, with every equipped item applied
## on top. Called at run start and after any stat or equipment change. Hit points
## are clamped to the new maximum, so replacing a health piece can never leave
## the player above their own bar.
func _recompute_stats() -> void:
	if _base_stats == null:
		return
	var derived := _base_stats.clone()
	_inventory.apply_to(derived)
	_player.stats = derived
	_player.hp = minf(_player.hp, derived.max_hp)
	if _weapon_system != null:
		_weapon_system.stats = derived


func _update_contact_damage(delta: float) -> void:
	for enemy in _enemy_manager.enemies:
		if enemy == null or enemy.hp <= 0.0:
			continue
		enemy.contact_cooldown = maxf(enemy.contact_cooldown - delta, 0.0)
		if enemy.contact_cooldown > 0.0:
			continue
		if enemy.data == null:
			continue

		var reach := Player.RADIUS + enemy.radius
		if _player.position.distance_squared_to(enemy.position) > reach * reach:
			continue

		var landed := _player.take_damage(enemy.contact_damage)
		enemy.contact_cooldown = CONTACT_COOLDOWN
		if landed:
			_on_player_hit()
		if not _player.is_alive():
			return


## Player-side feedback for one landed contact hit.
func _on_player_hit() -> void:
	_hud.flash_damage()
	_shake(SHAKE_DURATION, SHAKE_STRENGTH)
	if _sfx != null:
		_sfx.play("player_hurt", -3.0)


func _collect_pickups(delta: float) -> void:
	_enemy_manager.remove_dead(_drop_pickup)
	# Checked after remove_dead so the kill and the loot panel land on the same
	# frame the boss's shards do. The node is only queued for deletion at this
	# point, so its hp is still readable.
	if _boss != null and _boss.hp <= 0.0:
		_on_boss_killed()

	for node in _pickups.get_children():
		var pickup := node as XpPickup
		if pickup == null:
			continue
		pickup.step_toward(_player.position, delta)
		if pickup.collected_by(_player.position):
			_xp += float(pickup.value)
			pickup.queue_free()


## Death callback: shards and the death sound first, then the XP gem. The enemy
## data is supplied by EnemyManager so the shards take the archetype's colour.
func _drop_pickup(at: Vector2, xp_value: int, enemy_data: EnemyData = null) -> void:
	if _fx != null:
		var colour := Color(0.16, 0.14, 0.12)
		if enemy_data != null:
			colour = enemy_data.color
		_fx.spawn_shards(at, colour)
	if _sfx != null:
		_sfx.play("enemy_death", -8.0)
	if xp_value <= 0:
		return
	_pickups.add_child(XpPickup.create(xp_value, at))


func _check_level_up() -> void:
	if is_paused or _dead:
		return
	if _xp < _xp_needed:
		return

	_xp -= _xp_needed
	_level += 1
	_xp_needed = xp_to_next(_level)
	if _level in REROLL_LEVELS:
		_rerolls += 1
	_offer_choices()


func _offer_choices() -> void:
	var choices := _build_offers(UPGRADE_OFFER_COUNT)
	if choices.is_empty():
		return
	_pending_choices = choices
	_boss_loot_open = false
	is_paused = true
	_request_hitstop(LEVEL_UP_HITSTOP)
	if _fx != null:
		add_child(RingBurst.create(_player.position, LEVEL_UP_COLOR))
	if _sfx != null:
		_sfx.play("level_up", -2.0)
	_hud.show_upgrade_choices(choices, _rerolls)
	_refresh_hud()


## Opens the boss loot panel: the same three-choice panel as a level up, titled
## differently and weighted toward gear. The XP the boss dropped still levels the
## player up afterwards, once this panel is answered.
func _offer_boss_loot() -> void:
	if _dead:
		return
	var choices := _build_offers(
		UPGRADE_OFFER_COUNT, BOSS_LOOT_WEAPON_WEIGHT, BOSS_LOOT_EQUIPMENT_WEIGHT
	)
	if choices.is_empty():
		return
	_pending_choices = choices
	_boss_loot_open = true
	is_paused = true
	_hud.show_upgrade_choices(choices, _rerolls, BOSS_LOOT_TITLE)
	_refresh_hud()


## Builds the level-up choices: stat upgrades, new weapons when a slot is free,
## and equipment. Sampled without replacement, weighted per kind. Equipment is
## weighted by rarity, and a piece that would replace the equipped one with the
## same stat for less is never offered — the panel must not hide a downgrade.
##
## [param weapon_weight] and [param equipment_weight] override the normal kind
## weights, which is how the boss loot panel leans its offers toward gear.
func _build_offers(
	count: int,
	weapon_weight: float = WEAPON_OFFER_WEIGHT,
	equipment_weight: float = EQUIPMENT_OFFER_WEIGHT
) -> Array[Offer]:
	var candidates: Array[Offer] = []

	for upgrade in _upgrades:
		if upgrade == null:
			continue
		var stat_offer := Offer.for_stat(upgrade)
		stat_offer.weight = maxf(upgrade.weight, 0.0)
		candidates.append(stat_offer)

	var free_slots := _inventory.free_weapon_slots()
	if free_slots > 0:
		var weapon_offers: Array[Offer] = []
		for weapon in _weapon_pool:
			if weapon == null or _inventory.has_weapon(weapon):
				continue
			var weapon_offer := Offer.for_weapon(weapon)
			weapon_offer.weight = weapon_weight
			_decorate_offer(weapon_offer)
			weapon_offers.append(weapon_offer)
		# One weapon per free slot at most: a third weapon row in a panel with one
		# slot left is the same choice printed twice.
		if weapon_offers.size() > free_slots:
			_shuffle(weapon_offers)
			weapon_offers.resize(free_slots)
		candidates.append_array(weapon_offers)

	for item in _equipment_pool:
		if item == null:
			continue
		var equipped := _inventory.item_in_slot(item.slot)
		if equipped == item:
			continue
		if equipped != null and equipped.stat == item.stat and item.amount <= equipped.amount:
			continue
		var item_offer := Offer.for_equipment(item)
		item_offer.weight = (
			equipment_weight * EquipmentData.offer_weight_for_rarity(item.rarity)
		)
		_decorate_offer(item_offer)
		candidates.append(item_offer)

	return _pick_weighted(candidates, count)


## Rewrites an offer's description with the numbers that actually apply to this
## run: effective DPS for a weapon, the effect in points for a piece of
## equipment, and what it would replace.
func _decorate_offer(offer: Offer) -> void:
	if offer == null or _player == null or _player.stats == null:
		return
	var stats := _player.stats

	match offer.kind:
		"weapon":
			var weapon := offer.weapon
			if weapon == null:
				return
			var damage := stats.weapon_damage(weapon)
			var cadence := stats.weapon_attacks_per_second(weapon)
			var crit := stats.weapon_crit_chance(weapon)
			var dps := damage * cadence * (1.0 + crit * (weapon.crit_multiplier - 1.0))
			offer.description = "%d dégâts · %.1f att/s · %.0f DPS · portée %.0f px" % [
				int(round(damage)), cadence, dps, stats.weapon_range(weapon)
			]
		"equipment":
			var item := offer.equipment
			if item == null:
				return
			var text := item.effect_text()
			var current := _inventory.item_in_slot(item.slot)
			if current != null:
				text += " · remplace %s (%s)" % [current.display_name, current.effect_text()]
			offer.description = text


## Picks [param count] distinct offers, each draw weighted by [member Offer.weight].
## Once a piece of equipment is picked, every other piece for the same body slot
## is dropped from the pool: two helmets in one panel are one choice and one
## wasted row, since equipping the second would replace the first.
func _pick_weighted(pool: Array[Offer], count: int) -> Array[Offer]:
	var remaining := pool.duplicate()
	var picked: Array[Offer] = []
	while picked.size() < count and not remaining.is_empty():
		var total := 0.0
		for offer in remaining:
			total += maxf(offer.weight, 0.0)

		var chosen_index := 0
		if total > 0.0:
			var roll := _rng.randf() * total
			var running := 0.0
			for index in remaining.size():
				running += maxf(remaining[index].weight, 0.0)
				if roll <= running:
					chosen_index = index
					break

		var chosen: Offer = remaining[chosen_index]
		picked.append(chosen)
		remaining.remove_at(chosen_index)
		if chosen.kind == "equipment" and chosen.equipment != null:
			remaining = _without_slot(remaining, chosen.equipment.slot)
	return picked


## Returns [param pool] without the equipment offers that occupy [param slot].
func _without_slot(pool: Array[Offer], slot: String) -> Array[Offer]:
	var kept: Array[Offer] = []
	for offer in pool:
		if offer.kind == "equipment" and offer.equipment != null and offer.equipment.slot == slot:
			continue
		kept.append(offer)
	return kept


## Fisher-Yates shuffle driven by the run's roll source, so the trimmed weapon
## offers are as reproducible as any other roll.
func _shuffle(pool: Array[Offer]) -> void:
	for index in range(pool.size() - 1, 0, -1):
		var swap := _rng.randi_range(0, index)
		var held: Offer = pool[index]
		pool[index] = pool[swap]
		pool[swap] = held


func _on_upgrade_chosen(index: int) -> void:
	if not is_paused or index < 0 or index >= _pending_choices.size():
		return

	_apply_offer(_pending_choices[index])
	_pending_choices.clear()
	_boss_loot_open = false
	_hud.hide_upgrade_choices()
	is_paused = false
	_refresh_hud()
	_check_level_up()


## Spends one reroll and rebuilds the choices. The panel stays open and keeps
## accepting input; the HUD keeps the focus on the first option.
func _on_reroll_requested() -> void:
	if not is_paused or _dead or _rerolls <= 0:
		return

	_rerolls -= 1
	var choices: Array[Offer]
	if _boss_loot_open:
		choices = _build_offers(
			UPGRADE_OFFER_COUNT, BOSS_LOOT_WEAPON_WEIGHT, BOSS_LOOT_EQUIPMENT_WEIGHT
		)
	else:
		choices = _build_offers(UPGRADE_OFFER_COUNT)
	if choices.is_empty():
		return
	_pending_choices = choices
	var title := BOSS_LOOT_TITLE if _boss_loot_open else HUD.LEVEL_UP_TITLE
	_hud.show_upgrade_choices(choices, _rerolls, title)


## Applies one choice, whatever its kind.
func _apply_offer(offer: Offer) -> void:
	match offer.kind:
		"weapon":
			_gain_weapon(offer.weapon)
		"equipment":
			_gain_equipment(offer.equipment)
		_:
			_apply_stat_upgrade(offer.stat_upgrade)


func _apply_stat_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null or _base_stats == null:
		return
	_base_stats.apply_upgrade(upgrade)
	if upgrade.stat == "max_hp":
		_player.heal(upgrade.amount)
	_recompute_stats()


## Adds a weapon and gives it its own timer and view.
func _gain_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return
	if not _inventory.add_weapon(weapon):
		return
	_weapon_system.refresh()


## Equips an item and rebuilds the stats on top of the base ones.
func _gain_equipment(item: EquipmentData) -> void:
	if item == null:
		return
	_inventory.equip(item)
	_recompute_stats()


func _on_player_died() -> void:
	_dead = true
	is_paused = true
	_boss = null
	_hud.hide_boss()
	_hud.show_dead()


func _on_spawn_tick(wave_index: int) -> void:
	if _enemy_manager.count() >= _wave_director.max_alive():
		return
	if _spawner == null or _enemy_pool.is_empty():
		return

	var enemy_data := _spawner.pick_enemy(wave_index, _enemy_pool, _rng)
	if enemy_data == null:
		return
	var at := _spawner.spawn_position(_rng)
	_enemy_manager.spawn(enemy_data, at, _enemies)


func _on_wave_started(wave_index: int) -> void:
	var suffix := ""
	if _wave_director.is_boss_wave(wave_index):
		suffix = "BOSS"
		_spawn_boss(wave_index)
	_hud.show_wave_banner(wave_index, suffix)
	_hud.update_wave(wave_index, _wave_director.time_left(), _wave_director.wave_progress())


## Spawns the wave's boss on the arena border, scaled by the boss tier. Does
## nothing when a boss from the previous wave is still alive, or when the run has
## no boss resource: a missing file must never stop the wave.
func _spawn_boss(wave_index: int) -> void:
	if _boss_data == null or _spawner == null or _enemy_manager == null:
		return
	if _boss != null and is_instance_valid(_boss) and _boss.hp > 0.0:
		return

	var tier := maxi(_wave_director.boss_tier(wave_index), 0)
	var hp_scale := 1.0 + BOSS_HP_PER_TIER * float(tier)
	var damage_scale := 1.0 + BOSS_DAMAGE_PER_TIER * float(tier)

	var at := _spawner.spawn_position(_rng)
	_boss = _enemy_manager.spawn(_boss_data, at, _enemies, hp_scale, damage_scale)
	_boss.slam_struck.connect(_on_boss_slam)
	_hud.show_boss(_boss_data.display_name)
	if _sfx != null:
		_sfx.play("boss_roar", -1.0)


## A slam landed: impact ring, shake and sound wherever it struck, damage only
## inside the radius. The boss reports the blow; this is the only place it can
## reach the player's hit points.
func _on_boss_slam(at: Vector2, radius: float, damage: float) -> void:
	if _dead or _player == null:
		return
	if _fx != null:
		add_child(RingBurst.create(at, BOSS_SLAM_COLOR))
	_shake(BOSS_SLAM_SHAKE_DURATION, BOSS_SLAM_SHAKE_STRENGTH)
	if _sfx != null:
		_sfx.play("boss_slam", -1.0)
	if _player.position.distance_to(at) > radius + Player.RADIUS:
		return
	if _player.take_damage(damage):
		_on_player_hit()


## The boss died: victory feedback, then the loot panel. Its XP gems are already
## on the ground, so the level ups they buy arrive after the loot choice.
func _on_boss_killed() -> void:
	var at := _player.position
	var colour := BOSS_SLAM_COLOR
	if _boss != null and is_instance_valid(_boss):
		at = _boss.position
		if _boss.data != null:
			colour = _boss.data.color
	_boss = null

	_hud.hide_boss()
	_hud.show_wave_banner(_wave_director.wave_index, "VAINCU")
	if _fx != null:
		add_child(RingBurst.create(at, LEVEL_UP_COLOR))
		_fx.spawn_shards(at, colour)
	_shake(BOSS_SLAM_SHAKE_DURATION, BOSS_SLAM_SHAKE_STRENGTH)
	if _sfx != null:
		_sfx.play("level_up", -1.0)
	_offer_boss_loot()


func _on_wave_ended(wave_index: int) -> void:
	_hud.update_wave(wave_index, _wave_director.time_left(), _wave_director.wave_progress())


## One hit landed on an enemy. Critical and heavy hits freeze the frame for a
## few dozen milliseconds; the rest is left to the floating numbers.
func _on_hit_landed(is_crit: bool, amount: float, _at: Vector2) -> void:
	if is_crit:
		_request_hitstop(CRIT_HITSTOP)
	elif amount >= HEAVY_HIT_DAMAGE:
		_request_hitstop(HEAVY_HITSTOP)


## Freezes the frame briefly. Restored by a real-time timer, because the scaled
## delta would otherwise stretch a 40 ms freeze into a second.
func _request_hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	var now := Time.get_ticks_msec()
	if now < _hitstop_ready_at:
		return

	_hitstop_active = true
	_hitstop_ready_at = now + int((duration + HITSTOP_REST) * 1000.0)
	Engine.time_scale = HITSTOP_SCALE
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	Engine.time_scale = 1.0
	_hitstop_active = false


## Starts a camera shake. Overlapping requests keep the longest and strongest.
func _shake(duration: float, strength: float) -> void:
	_shake_time = maxf(_shake_time, duration)
	_shake_total = maxf(_shake_total, duration)
	_shake_strength = maxf(_shake_strength, strength)


func _update_camera(delta: float) -> void:
	if _camera == null:
		return
	if _shake_time <= 0.0:
		_camera.offset = Vector2.ZERO
		return

	_shake_time = maxf(_shake_time - delta, 0.0)
	var falloff := 1.0
	if _shake_total > 0.0:
		falloff = _shake_time / _shake_total
	_camera.offset = (
		Vector2(_fx_rng.randf_range(-1.0, 1.0), _fx_rng.randf_range(-1.0, 1.0))
		* _shake_strength
		* falloff
	)
	if _shake_time <= 0.0:
		_camera.offset = Vector2.ZERO
		_shake_strength = 0.0
		_shake_total = 0.0


func _refresh_hud() -> void:
	if _player == null or _player.stats == null:
		return
	_hud.update_bars(_player.hp, _player.stats.max_hp, _xp, _xp_needed, _level)
	_hud.update_wave(
		_wave_director.wave_index, _wave_director.time_left(), _wave_director.wave_progress()
	)
	_hud.update_weapons(
		_inventory.weapons, _weapon_cooldown_ratios(), _weapon_cooldown_seconds()
	)
	_hud.update_equipment(_inventory)
	if _boss != null and is_instance_valid(_boss) and _boss.hp > 0.0:
		_hud.update_boss(_boss.hp, _boss.max_hp)


## Recharge fraction of every weapon, in 0..1, consumed by the HUD bars.
func _weapon_cooldown_ratios() -> Array[float]:
	var ratios: Array[float] = []
	for index in _inventory.weapons.size():
		ratios.append(_weapon_system.cooldown_ratio(index))
	return ratios


## Seconds left before each weapon may fire again, consumed by the HUD status.
func _weapon_cooldown_seconds() -> Array[float]:
	var seconds: Array[float] = []
	for index in _inventory.weapons.size():
		seconds.append(_weapon_system.cooldown_seconds(index))
	return seconds


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or key_event.echo or not key_event.pressed:
		return
	if _key_of(key_event) != KEY_M or _sfx == null:
		return
	_sfx.toggle_muted()
	get_viewport().set_input_as_handled()


## Physical key wins, so the shortcut survives non-QWERTY layouts.
func _key_of(event: InputEventKey) -> Key:
	if event.physical_keycode != KEY_NONE:
		return event.physical_keycode
	return event.keycode


func _exit_tree() -> void:
	Engine.time_scale = 1.0
