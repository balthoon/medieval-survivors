## Integration suite for slice 0.3: build rules, survivability and feel wiring.
##
## Ported from tools/verify_slice03.gd (SceneTree + PASS/FAIL counters) to
## gdUnit4 assertions. Every test instantiates its own real main scene through
## MainSceneFixture, so no test depends on state left by another — gdUnit4 may
## run them in any order.
##
## Covers: additive stat rules, the crit multiplier source, rarity weights,
## equipment text, weapon swing timings, player invulnerability, the enemy hit
## signal, the dominated-equipment filter and the reroll budget.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const EPEE := "res://data/weapons/epee_longue.tres"
const DAGUE := "res://data/weapons/dague.tres"
const MARTEAU := "res://data/weapons/marteau.tres"
const ARC := "res://data/weapons/arc_court.tres"
const CASQUE_FER := "res://data/equipment/casque_fer.tres"


func test_wiring_connects_run_services() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var weapons: WeaponSystem = main.get_node_or_null("WeaponSystem") as WeaponSystem
	assert_object(weapons).is_not_null()
	if weapons == null:
		return

	# Act
	var cooldown_count: int = main._weapon_cooldown_seconds().size()
	var inventory_count: int = main._inventory.weapons.size()

	# Assert
	assert_object(main._fx).override_failure_message("Fx wired").is_not_null()
	assert_object(main._sfx).override_failure_message("Sfx wired").is_not_null()
	assert_object(main._camera).override_failure_message("Camera wired").is_not_null()
	assert_object(weapons.fx).override_failure_message(
		"weapon system uses the run Fx"
	).is_same(main._fx)
	assert_object(weapons.sfx).override_failure_message(
		"weapon system uses the run Sfx"
	).is_same(main._sfx)
	assert_int(cooldown_count).override_failure_message(
		"cooldown seconds match the inventory"
	).is_equal(inventory_count)


func test_xp_curve_costs_5_9_21() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)

	# Act
	var level_1: float = main.xp_to_next(1)
	var level_2: float = main.xp_to_next(2)
	var level_5: float = main.xp_to_next(5)

	# Assert
	assert_float(level_1).override_failure_message(
		"level 1 costs 5 xp"
	).is_equal_approx(5.0, 0.001)
	assert_float(level_2).override_failure_message(
		"level 2 costs 9 xp"
	).is_equal_approx(9.0, 0.001)
	assert_float(level_5).override_failure_message(
		"level 5 costs 21 xp"
	).is_equal_approx(21.0, 0.001)


func test_additive_stats_share_one_multiplier() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var stats := Stats.new()
	var upgrade := UpgradeData.new()
	upgrade.stat = "damage"
	upgrade.amount = 0.2

	# Act
	stats.apply_upgrade(upgrade)
	stats.apply_upgrade(upgrade)
	var speed_upgrade := UpgradeData.new()
	speed_upgrade.stat = "move_speed"
	speed_upgrade.amount = 0.12
	stats.apply_upgrade(speed_upgrade)
	var move_speed_mult_after_upgrade := stats.move_speed_mult
	var speed_after_upgrade := stats.effective_move_speed()
	var item := EquipmentData.new()
	item.stat = "move_speed"
	item.amount = 0.16
	stats.apply_equipment(item)
	var move_speed_mult_after_equipment := stats.move_speed_mult
	var speed_after_equipment := stats.effective_move_speed()

	# Assert
	assert_float(stats.damage_mult).override_failure_message(
		"two +20% damage upgrades give x1.40"
	).is_equal_approx(1.4, 0.001)
	assert_float(move_speed_mult_after_upgrade).override_failure_message(
		"move speed multiplier is additive"
	).is_equal_approx(1.12, 0.001)
	assert_float(speed_after_upgrade).override_failure_message(
		"effective move speed"
	).is_equal_approx(220.0 * 1.12, 0.001)
	assert_float(move_speed_mult_after_equipment).override_failure_message(
		"equipment adds to the same multiplier"
	).is_equal_approx(1.28, 0.001)
	assert_float(speed_after_equipment).override_failure_message(
		"effective move speed after equipment"
	).is_equal_approx(220.0 * 1.28, 0.001)


