## Regression check for W0-E3: moving the run tuning out of src/main.gd into
## res://data/run_config.tres must not have changed a single value.
##
## Each test loads the resource itself and touches no shared state, so the suite
## passes in any execution order.
extends GdUnitTestSuite

const RUN_CONFIG_PATH := "res://data/run_config.tres"


func test_run_config_resource_loads() -> void:
	# Arrange / Act
	var config := load(RUN_CONFIG_PATH) as RunConfig

	# Assert
	assert_object(config).override_failure_message(
		"run_config.tres loads as a RunConfig resource"
	).is_not_null()


func test_xp_curve_matches_historical_constants() -> void:
	# Arrange
	var config := load(RUN_CONFIG_PATH) as RunConfig
	assert_object(config).override_failure_message(
		"run_config.tres loads as a RunConfig resource"
	).is_not_null()
	if config == null:
		return

	# Act — the same curve main.xp_to_next() evaluates.
	var level_1 := float(config.xp_base + (1 - 1) * config.xp_per_level)
	var level_2 := float(config.xp_base + (2 - 1) * config.xp_per_level)
	var level_5 := float(config.xp_base + (5 - 1) * config.xp_per_level)

	# Assert
	assert_int(config.xp_base).override_failure_message(
		"first level costs 5 xp"
	).is_equal(5)
	assert_int(config.xp_per_level).override_failure_message(
		"each level adds 4 xp"
	).is_equal(4)
	assert_float(level_1).override_failure_message(
		"level 1 costs 5 xp"
	).is_equal_approx(5.0, 0.001)
	assert_float(level_2).override_failure_message(
		"level 2 costs 9 xp"
	).is_equal_approx(9.0, 0.001)
	assert_float(level_5).override_failure_message(
		"level 5 costs 21 xp"
	).is_equal_approx(21.0, 0.001)


func test_boss_tier_multipliers_match_historical_constants() -> void:
	# Arrange
	var config := load(RUN_CONFIG_PATH) as RunConfig
	assert_object(config).override_failure_message(
		"run_config.tres loads as a RunConfig resource"
	).is_not_null()
	if config == null:
		return

	# Act
	var hp_per_tier := config.boss_hp_per_tier
	var damage_per_tier := config.boss_damage_per_tier

	# Assert
	assert_float(hp_per_tier).override_failure_message(
		"boss hp grows 90% per tier"
	).is_equal_approx(0.9, 0.0001)
	assert_float(damage_per_tier).override_failure_message(
		"boss damage grows 35% per tier"
	).is_equal_approx(0.35, 0.0001)
