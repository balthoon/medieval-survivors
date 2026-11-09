## Integration tests for slice 0.2: weapons, equipment and level-up offers.
##
## Port of the throwaway tools/verify_slice02.gd script: the real main scene is
## instantiated, wave spawning is silenced, then the inventory rules, the
## equipment-derived stats (no double counting on replacement), the melee swing,
## the projectile bolt and the offer rules are asserted.
##
## The six original checks are kept, one test function each. Every test builds
## its own scene: gdUnit4 may run tests in any order, so no test may rely on
## state left behind by another.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const EPEE := "res://data/weapons/epee_longue.tres"
const DAGUE := "res://data/weapons/dague.tres"
const MARTEAU := "res://data/weapons/marteau.tres"
const ARC := "res://data/weapons/arc_court.tres"
const CASQUE_FER := "res://data/equipment/casque_fer.tres"
const PLASTRON_MAILLES := "res://data/equipment/plastron_mailles.tres"
const CASQUE_ANCIEN := "res://data/equipment/casque_ancien.tres"

## Tolerance on the equipment-derived stats, carried over from verify_slice02.gd.
const FLOAT_EPSILON := 0.001


func test_inventory_start_holds_one_sword() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var inventory: Inventory = main._inventory

	# Act
	var weapon_count := inventory.weapons.size()
	var holds_sword := 1 if inventory.has_weapon(load(EPEE)) else 0

	# Assert
	_assert_int("starts with one weapon", weapon_count, 1)
	_assert_int("starts with the sword", holds_sword, 1)


func test_weapon_slots_accept_three_unique_weapons() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var inventory: Inventory = main._inventory
	var weapons := main.get_node_or_null("WeaponSystem") as WeaponSystem
	assert_object(weapons).is_not_null()
	if weapons == null:
		return

	# Act
	main._gain_weapon(load(MARTEAU))
	var after_marteau := inventory.weapons.size()
	main._gain_weapon(load(DAGUE))
	var after_dague := inventory.weapons.size()
	main._gain_weapon(load(ARC))
	var after_arc := inventory.weapons.size()
	main._gain_weapon(load(EPEE))
	var after_duplicate := inventory.weapons.size()

	# Assert
	_assert_int("marteau added", after_marteau, 2)
	_assert_int("dague added", after_dague, 3)
	_assert_int("fourth weapon refused", after_arc, 3)
	_assert_int("duplicate refused", after_duplicate, 3)
	_assert_int("three melee views built", weapons._views.size(), 3)


func test_equipment_stats_add_without_double_counting() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var player := main.get_node_or_null("Player") as Player
	assert_object(player).is_not_null()
	if player == null:
		return
	var base_hp: float = player.stats.max_hp

	# Act
	main._gain_equipment(load(CASQUE_FER))
	var hp_after_helmet: float = player.stats.max_hp
	main._gain_equipment(load(PLASTRON_MAILLES))
	var hp_after_chest: float = player.stats.max_hp
	main._gain_equipment(load(CASQUE_ANCIEN))
	var hp_after_replacement: float = player.stats.max_hp
	var crit_after_replacement: float = player.stats.crit_chance_bonus

	# Assert
	_assert_close("casque de fer +15 hp", hp_after_helmet, base_hp + 15.0)
	_assert_close("cotte de mailles +45 hp", hp_after_chest, base_hp + 60.0)
	_assert_close(
		"replacing the helmet does not double count", hp_after_replacement, base_hp + 45.0
	)
	_assert_close("heaume ancien gives crit", crit_after_replacement, 0.06)


func test_melee_swing_damages_target() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var player := main.get_node_or_null("Player") as Player
	var manager := main.get_node_or_null("EnemyManager") as EnemyManager
	var weapons := main.get_node_or_null("WeaponSystem") as WeaponSystem
	assert_object(player).is_not_null()
	assert_object(manager).is_not_null()
	assert_object(weapons).is_not_null()
	if player == null or manager == null or weapons == null:
		return
	# Silence leaves the field clear for the enemy this test spawns.
	manager.remove_dead(Callable())
	var enemy := manager.spawn(
		_sample_enemy(200.0), player.position + Vector2(40.0, 0.0), main.get_node("Enemies") as Node2D
	)
	assert_object(enemy).is_not_null()
	if enemy == null:
		return

	# Act
	for _i in 6:
		weapons.step(0.1)

	# Assert
	_assert_int("melee weapons damaged the target", 1 if enemy.hp < 200.0 else 0, 1)


