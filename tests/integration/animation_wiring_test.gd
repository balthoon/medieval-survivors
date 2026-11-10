## Integration tests for the lot 2 animation wiring (ADR-0003).
##
## The unit suite pins the timers. This one pins the connections between the
## systems: the real main scene must route a weapon shot into the player's
## lunge, and EnemyManager.remove_dead must spawn the visual DeathFade while
## keeping the XP drop and the enemy lifecycle exactly as they were.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const SKELETON_PATH := "res://data/enemies/squelette.tres"
const DELTA := 0.1
const EPSILON := 0.001


func test_main_scene_routes_a_shot_into_the_player_lunge() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).override_failure_message("main.tscn instantiates").is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.set_process(false)
	var player := main.get_node_or_null("Player") as Player
	var weapons := main.get_node_or_null("WeaponSystem") as WeaponSystem
	assert_object(player).override_failure_message("the scene has a Player").is_not_null()
	assert_object(weapons).override_failure_message("the scene has a WeaponSystem").is_not_null()
	if player == null or weapons == null:
		return
	# Start from a resting body so the emission is the only thing that can arm it.
	player._lunge_time = 0.0

	# Act — exactly what a firing weapon emits.
	weapons.attack_started.emit(PI * 0.5)

	# Assert
	assert_float(player._lunge_time).override_failure_message(
		"a firing weapon must start the player's lunge"
	).is_equal_approx(Player.LUNGE_DURATION, EPSILON)
	assert_vector(player._lunge_direction).override_failure_message(
		"the lunge follows the angle the weapon fired along"
	).is_equal_approx(Vector2.DOWN, Vector2(EPSILON, EPSILON))


func test_remove_dead_spawns_a_fade_and_keeps_the_xp_drop() -> void:
	# Arrange — a standalone manager, so no wave enemy can pollute the counts.
	var container := Node2D.new()
	add_child(container)
	auto_free(container)
	var manager := EnemyManager.new()
	auto_free(manager)
	var skeleton := load(SKELETON_PATH) as EnemyData
	assert_object(skeleton).override_failure_message("squelette.tres loads").is_not_null()
	if skeleton == null:
		return
	var death_spot := Vector2(700.0, 420.0)
	var enemy := manager.spawn(skeleton, death_spot, container)
	# The manager may push a spawn out of a prop; the fade must copy where the
	# body actually stood, not where it was requested.
	var fell_at := enemy.position
	enemy.take_damage(9999.0)

	# Act
	var dropped_xp := manager.remove_dead(Callable())

	# Assert — loot and lifecycle are untouched.
	assert_int(dropped_xp).override_failure_message(
		"the XP drop is unchanged by the death effect"
	).is_equal(skeleton.xp_value)
	assert_int(manager.count()).override_failure_message(
		"the dead enemy leaves the manager immediately"
	).is_equal(0)
	# Assert — exactly one visual fade, where the body fell.
	var fades: Array[DeathFade] = []
	for child: Node in container.get_children():
		if child is DeathFade:
			fades.append(child as DeathFade)
	assert_int(fades.size()).override_failure_message(
		"remove_dead creates exactly one DeathFade per kill"
	).is_equal(1)
	if fades.size() == 1:
		assert_vector(fades[0].position).override_failure_message(
			"the fade plays where the body fell"
		).is_equal_approx(fell_at, Vector2(EPSILON, EPSILON))
		assert_bool(fades[0].art == skeleton.art).override_failure_message(
			"the fade draws the dead enemy's art"
		).is_true()


func test_step_all_advances_the_animation_of_a_living_enemy() -> void:
	# Arrange
	var container := Node2D.new()
	add_child(container)
	auto_free(container)
	var manager := EnemyManager.new()
	auto_free(manager)
	var skeleton := load(SKELETON_PATH) as EnemyData
	assert_object(skeleton).override_failure_message("squelette.tres loads").is_not_null()
	if skeleton == null:
		return
	var enemy := manager.spawn(skeleton, Vector2(500.0, 400.0), container)
	var start := enemy.position
	var before := enemy._anim_time

	# Act
	manager.step_all(Vector2(640.0, 360.0), DELTA)

	# Assert — the enemy closes in and its waddle clock runs.
	assert_float(enemy._anim_time).override_failure_message(
		"step_all drives the living enemy's animation clock"
	).is_equal_approx(before + DELTA, EPSILON)
	assert_float(enemy.position.distance_to(start)).override_failure_message(
		"the enemy still moves toward the player"
	).is_greater(0.0)
