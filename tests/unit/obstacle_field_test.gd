## Unit tests for the prop-collision field (lot 1).
##
## ObstacleField is pure math on a RefCounted, so every case builds its own
## field and touches no scene, no input and no filesystem. The factory checks at
## the end pin the props the field is built from: 9 tree trunks, 12 rocks and the
## shrine are circles, the fallen log is the only rectangle, and the bushes never
## block.
extends GdUnitTestSuite

const ObstacleFieldScript := preload("res://src/systems/obstacle_field.gd")
const PilotArenas := preload("res://src/art/pilot_arenas.gd")
const VisualPilot := preload("res://src/art/visual_pilot.gd")

const BODY_RADIUS := 10.0
const CIRCLE_RADIUS := 20.0
const CIRCLE_CENTRE := Vector2.ZERO
const FAR_CENTRE := Vector2(500.0, 500.0)

## How deep the body already sits inside the circle, and how far the test point
## sits from a rectangle's face. Boundary values: the point is the contact rule.
const OVERLAP_DEPTH := 5.0
const FACE_GAP := 3.0
const INSIDE_GAP := 5.0

const RECT := Rect2(0.0, 0.0, 100.0, 100.0)

## Free start/target pair for the untouched-slide case.
const FREE_START := Vector2.ZERO
const FREE_TARGET := Vector2(0.0, 50.0)

## Diagonal approach: outside the contact circle, aiming at its centre.
const DIAGONAL_START := Vector2(60.0, -40.0)
## Dead-on approach from directly to the right of the circle.
const HEAD_ON_START := Vector2(100.0, 0.0)

const GEOMETRY_EPSILON := 0.001
## Half a pixel of slack on "stays outside": the slide may resolve in passes.
const CONTACT_EPSILON := 0.5

## First tree trunk from PilotArenas.TREES: centre (x, y + z * 0.88), radius
## max(z * 0.24, 5) with z = 44. Boundary values: the fixture's own constants.
const ARENA_TREE_TRUNK_CENTRE := Vector2(140.0, 150.0 + 44.0 * 0.88)
const ARENA_TRUNK_RADIUS := 10.56
const ARENA_CIRCLE_COUNT := 22
const ARENA_RECT_COUNT := 1
const SHRINE_CIRCLE := Vector3(1168.0, 500.0, 16.0)
const FALLEN_LOG_RECT := Rect2(232.0, 564.0, 92.0, 20.0)


func test_empty_field_leaves_a_free_point_unchanged() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	var point := Vector2(100.0, 200.0)

	# Act
	var resolved: Vector2 = field.resolve(point, BODY_RADIUS)

	# Assert
	assert_vector(resolved).override_failure_message(
		"an empty field has nothing to push against"
	).is_equal_approx(point, Vector2(GEOMETRY_EPSILON, GEOMETRY_EPSILON))


func test_body_overlapping_circle_is_pushed_to_contact_distance() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_circle(CIRCLE_CENTRE, CIRCLE_RADIUS)
	var overlap_point := CIRCLE_CENTRE + Vector2(CIRCLE_RADIUS - OVERLAP_DEPTH, 0.0)

	# Act
	var resolved: Vector2 = field.resolve(overlap_point, BODY_RADIUS)

	# Assert — the centre sits radius + body_radius from the circle centre.
	assert_float(resolved.distance_to(CIRCLE_CENTRE)).override_failure_message(
		"the push lands exactly on the contact distance"
	).is_equal_approx(CIRCLE_RADIUS + BODY_RADIUS, GEOMETRY_EPSILON)
	assert_vector(resolved.normalized()).override_failure_message(
		"the push keeps the original direction"
	).is_equal_approx(Vector2.RIGHT, Vector2(GEOMETRY_EPSILON, GEOMETRY_EPSILON))


func test_body_at_circle_centre_is_pushed_out_by_radius_plus_body_radius() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_circle(CIRCLE_CENTRE, CIRCLE_RADIUS)

	# Act
	var resolved: Vector2 = field.resolve(CIRCLE_CENTRE, BODY_RADIUS)

	# Assert — only the distance is contractual; the escape angle is any.
	assert_float(resolved.distance_to(CIRCLE_CENTRE)).override_failure_message(
		"a body exactly on the centre is still pushed to the contact distance"
	).is_equal_approx(CIRCLE_RADIUS + BODY_RADIUS, GEOMETRY_EPSILON)


func test_body_near_rect_face_is_pushed_to_body_radius_from_it() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_rect(RECT)
	var outside_point := Vector2(RECT.end.x + FACE_GAP, RECT.get_center().y)

	# Act
	var resolved: Vector2 = field.resolve(outside_point, BODY_RADIUS)

	# Assert — pushed straight out of the face it overlaps.
	assert_float(resolved.x - RECT.end.x).override_failure_message(
		"the body sits body_radius from the face it was touching"
	).is_equal_approx(BODY_RADIUS, GEOMETRY_EPSILON)
	assert_float(resolved.y).override_failure_message(
		"the push does not slide along the face"
	).is_equal_approx(RECT.get_center().y, GEOMETRY_EPSILON)


func test_point_inside_rect_exits_through_nearest_face() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_rect(RECT)
	var inside_point := Vector2(RECT.end.x - INSIDE_GAP, RECT.get_center().y)

	# Act
	var resolved: Vector2 = field.resolve(inside_point, BODY_RADIUS)

	# Assert — the right face is the nearest one, body_radius beyond it.
	assert_float(resolved.x).override_failure_message(
		"the body exits the nearest face, body_radius beyond it"
	).is_equal_approx(RECT.end.x + BODY_RADIUS, GEOMETRY_EPSILON)
	assert_float(resolved.y).override_failure_message(
		"the exit keeps the point's y on the face"
	).is_equal_approx(RECT.get_center().y, GEOMETRY_EPSILON)


