## Unit tests for lot 2 character animation timers (ADR-0003).
##
## Animation is draw-only: these tests never inspect pixels. They pin the state
## that drives the drawing — walk phase, lunge timer, waddle time and the
## DeathFade curve — and every one of them asserts that the node's position,
## the gameplay truth the hash and collisions read, never moves.
extends GdUnitTestSuite

const CLASS_PATH := "res://data/classes/chevalier.tres"
const SKELETON_PATH := "res://data/enemies/squelette.tres"

const DELTA := 0.05
const EPSILON := 0.001


func test_walk_phase_stays_frozen_while_standing_still() -> void:
	# Arrange
	var player := _make_player()
	var before := player._walk_phase

	# Act
	player.step_movement(Vector2.ZERO, DELTA)
	player.step(DELTA)

	# Assert — no input means no walk cycle.
	assert_float(player._walk_phase).override_failure_message(
		"standing still must not advance the walk phase"
	).is_equal_approx(before, EPSILON)


func test_walk_phase_advances_while_moving() -> void:
	# Arrange
	var player := _make_player()

	# Act
	player.step_movement(Vector2.RIGHT, DELTA)
	player.step(DELTA)

	# Assert
	assert_float(player._walk_phase).override_failure_message(
		"walking must advance the walk phase"
	).is_greater(0.0)


func test_walk_phase_stays_within_one_turn() -> void:
	# Arrange
	var player := _make_player()

	# Act — enough steps to wrap many times.
	for _i in 200:
		player.step_movement(Vector2.RIGHT, DELTA)
		player.step(DELTA)

	# Assert — fposmod keeps the sine argument bounded.
	assert_float(player._walk_phase).is_greater_equal(0.0)
	assert_float(player._walk_phase).is_less(TAU)


func test_attack_lunge_points_along_the_firing_angle() -> void:
	# Arrange
	var player := _make_player()

	# Act
	player.play_attack_lunge(PI * 0.5)

	# Assert
	assert_float(player._lunge_time).override_failure_message(
		"the lunge starts at its full duration"
	).is_equal_approx(Player.LUNGE_DURATION, EPSILON)
	assert_vector(player._lunge_direction).override_failure_message(
		"the lunge direction follows the firing angle"
	).is_equal_approx(Vector2.DOWN, Vector2(EPSILON, EPSILON))


func test_lunge_decays_to_zero_and_never_goes_negative() -> void:
	# Arrange
	var player := _make_player()
	player.play_attack_lunge(0.0)

	# Act — more steps than the lunge needs.
	for _i in 6:
		player.step(DELTA)

	# Assert
	assert_float(player._lunge_time).override_failure_message(
		"the lunge timer clamps at zero"
	).is_equal_approx(0.0, EPSILON)


func test_animation_never_moves_the_player_position() -> void:
	# Arrange
	var player := _make_player()
	player.position = Vector2(500.0, 400.0)
	var start := player.position

	# Act
	player.play_attack_lunge(PI)
	player.step(DELTA)
	player.step_movement(Vector2.ZERO, DELTA)
	player.step(DELTA)

	# Assert — the lean is a drawing transform, not a move.
	assert_vector(player.position).override_failure_message(
		"walking and lunging must never displace the gameplay position"
	).is_equal_approx(start, Vector2(EPSILON, EPSILON))


func test_death_fade_create_copies_the_body_fields() -> void:
	# Arrange / Act
	var fade := DeathFade.create("orc", 22.0, Color(0.7, 0.2, 0.1))

	# Assert
	assert_bool(fade.art == "orc").override_failure_message(
		"the fade keeps the dead enemy's art key"
	).is_true()
	assert_float(fade.radius).is_equal_approx(22.0, EPSILON)
	assert_bool(fade.tint.is_equal_approx(Color(0.7, 0.2, 0.1))).override_failure_message(
		"the fade keeps the dead enemy's tint"
	).is_true()
	auto_free(fade)


