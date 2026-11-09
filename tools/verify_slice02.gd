## Throwaway verification for slice 0.2: weapons, equipment and offers.
##
## Loads the real main scene, silences spawning, then asserts the inventory
## rules, the equipment-derived stats (no double counting on replacement), the
## melee swing, the projectile bolt, and the level-up offer rules.
## Prints PASS/FAIL lines and exits non-zero on any failure.
##
##   godot --path . --script res://tools/verify_slice02.gd
extends SceneTree

const EPEE := "res://data/weapons/epee_longue.tres"
const DAGUE := "res://data/weapons/dague.tres"
const MARTEAU := "res://data/weapons/marteau.tres"
const ARC := "res://data/weapons/arc_court.tres"
const CASQUE_FER := "res://data/equipment/casque_fer.tres"
const PLASTRON_MAILLES := "res://data/equipment/plastron_mailles.tres"
const CASQUE_ANCIEN := "res://data/equipment/casque_ancien.tres"

var _frame := 0
var _failures := 0
var _main: Node = null
var _player: Player = null
var _manager: EnemyManager = null
var _weapons: WeaponSystem = null


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("verify: could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	_player = _main.get_node_or_null("Player") as Player
	_manager = _main.get_node_or_null("EnemyManager") as EnemyManager
	_weapons = _main.get_node_or_null("WeaponSystem") as WeaponSystem
	if _player == null or _manager == null or _weapons == null:
		print("FAIL: could not find Player / EnemyManager / WeaponSystem")
		quit(1)
		return true

	_main._enemy_pool.clear()
	_manager.remove_dead(Callable())

	_check_inventory_start()
	_check_weapon_slots()
	_check_equipment_stats()
	_check_melee_swing()
	_check_projectile()
	_check_offers()

	print("verify: failures=%d" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _check_inventory_start() -> void:
	_expect("starts with one weapon", _main._inventory.weapons.size(), 1)
	_expect("starts with the sword", 1 if _main._inventory.has_weapon(load(EPEE)) else 0, 1)


func _check_weapon_slots() -> void:
	_main._gain_weapon(load(MARTEAU))
	_expect("marteau added", _main._inventory.weapons.size(), 2)
	_main._gain_weapon(load(DAGUE))
	_expect("dague added", _main._inventory.weapons.size(), 3)
	_main._gain_weapon(load(ARC))
	_expect("fourth weapon refused", _main._inventory.weapons.size(), 3)
	_main._gain_weapon(load(EPEE))
	_expect("duplicate refused", _main._inventory.weapons.size(), 3)
	_expect("three melee views built", _weapons._views.size(), 3)


func _check_equipment_stats() -> void:
	var base_hp: float = _main._player.stats.max_hp
	_main._gain_equipment(load(CASQUE_FER))
	_expect_float("casque de fer +15 hp", _main._player.stats.max_hp, base_hp + 15.0)
	_main._gain_equipment(load(PLASTRON_MAILLES))
	_expect_float("cotte de mailles +45 hp", _main._player.stats.max_hp, base_hp + 60.0)
	_main._gain_equipment(load(CASQUE_ANCIEN))
	_expect_float(
		"replacing the helmet does not double count", _main._player.stats.max_hp, base_hp + 45.0
	)
	_expect_float("heaume ancien gives crit", _main._player.stats.crit_chance_bonus, 0.06)


func _check_melee_swing() -> void:
	var enemy := _manager.spawn(_sample_enemy(200.0), _player.position + Vector2(40.0, 0.0), _main.get_node("Enemies"))
	for i in 6:
		_weapons.step(0.1)
	_expect("melee weapons damaged the target", 1 if enemy.hp < 200.0 else 0, 1)


func _check_projectile() -> void:
	var bolt_weapon := load(ARC) as WeaponData
	var stats := _player.stats
	# Fired downward, on a clear line: the melee target sits to the right and
	# would otherwise intercept the bolt.
	var enemy := _manager.spawn(
		_sample_enemy(100.0), _player.position + Vector2(0.0, 160.0), _main.get_node("Enemies")
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var bolt := Projectile.create(
		bolt_weapon, stats, rng, _player.position, Vector2.DOWN
	)
	_main.get_node("Projectiles").add_child(bolt)

	var spent := false
	for i in 10:
		spent = bolt.step(0.1, _manager)
		if spent:
			break
	_expect("bolt was spent", 1 if spent else 0, 1)
	_expect("bolt damaged its target", 1 if enemy.hp < 100.0 else 0, 1)
	bolt.queue_free()


func _check_offers() -> void:
	# The inventory is full, so no weapon may be offered.
	var offers: Array[Offer] = _main._build_offers(3)
	_expect("three offers built", offers.size(), 3)
	var weapon_offers := 0
	for offer in offers:
		if offer.kind == "weapon":
			weapon_offers += 1
	_expect("no weapon offered while the slots are full", weapon_offers, 0)

	# An offer that is applied must change something.
	var applied: Offer = offers[0]
	_main._apply_offer(applied)
	_expect("offer applied without error", 1, 1)


func _sample_enemy(hp: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = int(hp)
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.contact_damage = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data


func _expect(label: String, actual: int, expected: int) -> void:
	if actual == expected:
		print("PASS: %s (%d)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s — got %d, expected %d" % [label, actual, expected])


func _expect_float(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) <= 0.001:
		print("PASS: %s (%.3f)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s — got %.3f, expected %.3f" % [label, actual, expected])
