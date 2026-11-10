## Lot 1: weapon levels.
##
## A level is run state, not content: the .tres stays shared by every run, so
## the level lives in the Inventory keyed by the weapon's stable id. The level
## step is additive on the base stat and applies before the player's global
## multiplier, so level 4 with a 0.25 step is x1.75 — not x1.25^3.
##
## Every test builds its own WeaponData and Stats: no file, no scene tree, no
## shared state, so the suite passes in any execution order.
extends GdUnitTestSuite

const BASE_DAMAGE := 10.0
const BASE_CADENCE := 2.0
const BASE_RANGE := 100.0


## A weapon resource tuned for these tests, away from any content file.
func _weapon(id: String = "test_blade") -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = id
	weapon.display_name = "Lame de test"
	weapon.damage = BASE_DAMAGE
	weapon.attacks_per_second = BASE_CADENCE
	weapon.range_px = BASE_RANGE
	weapon.crit_chance = 0.0
	weapon.max_level = 4
	weapon.level_damage_step = 0.25
	weapon.level_cadence_step = 0.05
	weapon.level_range_step = 0.05
	return weapon


func test_level_damage_step_is_additive_on_the_base_stat() -> void:
	# Arrange
	var weapon := _weapon()

	# Act / Assert
	assert_float(Stats.level_damage_multiplier(weapon, 1)).is_equal_approx(1.0, 0.0001)
	assert_float(Stats.level_damage_multiplier(weapon, 2)).is_equal_approx(1.25, 0.0001)
	assert_float(Stats.level_damage_multiplier(weapon, 4)).is_equal_approx(1.75, 0.0001)


func test_level_damage_applies_before_the_global_multiplier() -> void:
	# Arrange
	var weapon := _weapon()
	var stats := Stats.new()
	stats.damage_mult = 1.2

	# Act
	var damage := stats.weapon_damage(weapon, 4)

	# Assert — base x level step, then the global multiplier: 10 x 1.75 x 1.2.
	assert_float(damage).override_failure_message(
		"the level step scales the base damage, then damage_mult applies"
	).is_equal_approx(BASE_DAMAGE * 1.75 * 1.2, 0.0001)


func test_level_cadence_adds_five_percent_per_level() -> void:
	# Arrange
	var weapon := _weapon()
	var stats := Stats.new()
	stats.attack_speed_mult = 1.3

	# Act
	var cadence := stats.weapon_attacks_per_second(weapon, 4)

	# Assert — A1 keeps the cadence step at 5 %, and the global multiplier stacks.
	assert_float(Stats.level_cadence_multiplier(weapon, 2)).is_equal_approx(1.05, 0.0001)
	assert_float(Stats.level_cadence_multiplier(weapon, 4)).is_equal_approx(1.15, 0.0001)
	assert_float(cadence).is_equal_approx(BASE_CADENCE * 1.15 * 1.3, 0.0001)


func test_level_range_scales_range_px_and_orbit_radius() -> void:
	# Arrange
	var weapon := _weapon()
	var stats := Stats.new()
	stats.range_mult = 1.1

	# Act
	var reach := stats.weapon_range(weapon, 4)
	var multiplier := stats.weapon_range_multiplier(weapon, 4)

	# Assert — the orbit multiplies its radius by this same multiplier (E20).
	assert_float(reach).is_equal_approx(BASE_RANGE * 1.15 * 1.1, 0.0001)
	assert_float(multiplier).is_equal_approx(1.15 * 1.1, 0.0001)


func test_level_below_one_reads_as_level_one() -> void:
	# Arrange
	var weapon := _weapon()

	# Act / Assert — a zero or negative level never shrinks a weapon.
	assert_float(Stats.level_damage_multiplier(weapon, 0)).is_equal_approx(1.0, 0.0001)
	assert_float(Stats.level_cadence_multiplier(weapon, -3)).is_equal_approx(1.0, 0.0001)


func test_inventory_upgrade_stops_at_max_level() -> void:
	# Arrange
	var weapon := _weapon()
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)

	# Act
	var first := inventory.upgrade_weapon(weapon)
	var second := inventory.upgrade_weapon(weapon)
	var third := inventory.upgrade_weapon(weapon)
	var fourth := inventory.upgrade_weapon(weapon)

	# Assert
	assert_bool(first).is_true()
	assert_bool(second).is_true()
	assert_bool(third).is_true()
	assert_bool(fourth).override_failure_message(
		"a weapon at max_level refuses another upgrade"
	).is_false()
	assert_int(inventory.level_of(weapon)).is_equal(4)


func test_inventory_refuses_to_upgrade_a_weapon_not_carried() -> void:
	# Arrange
	var weapon := _weapon()
	var inventory := Inventory.new()

	# Act
	var upgraded := inventory.upgrade_weapon(weapon)

	# Assert
	assert_bool(upgraded).is_false()
	assert_int(inventory.level_of(weapon)).is_equal(1)


func test_new_weapon_starts_at_level_one() -> void:
	# Arrange
	var weapon := _weapon()
	var inventory := Inventory.new()

	# Act
	inventory.add_weapon(weapon)

	# Assert
	assert_int(inventory.level_of(weapon)).is_equal(1)


func test_replacing_a_weapon_resets_the_slot_to_level_one() -> void:
	# Arrange
	var first := _weapon("first")
	var second := _weapon("second")
	var inventory := Inventory.new()
	inventory.add_weapon(first)
	inventory.upgrade_weapon(first)
	inventory.upgrade_weapon(first)

	# Act
	inventory.replace_weapon(0, second)

	# Assert — the level belongs to the weapon, not to the slot.
	assert_int(inventory.level_of(second)).is_equal(1)
	assert_int(inventory.level_of(first)).override_failure_message(
		"the displaced weapon's level is forgotten"
	).is_equal(1)


func test_new_run_clears_the_previous_levels() -> void:
	# Arrange
	var weapon := _weapon()
	var inventory := Inventory.new()
	inventory.setup_starting(weapon)
	inventory.upgrade_weapon(weapon)
	inventory.upgrade_weapon(weapon)

	# Act
	inventory.setup_starting(weapon)

	# Assert
	assert_int(inventory.level_of(weapon)).is_equal(1)


func test_damage_roll_uses_the_requested_level() -> void:
	# Arrange
	var weapon := _weapon()
	var stats := Stats.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# Act
	var level_1 := DamageCalc.roll(stats, weapon, rng, 1)
	var level_3 := DamageCalc.roll(stats, weapon, rng, 3)

	# Assert — the level is an explicit input, so a hit in flight keeps its own.
	assert_bool(bool(level_1["is_crit"])).is_false()
	assert_bool(bool(level_3["is_crit"])).is_false()
	assert_float(float(level_1["amount"])).is_equal_approx(BASE_DAMAGE, 0.0001)
	assert_float(float(level_3["amount"])).is_equal_approx(BASE_DAMAGE * 1.5, 0.0001)


func test_damage_roll_defaults_to_level_one() -> void:
	# Arrange
	var weapon := _weapon()
	var stats := Stats.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Act
	var hit := DamageCalc.roll(stats, weapon, rng)

	# Assert — every legacy call site that omits the level keeps level-1 damage.
	assert_float(float(hit["amount"])).is_equal_approx(BASE_DAMAGE, 0.0001)
