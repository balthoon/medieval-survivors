## Throwaway drawing helpers for the three visual-direction mockups.
##
## Nothing in this file runs unless [VisualPilot] selects a pilot direction.
## The helpers are deliberately small and procedural, like the real art: soft
## vertex-coloured gradients, directional shading bands, hatching and paper
## speckle. There are no textures and no shaders, so the mockup can be deleted
## without leaving an asset behind.
extends RefCounted

## Direction the light comes from everywhere in the pilots. Top-left, like the
## locked art bible.
const LIGHT_DIR := Vector2(-0.7071, -0.7071)


## A polygon approximation of an ellipse.
static func ellipse_points(
	at: Vector2, rx: float, ry: float, segments: int = 28
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(at + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


## Average of a polygon's points. Used as the origin of shading bands.
static func centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())


## Pushes every point away from the polygon centre, making an even rim for the
## star-shaped volumes this game draws.
static func inflate(points: PackedVector2Array, width: float) -> PackedVector2Array:
	if points.is_empty():
		return points
	var centre := centroid(points)
	var out := PackedVector2Array()
	for point in points:
		var offset := point - centre
		if offset.length_squared() < 0.0001:
			out.append(point)
		else:
			out.append(point + offset.normalized() * width)
	return out


## The signed area of a polygon; the sign follows the winding.
static func polygon_area(points: PackedVector2Array) -> float:
	var total := 0.0
	var count := points.size()
	for index in count:
		var here := points[index]
		var next := points[(index + 1) % count]
		total += here.x * next.y - next.x * here.y
	return total * 0.5


## A radial gradient with no hard rim: the centre keeps [param colour], every
## edge point fades to zero alpha. Cheap enough to use for shadows, fogs and
## light pools, and it never shows the faceting of a plain drawn circle.
static func soft_blob(
	item: CanvasItem, at: Vector2, rx: float, ry: float, colour: Color,
	segments: int = 24
) -> void:
	if colour.a <= 0.0:
		return
	var clear := Color(colour.r, colour.g, colour.b, 0.0)
	for index in segments:
		var angle_a := TAU * float(index) / float(segments)
		var angle_b := TAU * float(index + 1) / float(segments)
		var point_a := at + Vector2(cos(angle_a) * rx, sin(angle_a) * ry)
		var point_b := at + Vector2(cos(angle_b) * rx, sin(angle_b) * ry)
		item.draw_polygon(
			PackedVector2Array([at, point_a, point_b]),
			PackedColorArray([colour, clear, clear])
		)


## A rectangle filled with a gradient from [param colour] on the outside to
## transparent on the inside. [param side] is one of "top", "bottom", "left",
## "right"; four calls make a vignette.
static func edge_gradient(
	item: CanvasItem, rect: Rect2, thickness: float, colour: Color, side: String
) -> void:
	var clear := Color(colour.r, colour.g, colour.b, 0.0)
	var points := PackedVector2Array()
	var colours := PackedColorArray()
	match side:
		"top":
			points = PackedVector2Array([
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.end.x, rect.position.y + thickness),
				Vector2(rect.position.x, rect.position.y + thickness),
			])
			colours = PackedColorArray([colour, colour, clear, clear])
		"bottom":
			points = PackedVector2Array([
				Vector2(rect.position.x, rect.end.y),
				Vector2(rect.end.x, rect.end.y),
				Vector2(rect.end.x, rect.end.y - thickness),
				Vector2(rect.position.x, rect.end.y - thickness),
			])
			colours = PackedColorArray([colour, colour, clear, clear])
		"left":
			points = PackedVector2Array([
				rect.position,
				Vector2(rect.position.x, rect.end.y),
				Vector2(rect.position.x + thickness, rect.end.y),
				Vector2(rect.position.x + thickness, rect.position.y),
			])
			colours = PackedColorArray([colour, colour, clear, clear])
		"right":
			points = PackedVector2Array([
				Vector2(rect.end.x, rect.position.y),
				rect.end,
				Vector2(rect.end.x - thickness, rect.end.y),
				Vector2(rect.end.x - thickness, rect.position.y),
			])
			colours = PackedColorArray([colour, colour, clear, clear])
		_:
			return
	item.draw_polygon(points, colours)


## Four-sided vignette. The centre is untouched, each edge fades in.
static func vignette(
	item: CanvasItem, rect: Rect2, thickness: float, colour: Color
) -> void:
	edge_gradient(item, rect, thickness, colour, "top")
	edge_gradient(item, rect, thickness, colour, "bottom")
	edge_gradient(item, rect, thickness, colour, "left")
	edge_gradient(item, rect, thickness, colour, "right")