func test_slide_keeps_motion_that_is_already_free() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_circle(FAR_CENTRE, CIRCLE_RADIUS)

	# Act
	var resolved: Vector2 = field.slide(FREE_START, FREE_TARGET, BODY_RADIUS)

	# Assert
	assert_vector(resolved).override_failure_message(
		"an unobstructed slide reaches its target"
	).is_equal_approx(FREE_TARGET, Vector2(GEOMETRY_EPSILON, GEOMETRY_EPSILON))


func test_slide_deflects_diagonal_approach_along_circle() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_circle(CIRCLE_CENTRE, CIRCLE_RADIUS)

	# Act — the target is the circle centre, so the slide must deflect.
	var resolved: Vector2 = field.slide(DIAGONAL_START, CIRCLE_CENTRE, BODY_RADIUS)

	# Assert — outside the contact circle, with the tangential +y kept.
	assert_float(resolved.distance_to(CIRCLE_CENTRE)).override_failure_message(
		"the slid body stays outside the circle"
	).is_greater(CIRCLE_RADIUS + BODY_RADIUS - CONTACT_EPSILON)
	assert_float(resolved.y).override_failure_message(
		"the tangential part of the motion survives, so the body skirts the prop"
	).is_greater(DIAGONAL_START.y)


func test_slide_head_on_into_circle_moves_sideways() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()
	field.add_circle(CIRCLE_CENTRE, CIRCLE_RADIUS)

	# Act
	var resolved: Vector2 = field.slide(HEAD_ON_START, CIRCLE_CENTRE, BODY_RADIUS)

	# Assert — a dead-on approach is nudged off the approach line, not stopped.
	assert_float(resolved.distance_to(HEAD_ON_START)).override_failure_message(
		"the body does not simply stop at its start"
	).is_greater(GEOMETRY_EPSILON)
	assert_float(resolved.distance_to(CIRCLE_CENTRE)).override_failure_message(
		"the nudged body stays outside the circle"
	).is_greater(CIRCLE_RADIUS + BODY_RADIUS - CONTACT_EPSILON)
	assert_float(absf(resolved.y - HEAD_ON_START.y)).override_failure_message(
		"the nudge is sideways, perpendicular to the approach"
	).is_greater(GEOMETRY_EPSILON)


func test_adders_ignore_invalid_shapes() -> void:
	# Arrange
	var field = ObstacleFieldScript.new()

	# Act
	field.add_circle(CIRCLE_CENTRE, 0.0)
	field.add_circle(Vector2(50.0, 50.0), -CIRCLE_RADIUS)
	field.add_rect(Rect2(Vector2(10.0, 10.0), Vector2.ZERO))

	# Assert
	assert_bool(field.is_empty()).override_failure_message(
		"zero/negative radii and empty rects are not obstacles"
	).is_true()
	assert_int(field.circles.size()).is_equal(0)
	assert_int(field.rects.size()).is_equal(0)


func test_pilot_arenas_obstacle_field_matches_the_arena_props() -> void:
	# Act
	var field = PilotArenas.obstacle_field()

	# Assert — 9 tree trunks + 12 rocks + 1 shrine; bushes never block.
	assert_object(field).override_failure_message(
		"PilotArenas.obstacle_field() returns a field"
	).is_not_null()
	if field == null:
		return
	assert_int(field.circles.size()).override_failure_message(
		"9 tree trunks + 12 rocks + 1 shrine"
	).is_equal(ARENA_CIRCLE_COUNT)
	assert_int(field.rects.size()).override_failure_message(
		"the fallen log is the only rectangle"
	).is_equal(ARENA_RECT_COUNT)
	assert_bool(field.is_empty()).is_false()
	assert_bool(field.circles.has(SHRINE_CIRCLE)).override_failure_message(
		"the shrine blocks with a 16 px circle"
	).is_true()
	assert_bool(field.rects.has(FALLEN_LOG_RECT)).override_failure_message(
		"the fallen log sits where PilotArenas draws it"
	).is_true()

	# The first trunk: a body resolved from its centre comes out at contact.
	var resolved: Vector2 = field.resolve(ARENA_TREE_TRUNK_CENTRE, BODY_RADIUS)
	assert_float(resolved.distance_to(ARENA_TREE_TRUNK_CENTRE)).override_failure_message(
		"the first tree trunk resolves a body outside its radius"
	).is_greater(ARENA_TRUNK_RADIUS + BODY_RADIUS - CONTACT_EPSILON)


func test_visual_pilot_defaults_to_storybook_style() -> void:
	# Assert — main.gd builds the field through VisualPilot; the shipped default
	# must be the storybook arena, never the style-off passthrough.
	assert_int(VisualPilot.style).override_failure_message(
		"the default visual direction is STYLE_STORYBOOK (1)"
	).is_equal(VisualPilot.STYLE_STORYBOOK)


func test_visual_pilot_obstacle_field_matches_pilot_arenas() -> void:
	# Arrange — force the default direction, then restore whatever was active.
	var previous := VisualPilot.style
	VisualPilot.set_style(VisualPilot.STYLE_STORYBOOK)

	# Act
	var field = VisualPilot.obstacle_field()

	# Assert
	VisualPilot.set_style(previous)
	assert_object(field).override_failure_message(
		"VisualPilot.obstacle_field() delegates to PilotArenas"
	).is_not_null()
	if field == null:
		return
	assert_int(field.circles.size()).is_equal(ARENA_CIRCLE_COUNT)
	assert_int(field.rects.size()).is_equal(ARENA_RECT_COUNT)
