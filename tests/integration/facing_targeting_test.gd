## Integration tests for the blade-tracks-nearest-enemy rule in main.gd.
##
## Port of the throwaway tools/verify_facing.gd script: the real main scene is
## instantiated, wave spawning is silenced, and the rule is driven through
## Main._update_facing(). The three original cases are kept one test each:
##   1. no living enemy -> the blade follows the movement direction;
##   2. one enemy far outside weapon range -> the blade still aims at it;
##   3. a nearer enemy appears -> the blade switches to the nearer one.
##
## Every test builds its own scene: gdUnit4 may run tests in any order, so no
## test may rely on state left behind by another.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

## Tolerance on the facing angle, in radians, carried over from verify_facing.gd.
const ANGLE_EPSILON := 0.05


func test_no_enemy_alive_faces_movement_direction() -> void:
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
	# Mirrors verify_facing.gd: with the pool empty no new enemy can spawn, and
	# this drops any dead one left from the frames before the pool was cleared.
	manager.remove_dead(Callable())

	# Act
	main._update_facing(Vector2.DOWN)

	# Assert
	var living := _count_living(manager)
	assert_int(living) \
		.override_failure_message(
			"field cleared before case 1 — %d enemies still alive" % living
		) \
		.is_equal(0)
	_assert_facing("no enemy alive, facing down", player.facing, PI * 0.5)


func test_far_enemy_outside_weapon_range_is_still_faced() -> void:
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
	manager.remove_dead(Callable())

	# 400 px away: well outside any weapon range, but nearest_to() is unbounded.
	var far_at := player.position + Vector2(400.0, 0.0)
	var far_enemy := manager.spawn(_sample_enemy(), far_at, main.get_node("Enemies") as Node2D)
	assert_object(far_enemy).is_not_null()

	# Act
	main._update_facing(Vector2.DOWN)

	# Assert
	_assert_facing("far enemy, facing it", player.facing, 0.0)


func test_nearer_enemy_wins_over_far_enemy() -> void:
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
	manager.remove_dead(Callable())

	var container := main.get_node("Enemies") as Node2D
	var far_enemy := manager.spawn(
		_sample_enemy(), player.position + Vector2(400.0, 0.0), container
	)
	var near_enemy := manager.spawn(
		_sample_enemy(), player.position + Vector2(-120.0, 0.0), container
	)
	assert_object(far_enemy).is_not_null()
	assert_object(near_enemy).is_not_null()

	# Act — movement points up, but the nearer enemy lies to the left.
	main._update_facing(Vector2.UP)

	# Assert — PI or -PI both mean "left"; absf keeps the original comparison.
	_assert_facing("nearer enemy wins", absf(player.facing), PI)


## Number of enemies still alive in [param manager], counted the way
## verify_facing.gd counted them before its first case.
func _count_living(manager: EnemyManager) -> int:
	var living := 0
	for enemy in manager.enemies:
		if enemy != null and enemy.hp > 0.0:
			living += 1
	return living


## The minimal archetype verify_facing.gd spawned: no movement, low health.
func _sample_enemy() -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = 10
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data


## Asserts that [param actual] points within ANGLE_EPSILON of [param expected],
## comparing shortest-arc deltas exactly as verify_facing.gd did.
func _assert_facing(label: String, actual: float, expected: float) -> void:
	var delta := absf(wrapf(actual - expected, -PI, PI))
	assert_float(delta) \
		.override_failure_message(
			"%s — got %.3f rad, expected %.3f rad" % [label, actual, expected]
		) \
		.is_less_equal(ANGLE_EPSILON)