## A band of shading along every edge facing away from (or into) the light.
## [param light] true paints the upper-left edges, false the lower-right ones.
## The band stays inside the polygon, so the ink rim is never covered.
static func edge_band(
	item: CanvasItem, points: PackedVector2Array, colour: Color,
	light: bool, inset: float = 0.62
) -> void:
	if points.size() < 3:
		return
	var centre := centroid(points)
	var count := points.size()
	for index in count:
		var point_a := points[index]
		var point_b := points[(index + 1) % count]
		var middle := (point_a + point_b) * 0.5
		var facing := (middle - centre).normalized().dot(LIGHT_DIR)
		if (light and facing > 0.10) or (not light and facing < -0.10):
			var inner_a := centre.lerp(point_a, inset)
			var inner_b := centre.lerp(point_b, inset)
			item.draw_colored_polygon(
				PackedVector2Array([point_a, point_b, inner_b, inner_a]), colour
			)


## Three-tone volume: fill, shadow band on the lower-right, light band on the
## upper-left. The caller draws the ink rim itself, so it can choose its weight.
static func volume(
	item: CanvasItem, points: PackedVector2Array, base: Color,
	light: Color, shade: Color, inset: float = 0.62
) -> void:
	item.draw_colored_polygon(points, base)
	edge_band(item, points, shade, false, inset)
	edge_band(item, points, light, true, inset)


## A rim highlight along the upper-left edges only. Drawn after the body and
## its ink rim, which is what makes a dark silhouette read as lit from outside.
static func rim(
	item: CanvasItem, points: PackedVector2Array, colour: Color,
	width: float = 1.2, light_dir: Vector2 = LIGHT_DIR
) -> void:
	if points.size() < 2:
		return
	var centre := centroid(points)
	var count := points.size()
	for index in count:
		var point_a := points[index]
		var point_b := points[(index + 1) % count]
		var middle := (point_a + point_b) * 0.5
		if (middle - centre).normalized().dot(light_dir) > 0.18:
			item.draw_line(point_a, point_b, colour, width, true)


## Parallel hatching clipped analytically to an ellipse. Used on skulls, torsos
## and canopies, where the shape is round enough for the closed form.
static func hatch_ellipse(
	item: CanvasItem, at: Vector2, rx: float, ry: float,
	spacing: float, angle: float, colour: Color, width: float = 0.8
) -> void:
	if rx <= 0.0 or ry <= 0.0 or spacing <= 0.0:
		return
	var direction := Vector2.RIGHT.rotated(angle)
	var normal := Vector2(-direction.y, direction.x)
	var support := sqrt(
		(rx * normal.x) * (rx * normal.x) + (ry * normal.y) * (ry * normal.y)
	)
	var quadratic_a := (
		(direction.x / rx) * (direction.x / rx)
		+ (direction.y / ry) * (direction.y / ry)
	)
	var offset := -support
	while offset <= support:
		var quadratic_b := 2.0 * offset * (
			(normal.x * direction.x) / (rx * rx)
			+ (normal.y * direction.y) / (ry * ry)
		)
		var quadratic_c := offset * offset * (
			(normal.x / rx) * (normal.x / rx)
			+ (normal.y / ry) * (normal.y / ry)
		) - 1.0
		var discriminant := quadratic_b * quadratic_b - 4.0 * quadratic_a * quadratic_c
		if discriminant > 0.0:
			var root := sqrt(discriminant)
			var t0 := (-quadratic_b - root) / (2.0 * quadratic_a)
			var t1 := (-quadratic_b + root) / (2.0 * quadratic_a)
			var base := at + normal * offset
			item.draw_line(base + direction * t0, base + direction * t1, colour, width, true)
		offset += spacing