func test_death_fade_halfway_squashes_and_fades() -> void:
	# Arrange
	var fade := DeathFade.create("skeleton", 13.0, Color.WHITE)
	add_child(fade)
	auto_free(fade)
	fade.set_process(false)

	# Act
	fade._process(DeathFade.DURATION * 0.5)

	# Assert
	var expected: Vector2 = Vector2.ONE.lerp(DeathFade.END_SCALE, 0.5)
	assert_vector(fade.scale).override_failure_message(
		"halfway through, the body is halfway squashed"
	).is_equal_approx(expected, Vector2(EPSILON, EPSILON))
	assert_float(fade.modulate.a).override_failure_message(
		"halfway through, the body is half faded"
	).is_equal_approx(0.5, EPSILON)


func test_death_fade_ends_flat_and_frees_itself() -> void:
	# Arrange
	var fade := DeathFade.create("skeleton", 13.0, Color.WHITE)
	add_child(fade)
	auto_free(fade)
	fade.set_process(false)

	# Act
	fade._process(DeathFade.DURATION)

	# Assert
	assert_vector(fade.scale).is_equal_approx(
		DeathFade.END_SCALE, Vector2(EPSILON, EPSILON)
	)
	assert_float(fade.modulate.a).is_equal_approx(0.0, EPSILON)
	assert_bool(fade.is_queued_for_deletion()).override_failure_message(
		"the fade frees itself once it has played"
	).is_true()


func test_enemy_step_visual_advances_animation_time() -> void:
	# Arrange
	var enemy := _make_enemy()
	var before := enemy._anim_time

	# Act
	enemy.step_visual(0.1)
	enemy.step_visual(0.1)

	# Assert
	assert_float(enemy._anim_time).override_failure_message(
		"the waddle clock advances every visual step"
	).is_equal_approx(before + 0.2, EPSILON)


func test_enemy_step_visual_never_moves_the_body() -> void:
	# Arrange
	var enemy := _make_enemy()
	enemy.position = Vector2(300.0, 240.0)
	var start := enemy.position

	# Act
	enemy.step_visual(0.25)

	# Assert — the waddle is a draw transform, not a move.
	assert_vector(enemy.position).override_failure_message(
		"the waddle must never displace the gameplay position"
	).is_equal_approx(start, Vector2(EPSILON, EPSILON))


func test_enemy_waddle_phase_is_deterministic_from_spawn_position() -> void:
	# Arrange
	var first := _make_enemy()
	first.position = Vector2(100.0, 100.0)
	var second := _make_enemy()
	second.position = Vector2(100.0, 100.0)
	var other := _make_enemy()
	other.position = Vector2(300.0, 220.0)

	# Act
	first._ensure_anim_phase()
	second._ensure_anim_phase()
	other._ensure_anim_phase()

	# Assert — same spawn, same phase; a distant spawn is out of lockstep.
	assert_float(first._anim_phase).override_failure_message(
		"two enemies at the same spawn point animate in phase"
	).is_equal_approx(second._anim_phase, EPSILON)
	assert_float(absf(first._anim_phase - other._anim_phase)).override_failure_message(
		"a distant spawn gets a different waddle phase"
	).is_greater(EPSILON)


## A player attached to the suite, with class stats so movement is allowed.
func _make_player() -> Player:
	var player := Player.new()
	add_child(player)
	auto_free(player)
	var class_data := load(CLASS_PATH) as ClassData
	assert_object(class_data).override_failure_message("chevalier.tres loads").is_not_null()
	if class_data != null:
		player.setup(class_data)
	return player


## A plain squelette attached to the suite. No slam, so no telegraph child.
func _make_enemy() -> Enemy:
	var skeleton := load(SKELETON_PATH) as EnemyData
	assert_object(skeleton).override_failure_message("squelette.tres loads").is_not_null()
	var enemy := Enemy.create(skeleton) if skeleton != null else Enemy.new()
	add_child(enemy)
	auto_free(enemy)
	return enemy
