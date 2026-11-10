## Static props the player and enemies walk around, resolved with distance math.
##
## The game has no physics server and no bodies: actors are plain Node2D nodes
## moved by direct position math. This field is a pure, deterministic helper that
## knows nothing about nodes, so its behaviour is testable without a scene tree
## and identical in every replay of the same inputs. Circles store (x, y, radius);
## rects are axis-aligned.
class_name ObstacleField extends RefCounted

## Resolve passes per call. Two neighbouring props can push a body from one into
## the other; the extra passes let a corner settle instead of leaving the body
## inside a prop.
const RESOLVE_PASSES := 3

## Lengths below this count as zero, so the deterministic fallbacks run instead
## of normalising float noise.
const ZERO_LENGTH := 0.0001

## A tangential part smaller than this fraction of the full step counts as a
## head-on hit. Without the lateral nudge, an enemy steering straight at the
## player would stall behind a trunk instead of skirting it.
const DEAD_ON_FRACTION := 0.01

## Solid circles: x and y are the centre, z is the radius.
var circles: Array[Vector3] = []
## Solid axis-aligned rectangles.
var rects: Array[Rect2] = []


## Adds a circular obstacle. Zero and negative radii are ignored.
func add_circle(at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	circles.append(Vector3(at.x, at.y, radius))


## Adds a rectangular obstacle. Rectangles with no area are ignored; a
## negative-size rect counts as empty, so callers pass Rect2.abs() when needed.
func add_rect(rect: Rect2) -> void:
	if not rect.has_area():
		return
	rects.append(rect)


## True when no obstacle has been added.
func is_empty() -> bool:
	return circles.is_empty() and rects.is_empty()


## Pushes the centre of a circular body out of every obstacle it overlaps and
## returns the resolved point. A point that overlaps nothing is returned as is.
## [param body_radius] is the moving body's own radius.
func resolve(point: Vector2, body_radius: float) -> Vector2:
	for _pass in RESOLVE_PASSES:
		for circle in circles:
			point = _resolve_circle(point, circle, body_radius)
		for rect in rects:
			point = _resolve_rect(point, rect, body_radius)
	return point


## Slides a circular body from [param from] to [param to] instead of sticking to
## a prop. When [param to] overlaps nothing, it is returned unchanged; otherwise
## only the motion's tangential part is kept, so the body travels along the prop.
## A dead-on step is nudged sideways deterministically, which lets enemies skirt
## a trunk rather than stall behind it. [param body_radius] is the body's radius.
func slide(from: Vector2, to: Vector2, body_radius: float) -> Vector2:
	var resolved := resolve(to, body_radius)
	if resolved.is_equal_approx(to):
		return resolved

	var motion := to - from
	# Outward from the prop: the correction resolve() had to apply to the target.
	var normal := (resolved - to).normalized()
	var tangential := motion - normal * motion.dot(normal)
	if tangential.length_squared() <= motion.length_squared() * DEAD_ON_FRACTION * DEAD_ON_FRACTION:
		tangential = normal.orthogonal() * motion.length() * 0.5
	return resolve(from + tangential, body_radius)


## Resolves a point against one circle and returns the new point. Overlap is
## measured centre to centre against the sum of the radii.
func _resolve_circle(point: Vector2, circle: Vector3, body_radius: float) -> Vector2:
	var center := Vector2(circle.x, circle.y)
	var min_distance := circle.z + body_radius
	var offset := point - center
	var distance_sq := offset.length_squared()
	if distance_sq >= min_distance * min_distance:
		return point
	if distance_sq <= ZERO_LENGTH * ZERO_LENGTH:
		# The body's centre sits on the circle's centre: push along +X so the
		# result depends on no float noise and no random source.
		return center + Vector2(min_distance, 0.0)
	return center + offset.normalized() * min_distance


## Resolves a point against one rectangle and returns the new point. Outside the
## rect, the body is pushed away from its closest point; inside, it exits
## through the nearest face instead, which is the only way out of a solid area.
func _resolve_rect(point: Vector2, rect: Rect2, body_radius: float) -> Vector2:
	var closest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	var offset := point - closest
	var distance_sq := offset.length_squared()
	if distance_sq <= 0.0:
		return _exit_rect(point, rect, body_radius)
	if distance_sq >= body_radius * body_radius:
		return point
	return closest + offset.normalized() * body_radius


## Pushes a point that lies inside [param rect] out through the nearest face, at
## [param body_radius] beyond it, and returns the new point. Ties go left, right,
## top, then bottom, so the exit is deterministic.
func _exit_rect(point: Vector2, rect: Rect2, body_radius: float) -> Vector2:
	var to_left := point.x - rect.position.x
	var to_right := rect.end.x - point.x
	var to_top := point.y - rect.position.y
	var to_bottom := rect.end.y - point.y
	var nearest := minf(minf(to_left, to_right), minf(to_top, to_bottom))
	if is_equal_approx(nearest, to_left):
		point.x = rect.position.x - body_radius
	elif is_equal_approx(nearest, to_right):
		point.x = rect.end.x + body_radius
	elif is_equal_approx(nearest, to_top):
		point.y = rect.position.y - body_radius
	else:
		point.y = rect.end.y + body_radius
	return point