## Parallel hatching clipped to an arbitrary polygon by sampling. The step is
## small enough that the runs stay visually continuous at this game's scale.
static func hatch_polygon(
	item: CanvasItem, points: PackedVector2Array,
	spacing: float, angle: float, colour: Color, width: float = 0.8
) -> void:
	if points.size() < 3 or spacing <= 0.0:
		return
	var direction := Vector2.RIGHT.rotated(angle)
	var normal := Vector2(-direction.y, direction.x)
	var min_normal := INF
	var max_normal := -INF
	var min_along := INF
	var max_along := -INF
	for point in points:
		var on_normal := point.dot(normal)
		var on_direction := point.dot(direction)
		min_normal = minf(min_normal, on_normal)
		max_normal = maxf(max_normal, on_normal)
		min_along = minf(min_along, on_direction)
		max_along = maxf(max_along, on_direction)

	var offset := min_normal
	while offset <= max_normal:
		var run_start := NAN
		var along := min_along
		while along <= max_along:
			var at := normal * offset + direction * along
			var inside := Geometry2D.is_point_in_polygon(at, points)
			if inside and is_nan(run_start):
				run_start = along
			elif not inside and not is_nan(run_start):
				item.draw_line(
					normal * offset + direction * run_start,
					normal * offset + direction * (along - 2.0),
					colour, width, true
				)
				run_start = NAN
			along += 2.0
		if not is_nan(run_start):
			item.draw_line(
				normal * offset + direction * run_start,
				normal * offset + direction * max_along,
				colour, width, true
			)
		offset += spacing


## A soft ground shadow: a wide fade plus a darker contact core.
static func ground_shadow(
	item: CanvasItem, at: Vector2, radius: float, colour: Color,
	offset: Vector2 = Vector2(4.0, 6.0), squash: float = 0.42
) -> void:
	soft_blob(item, at + offset, radius * 1.25, radius * squash * 1.25, colour)
	var core := Color(colour.r, colour.g, colour.b, colour.a * 0.8)
	soft_blob(item, at + offset * 0.35, radius * 0.78, radius * squash * 0.78, core)


## A long directional cast shadow, useful under trees and the boss. The body
## polygon is re-used so the shadow keeps the silhouette.
static func cast_shadow(
	item: CanvasItem, points: PackedVector2Array, colour: Color,
	offset: Vector2
) -> void:
	var moved := PackedVector2Array()
	for point in points:
		moved.append(point + offset)
	item.draw_colored_polygon(moved, colour)


## A deterministic speckle field. [param rng] is the caller's seeded generator,
## so the arena never changes between launches.
static func speckle(
	item: CanvasItem, rect: Rect2, rng: RandomNumberGenerator,
	count: int, colours: Array[Color], min_side: float = 1.0, max_side: float = 2.0
) -> void:
	if colours.is_empty():
		return
	for _index in count:
		var at := Vector2(
			rng.randf_range(rect.position.x, rect.end.x),
			rng.randf_range(rect.position.y, rect.end.y)
		)
		var side := rng.randf_range(min_side, max_side)
		var colour: Color = colours[rng.randi_range(0, colours.size() - 1)]
		item.draw_rect(Rect2(at, Vector2(side, side)), colour)


## A short curved grass blade drawn as three stacked triangles, so it has a
## base, a belly and a tip instead of being one flat wedge.
static func grass_blade(
	item: CanvasItem, base: Vector2, height: float, lean: float,
	width: float, colour: Color
) -> void:
	var tip := base + Vector2(sin(lean) * height * 0.75, -cos(lean) * height)
	var middle := base.lerp(tip, 0.5) + Vector2(cos(lean) * width * 0.7, 0.0)
	var half := Vector2(cos(lean), sin(lean)) * width * 0.5
	item.draw_colored_polygon(
		PackedVector2Array([base - half, base + half, middle, tip]), colour
	)


## The inner negative-space line of a woodcut: a paper-coloured stroke that
## suggests a cut in the block rather than a highlight painted on top.
static func cut_line(
	item: CanvasItem, from: Vector2, to: Vector2, colour: Color,
	width: float = 1.0
) -> void:
	item.draw_line(from, to, colour, width, true)


## A soft irregular blob polygon, the same idea as ArenaDecor._blob. Kept here
## so the pilot arenas do not depend on the real decor's private helpers.
static func blob(
	centre: Vector2, radii: Vector2, count: int, rng: RandomNumberGenerator,
	jitter: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var start := rng.randf_range(0.0, TAU)
	for index in count:
		var angle := start + TAU * float(index) / float(count)
		var scale := 1.0 + rng.randf_range(-jitter, jitter)
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * scale)
	return points


## Short parallel ticks along a line, used for woodcut ground and tree bark.
static func tick_line(
	item: CanvasItem, from: Vector2, to: Vector2, count: int,
	length: float, colour: Color, width: float = 1.0
) -> void:
	if count <= 0:
		return
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	for index in count:
		var at := from.lerp(to, (float(index) + 0.5) / float(count))
		item.draw_line(at - normal * length * 0.5, at + normal * length * 0.5, colour, width, true)