func test_crit_roll_uses_weapon_multiplier() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var weapon := WeaponData.new()
	weapon.damage = 10.0
	weapon.crit_chance = 0.75
	weapon.crit_multiplier = 2.5
	var stats := Stats.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var crits := 0
	var crit_amount_ok := true

	# Act
	for _i in 50:
		var hit := DamageCalc.roll(stats, weapon, rng)
		if hit["is_crit"]:
			crits += 1
			if absf(float(hit["amount"]) - 25.0) > 0.001:
				crit_amount_ok = false
		elif absf(float(hit["amount"]) - 10.0) > 0.001:
			crit_amount_ok = false

	# Assert
	assert_int(1 if crits > 0 else 0).override_failure_message(
		"crits rolled"
	).is_equal(1)
	assert_int(1 if crit_amount_ok else 0).override_failure_message(
		"crit uses the weapon multiplier"
	).is_equal(1)


func test_rarity_weights_descend_with_fallback() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)

	# Act
	var commun := EquipmentData.offer_weight_for_rarity("commun")
	var peu_commun := EquipmentData.offer_weight_for_rarity("peu_commun")
	var rare := EquipmentData.offer_weight_for_rarity("rare")
	var epique := EquipmentData.offer_weight_for_rarity("epique")
	var legendaire := EquipmentData.offer_weight_for_rarity("legendaire")
	var mythique := EquipmentData.offer_weight_for_rarity("mythique")
	var unknown := EquipmentData.offer_weight_for_rarity("inconnu")

	# Assert
	assert_float(commun).override_failure_message(
		"commun weight"
	).is_equal_approx(1.0, 0.001)
	assert_float(peu_commun).override_failure_message(
		"peu_commun weight"
	).is_equal_approx(0.8, 0.001)
	assert_float(rare).override_failure_message(
		"rare weight"
	).is_equal_approx(0.55, 0.001)
	assert_float(epique).override_failure_message(
		"epique weight"
	).is_equal_approx(0.35, 0.001)
	assert_float(legendaire).override_failure_message(
		"legendaire weight"
	).is_equal_approx(0.22, 0.001)
	assert_float(mythique).override_failure_message(
		"mythique weight"
	).is_equal_approx(0.12, 0.001)
	assert_float(unknown).override_failure_message(
		"unknown rarity falls back"
	).is_equal_approx(0.5, 0.001)


func test_equipment_text_formats_each_stat() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var hp_item := EquipmentData.new()
	hp_item.stat = "max_hp"
	hp_item.amount = 15.0
	var damage_item := EquipmentData.new()
	damage_item.stat = "damage"
	damage_item.amount = 0.22
	var crit_item := EquipmentData.new()
	crit_item.stat = "crit_chance"
	crit_item.amount = 0.06

	# Act
	var hp_text := hp_item.effect_text()
	var damage_text := damage_item.effect_text()
	var crit_text := crit_item.effect_text()

	# Assert
	assert_str(hp_text).override_failure_message(
		"flat hp text"
	).is_equal("+15 PV")
	assert_str(damage_text).override_failure_message(
		"damage text"
	).is_equal("+22 % dégâts")
	assert_str(crit_text).override_failure_message(
		"crit text"
	).is_equal("+6 % critique")


func test_swing_timings_match_weapon_resources() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var epee := load(EPEE) as WeaponData
	var dague := load(DAGUE) as WeaponData
	var marteau := load(MARTEAU) as WeaponData
	var arc := load(ARC) as WeaponData
	assert_object(epee).override_failure_message("epee resource loads").is_not_null()
	assert_object(dague).override_failure_message("dague resource loads").is_not_null()
	assert_object(marteau).override_failure_message("marteau resource loads").is_not_null()
	assert_object(arc).override_failure_message("arc resource loads").is_not_null()
	if epee == null or dague == null or marteau == null or arc == null:
		return

	# Act
	var epee_swing := epee.swing_duration
	var dague_swing := dague.swing_duration
	var marteau_swing := marteau.swing_duration
	var arc_swing := arc.swing_duration

	# Assert
	assert_float(epee_swing).override_failure_message(
		"epee swing"
	).is_equal_approx(0.12, 0.001)
	assert_float(dague_swing).override_failure_message(
		"dague swing"
	).is_equal_approx(0.08, 0.001)
	assert_float(marteau_swing).override_failure_message(
		"marteau swing"
	).is_equal_approx(0.22, 0.001)
	assert_float(arc_swing).override_failure_message(
		"arc swing"
	).is_equal_approx(0.12, 0.001)


