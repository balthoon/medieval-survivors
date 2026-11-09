## Throwaway verification for slice 0.3: build rules, survivability, feel wiring.
##
## Loads the real main scene, silences spawning and the run loop, then asserts the
## additive stat rules, the crit multiplier source, rarity weights, equipment
## text, weapon swing timings, player invulnerability, the enemy hit signal, the
## dominated-equipment filter and the reroll budget.
## Prints PASS/FAIL lines and exits non-zero on any failure.
##
##   godot --path . --script res://tools/verify_slice03.gd
extends SceneTree

const EPEE := "res://data/weapons/epee_longue.tres"
const DAGUE := "res://data/weapons/dague.tres"
const MARTEAU := "res://data/weapons/marteau.tres"
const ARC := "res://data/weapons/arc_court.tres"
const CASQUE_FER := "res://data/equipment/casque_fer.tres"

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

	# Freeze the run: every check below is driven by hand, so nothing may race it.
	_main.is_paused = true
	_main._enemy_pool.clear()
	_manager.remove_dead(Callable())

	_check_wiring()
	_check_xp_curve()
	_check_additive_stats()
	_check_crit_multiplier()
	_check_rarity_weights()
	_check_equipment_text()
	_check_swing_timings()
	_check_invulnerability()
	_check_hit_signal()
	_check_dominated_equipment()
	_check_reroll()

	print("verify: failures=%d" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _check_wiring() -> void:
	_expect("Fx wired", 1 if _main._fx != null else 0, 1)
	_expect("Sfx wired", 1 if _main._sfx != null else 0, 1)
	_expect("Camera wired", 1 if _main._camera != null else 0, 1)
	_expect("weapon system uses the run Fx", 1 if _weapons.fx == _main._fx else 0, 1)
	_expect("weapon system uses the run Sfx", 1 if _weapons.sfx == _main._sfx else 0, 1)
	_expect("cooldown seconds match the inventory", _main._weapon_cooldown_seconds().size(), _main._inventory.weapons.size())


func _check_xp_curve() -> void:
	_expect_float("level 1 costs 5 xp", _main.xp_to_next(1), 5.0)
	_expect_float("level 2 costs 9 xp", _main.xp_to_next(2), 9.0)
	_expect_float("level 5 costs 21 xp", _main.xp_to_next(5), 21.0)


func _check_additive_stats() -> void:
	var stats := Stats.new()
	var up := UpgradeData.new()
	up.stat = "damage"
	up.amount = 0.2
	stats.apply_upgrade(up)
	stats.apply_upgrade(up)
	_expect_float("two +20% damage upgrades give x1.40", stats.damage_mult, 1.4)

	var speed_up := UpgradeData.new()
	speed_up.stat = "move_speed"
	speed_up.amount = 0.12
	stats.apply_upgrade(speed_up)
	_expect_float("move speed multiplier is additive", stats.move_speed_mult, 1.12)
	_expect_float("effective move speed", stats.effective_move_speed(), 220.0 * 1.12)

	var item := EquipmentData.new()
	item.stat = "move_speed"
	item.amount = 0.16
	stats.apply_equipment(item)
	_expect_float("equipment adds to the same multiplier", stats.move_speed_mult, 1.28)
	_expect_float("effective move speed after equipment", stats.effective_move_speed(), 220.0 * 1.28)


func _check_crit_multiplier() -> void:
	var weapon := WeaponData.new()
	weapon.damage = 10.0
	weapon.crit_chance = 0.75
	weapon.crit_multiplier = 2.5
	var stats := Stats.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var crits := 0
	var crit_amount_ok := true
	for i in 50:
		var hit := DamageCalc.roll(stats, weapon, rng)
		if hit["is_crit"]:
			crits += 1
			if absf(float(hit["amount"]) - 25.0) > 0.001:
				crit_amount_ok = false
		elif absf(float(hit["amount"]) - 10.0) > 0.001:
			crit_amount_ok = false
	_expect("crits rolled", 1 if crits > 0 else 0, 1)
	_expect("crit uses the weapon multiplier", 1 if crit_amount_ok else 0, 1)


func _check_rarity_weights() -> void:
	_expect_float("commun weight", EquipmentData.offer_weight_for_rarity("commun"), 1.0)
	_expect_float("peu_commun weight", EquipmentData.offer_weight_for_rarity("peu_commun"), 0.8)
	_expect_float("rare weight", EquipmentData.offer_weight_for_rarity("rare"), 0.55)
	_expect_float("epique weight", EquipmentData.offer_weight_for_rarity("epique"), 0.35)
	_expect_float("legendaire weight", EquipmentData.offer_weight_for_rarity("legendaire"), 0.22)
	_expect_float("mythique weight", EquipmentData.offer_weight_for_rarity("mythique"), 0.12)
	_expect_float("unknown rarity falls back", EquipmentData.offer_weight_for_rarity("inconnu"), 0.5)


func _check_equipment_text() -> void:
	var hp_item := EquipmentData.new()
	hp_item.stat = "max_hp"
	hp_item.amount = 15.0
	_expect_text("flat hp text", hp_item.effect_text(), "+15 PV")

	var damage_item := EquipmentData.new()
	damage_item.stat = "damage"
	damage_item.amount = 0.22
	_expect_text("damage text", damage_item.effect_text(), "+22 % dégâts")

	var crit_item := EquipmentData.new()
	crit_item.stat = "crit_chance"
	crit_item.amount = 0.06
	_expect_text("crit text", crit_item.effect_text(), "+6 % critique")


func _check_swing_timings() -> void:
	_expect_float("epee swing", (load(EPEE) as WeaponData).swing_duration, 0.12)
	_expect_float("dague swing", (load(DAGUE) as WeaponData).swing_duration, 0.08)
	_expect_float("marteau swing", (load(MARTEAU) as WeaponData).swing_duration, 0.22)
	_expect_float("arc swing", (load(ARC) as WeaponData).swing_duration, 0.12)


func _check_invulnerability() -> void:
	_player.heal(1000.0)
	var before := _player.hp
	_expect("first hit lands", 1 if _player.take_damage(10.0) else 0, 1)
	_expect_float("first hit removed hp", _player.hp, before - 10.0)
	_expect("second hit is ignored", 1 if _player.take_damage(10.0) else 0, 0)
	_expect_float("ignored hit removed nothing", _player.hp, before - 10.0)
	_player.step(Player.INVULNERABLE_TIME + 0.01)
	_expect("hit lands again after the window", 1 if _player.take_damage(10.0) else 0, 1)
	_expect_float("third hit removed hp", _player.hp, before - 20.0)


func _check_hit_signal() -> void:
	var landed := [0]
	_weapons.hit_landed.connect(
		func(_is_crit: bool, _amount: float, _at: Vector2) -> void: landed[0] += 1
	)
	var enemy := _manager.spawn(
		_sample_enemy(200.0), _player.position + Vector2(40.0, 0.0), _main.get_node("Enemies")
	)
	for i in 6:
		_weapons.step(0.1)
	_expect("melee weapon damaged the target", 1 if enemy.hp < 200.0 else 0, 1)
	_expect("hit_landed fired", 1 if landed[0] > 0 else 0, 1)
	enemy.hp = 0.0
	_manager.remove_dead(_main._drop_pickup)


func _check_dominated_equipment() -> void:
	_main._gain_equipment(load(CASQUE_FER) as EquipmentData)
	var equipped: EquipmentData = _main._inventory.item_in_slot("casque")
	_expect("helmet equipped", 1 if equipped != null else 0, 1)
	var dominated := 0
	for offer in _main._build_offers(200):
		if offer.kind != "equipment" or offer.equipment == null:
			continue
		if offer.equipment.slot != "casque" or equipped == null:
			continue
		if offer.equipment.stat != equipped.stat:
			continue
		if offer.equipment.amount <= equipped.amount:
			dominated += 1
	_expect("no dominated helmet offered", dominated, 0)


func _check_reroll() -> void:
	_main._rerolls = 1
	_main.is_paused = true
	_main._on_reroll_requested()
	_expect("reroll spent", _main._rerolls, 0)
	_expect("reroll rebuilt three choices", _main._pending_choices.size(), 3)
	_main._on_reroll_requested()
	_expect("empty reroll budget kept", _main._rerolls, 0)
	_main.is_paused = false


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
	print("FAIL: %s - got %d, expected %d" % [label, actual, expected])


func _expect_float(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) <= 0.001:
		print("PASS: %s (%.3f)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s - got %.3f, expected %.3f" % [label, actual, expected])


func _expect_text(label: String, actual: String, expected: String) -> void:
	if actual == expected:
		print("PASS: %s (%s)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s - got '%s', expected '%s'" % [label, actual, expected])