func test_projectile_bolt_spends_and_damages_target() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var player := main.get_node_or_null("Player") as Player
	var manager := main.get_node_or_null("EnemyManager") as EnemyManager
	assert_object(player).is_not_null()
	assert_object(manager).is_not_null()
	if player == null or manager == null:
		return
	# Silence leaves the field clear for the enemy this test spawns.
	manager.remove_dead(Callable())
	# Fired downward, on a clear line: nothing else is in the bolt's path.
	var enemy := manager.spawn(
		_sample_enemy(100.0),
		player.position + Vector2(0.0, 160.0),
		main.get_node("Enemies") as Node2D
	)
	assert_object(enemy).is_not_null()
	if enemy == null:
		return
	var bolt_weapon := load(ARC) as WeaponData
	var stats: Stats = player.stats
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var bolt := Projectile.create(bolt_weapon, stats, rng, player.position, Vector2.DOWN)
	auto_free(bolt)
	(main.get_node("Projectiles") as Node2D).add_child(bolt)

	# Act
	var spent := false
	for _i in 10:
		spent = bolt.step(0.1, manager)
		if spent:
			break

	# Assert
	_assert_int("bolt was spent", 1 if spent else 0, 1)
	_assert_int("bolt damaged its target", 1 if enemy.hp < 100.0 else 0, 1)


func test_offers_exclude_weapons_when_slots_are_full() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var inventory: Inventory = main._inventory
	# The original reached this check with three weapons from the slot test;
	# each test owns its scene, so the slots are filled here instead.
	main._gain_weapon(load(MARTEAU))
	main._gain_weapon(load(DAGUE))

	# Act
	var offers: Array[Offer] = main._build_offers(3)
	var weapon_offers := 0
	for offer in offers:
		if offer.kind == "weapon":
			weapon_offers += 1
	var applied: Offer = offers[0] if not offers.is_empty() else null
	var state_before := _offer_state(main)
	if applied != null:
		main._apply_offer(applied)
	var state_after := _offer_state(main)

	# Assert
	_assert_int("three offers built", offers.size(), 3)
	_assert_int("no weapon offered while the slots are full", weapon_offers, 0)
	# The original printed this check as an unconditional pass; it is read here
	# as the comment intended: an applied offer must change the run state.
	_assert_int("offer applied without error", 1 if state_before != state_after else 0, 1)


## The minimal archetype verify_slice02.gd spawned: still, harmless, low health.
func _sample_enemy(hp: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = int(hp)
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.contact_damage = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data


## Fingerprint of everything an offer can change: the carried weapons, every
## body slot and the base stats the next recompute is built from.
func _offer_state(main: Node) -> String:
	var inventory: Inventory = main._inventory
	var base_stats: Stats = main._base_stats
	var equipment := ""
	for slot in Inventory.SLOTS:
		var item: EquipmentData = inventory.item_in_slot(slot)
		equipment += "%s=%s;" % [slot, item.id if item != null else ""]
	return "%d|%.4f|%.4f|%.4f|%.4f|%.4f|%.4f|%s" % [
		inventory.weapons.size(),
		base_stats.max_hp,
		base_stats.move_speed_mult,
		base_stats.damage_mult,
		base_stats.attack_speed_mult,
		base_stats.range_mult,
		base_stats.crit_chance_bonus,
		equipment,
	]


## Asserts integer equality, keeping the original label in the failure message.
func _assert_int(label: String, actual: int, expected: int) -> void:
	assert_int(actual) \
		.override_failure_message(
			"%s — got %d, expected %d" % [label, actual, expected]
		) \
		.is_equal(expected)


## Asserts float equality within the original 0.001 tolerance.
func _assert_close(label: String, actual: float, expected: float) -> void:
	var delta := absf(actual - expected)
	assert_float(delta) \
		.override_failure_message(
			"%s — got %.3f, expected %.3f" % [label, actual, expected]
		) \
		.is_less_equal(FLOAT_EPSILON)
