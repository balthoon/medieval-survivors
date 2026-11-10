## Integration tests for prop collisions in the real main scene (lot 1).
##
## Proves the scene wires one ObstacleField into both the player's slide and the
## enemy manager, that a tree trunk stops the player, and that an enemy spawned
## on a trunk is resolved outside it.
##
## The walk is driven by hand: set_process(false) stops the engine's own frames
## and the test calls main._process(delta) itself, so input and timing are
## deterministic and headless-safe. Input.action_press/action_release feed the
## same InputMap path a keyboard does.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const SKELETON_PATH := "res://data/enemies/squelette.tres"

## Tree 7 from PilotArenas.TREES, (690, 548, 34): centre (x, y + z * 0.88) and
## radius max(z * 0.24, 5). Chosen because no rock overlaps its contact circle,
## so the walk and the spawn each prove one prop instead of a prop pocket.
## Boundary values: the fixture's own constants.
const TREE_CENTRE := Vector2(690.0, 548.0 + 34.0 * 0.88)
const TRUNK_RADIUS := 8.16

## Room to the left of the trunk's contact circle at which the player starts.
const START_GAP := 24.0
## Manual frame length: 11 px per step at the authored 220 px/s move speed.
const DELTA := 0.05
## Extra frames so the slide has time to skirt the trunk and its neighbouring
## rock in whichever direction the deterministic nudge picks.
const STEP_MARGIN := 20
## Half a pixel of slack on "outside the prop": resolve runs in passes.
const CONTACT_EPSILON := 0.5


## Safety net: a failed assertion mid-test must never leave a movement action
## held, or the next test walks on its own.
func after_test() -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")


func test_main_scene_shares_one_obstacle_field_with_enemy_manager() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)

	var manager := main.get_node_or_null("EnemyManager") as EnemyManager
	assert_object(manager).is_not_null()
	if manager == null:
		return

	# Act — the field main built in _ready().
	var field = main._obstacles

	# Assert
	assert_object(field).override_failure_message(
		"main builds the prop field in _ready()"
	).is_not_null()
	if field == null:
		return
	assert_object(manager.obstacles).override_failure_message(
		"the enemy manager resolves against the same field the player slides on"
	).is_same(field)
	assert_bool(field.is_empty()).override_failure_message(
		"the real arena has props"
	).is_false()


func test_main_scene_tree_trunk_blocks_the_player() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	# Deterministic: the test drives every frame itself.
	main.set_process(false)

	var player := main.get_node_or_null("Player") as Player
	assert_object(player).is_not_null()
	if player == null:
		return
	assert_object(player.stats).override_failure_message(
		"the player was set up from the class data"
	).is_not_null()
	if player.stats == null:
		return

	var speed := player.stats.effective_move_speed()
	assert_float(speed).override_failure_message(
		"the player has a positive move speed"
	).is_greater(0.0)
	if speed <= 0.0:
		return

	var clearance := TRUNK_RADIUS + Player.RADIUS
	var start := TREE_CENTRE + Vector2(-(clearance + START_GAP), 0.0)
	player.position = start
	var steps := ceili((clearance + START_GAP) * 2.0 / (speed * DELTA)) + STEP_MARGIN

	# Act — hold right and call the real frame function by hand.
	var closest := player.position.distance_to(TREE_CENTRE)
	Input.action_press("move_right")
	for _i in steps:
		main._process(DELTA)
		closest = minf(closest, player.position.distance_to(TREE_CENTRE))
	Input.action_release("move_right")

	# Assert — outside the trunk on every frame, and it really walked into it.
	assert_float(player.position.distance_to(start)).override_failure_message(
		"the player moved from its start"
	).is_greater(CONTACT_EPSILON)
	assert_float(closest).override_failure_message(
		"no frame of the walk put the player inside the trunk"
	).is_greater(clearance - CONTACT_EPSILON)
	assert_float(player.position.distance_to(TREE_CENTRE)).override_failure_message(
		"the player never ends inside the trunk"
	).is_greater(clearance - CONTACT_EPSILON)


func test_enemy_spawned_inside_a_trunk_is_resolved_outside() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)

	var manager := main.get_node_or_null("EnemyManager") as EnemyManager
	assert_object(manager).is_not_null()
	if manager == null:
		return
	var skeleton := load(SKELETON_PATH) as EnemyData
	assert_object(skeleton).override_failure_message(
		"squelette.tres loads as EnemyData"
	).is_not_null()
	if skeleton == null:
		return
	# The container owns the spawned node; auto_free frees it after the test.
	var container: Node2D = auto_free(Node2D.new())

	# Act — the spawn point is the trunk's centre.
	var enemy := manager.spawn(skeleton, TREE_CENTRE, container)

	# Assert
	assert_object(enemy).is_not_null()
	if enemy == null:
		return
	var clearance := TRUNK_RADIUS + enemy.radius
	assert_float(enemy.position.distance_to(TREE_CENTRE)).override_failure_message(
		"the spawned enemy is pushed clear of the trunk"
	).is_greater(clearance - CONTACT_EPSILON)