func test_invulnerability_ignores_hits_inside_window() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var player: Player = main.get_node_or_null("Player") as Player
	assert_object(player).override_failure_message("player exists").is_not_null()
	if player == null:
		return
	player.heal(1000.0)
	var before := player.hp

	# Act
	var first_landed := player.take_damage(10.0)
	var after_first := player.hp
	var second_landed := player.take_damage(10.0)
	var after_second := player.hp
	player.step(Player.INVULNERABLE_TIME + 0.01)
	var third_landed := player.take_damage(10.0)

	# Assert
	assert_int(1 if first_landed else 0).override_failure_message(
		"first hit lands"
	).is_equal(1)
	assert_float(after_first).override_failure_message(
		"first hit removed hp"
	).is_equal_approx(before - 10.0, 0.001)
	assert_int(1 if second_landed else 0).override_failure_message(
		"second hit is ignored"
	).is_equal(0)
	assert_float(after_second).override_failure_message(
		"ignored hit removed nothing"
	).is_equal_approx(before - 10.0, 0.001)
	assert_int(1 if third_landed else 0).override_failure_message(
		"hit lands again after the window"
	).is_equal(1)
	assert_float(player.hp).override_failure_message(
		"third hit removed hp"
	).is_equal_approx(before - 20.0, 0.001)


func test_melee_hit_lands_and_emits_hit_landed() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var player: Player = main.get_node_or_null("Player") as Player
	var manager: EnemyManager = main.get_node_or_null("EnemyManager") as EnemyManager
	var weapons: WeaponSystem = main.get_node_or_null("WeaponSystem") as WeaponSystem
	assert_object(player).override_failure_message("player exists").is_not_null()
	assert_object(manager).override_failure_message("enemy manager exists").is_not_null()
	assert_object(weapons).override_failure_message("weapon system exists").is_not_null()
	if player == null or manager == null or weapons == null:
		return
	# Clean field: only the enemy this test spawns may be targeted.
	manager.remove_dead(Callable())
	var landed := [0]
	weapons.hit_landed.connect(
		func(_is_crit: bool, _amount: float, _at: Vector2) -> void: landed[0] += 1
	)
	var enemy := manager.spawn(
		_sample_enemy(200.0), player.position + Vector2(40.0, 0.0), main.get_node("Enemies") as Node2D
	)
	assert_object(enemy).override_failure_message("enemy spawned").is_not_null()
	if enemy == null:
		return

	# Act
	for _i in 6:
		weapons.step(0.1)

	# Assert
	assert_int(1 if enemy.hp < 200.0 else 0).override_failure_message(
		"melee weapon damaged the target"
	).is_equal(1)
	assert_int(1 if landed[0] > 0 else 0).override_failure_message(
		"hit_landed fired"
	).is_equal(1)

	# Cleanup: drop the dead enemy through the run's real loot callback.
	enemy.hp = 0.0
	manager.remove_dead(main._drop_pickup)


func test_dominated_equipment_is_never_offered() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var helmet := load(CASQUE_FER) as EquipmentData
	assert_object(helmet).override_failure_message("helmet resource loads").is_not_null()
	if helmet == null:
		return

	# Act
	main._gain_equipment(helmet)
	var equipped: EquipmentData = main._inventory.item_in_slot("casque")
	var dominated := 0
	for offer in main._build_offers(200):
		if offer.kind != "equipment" or offer.equipment == null:
			continue
		if offer.equipment.slot != "casque" or equipped == null:
			continue
		if offer.equipment.stat != equipped.stat:
			continue
		if offer.equipment.amount <= equipped.amount:
			dominated += 1

	# Assert
	assert_object(equipped).override_failure_message("helmet equipped").is_not_null()
	assert_int(dominated).override_failure_message(
		"no dominated helmet offered"
	).is_equal(0)


func test_reroll_spends_charge_and_rebuilds_choices() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._rerolls = 1

	# Act
	main._on_reroll_requested()
	var rerolls_after_first: int = main._rerolls
	var choice_count: int = main._pending_choices.size()
	main._on_reroll_requested()
	var rerolls_after_second: int = main._rerolls

	# Assert
	assert_int(rerolls_after_first).override_failure_message(
		"reroll spent"
	).is_equal(0)
	assert_int(choice_count).override_failure_message(
		"reroll rebuilt three choices"
	).is_equal(3)
	assert_int(rerolls_after_second).override_failure_message(
		"empty reroll budget kept"
	).is_equal(0)


## Minimal enemy tuning for the hit-signal check: stationary, harmless, 200 hp.
func _sample_enemy(hp: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = int(hp)
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.contact_damage = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data
