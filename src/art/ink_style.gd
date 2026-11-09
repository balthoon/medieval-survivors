## Drawing primitives shared by every actor, so the whole game is drawn in one
## hand: the same ink, the same three-tone shading, the same ground shadow.
##
## See `design/art/art-bible.md`. Nothing here knows about gameplay: these are
## shapes and colours only, and every helper takes the [CanvasItem] to paint on
## so an actor calls them from inside its own [method CanvasItem._draw].
##
## All randomness is avoided: a drawing that changes between two calls would
## make a hit flash flicker for reasons the player cannot read.
class_name InkStyle
extends RefCounted

## The only outline colour in the game. Never pure black — pure black reads as a
## hole on the grass, and this warm brown-grey reads as ink.
const INK := Color(0.16, 0.14, 0.12)

## Interior detail lines (ribs, folds, visor slits): the same ink, held back so a
## creature is not a mass of black strokes.
const INK_SOFT := Color(0.16, 0.14, 0.12, 0.55)

## Weight of every outline, in pixels at 1x. The art bible fixes it: a boss gets
## the same ink as a skeleton.
const OUTLINE := 2.0

## Weight of interior detail lines.
const DETAIL := 1.0

## Alpha of the ground shadow under an actor. Low enough that two overlapping
## shadows do not turn the grass black.
const SHADOW_ALPHA := 0.13


## Light tone of a colour. Light comes from the top-left everywhere in the game,
## so this is what the upper-left third of every volume is painted with.
static func light_of(base: Color, amount: float = 0.22) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), amount)


## Dark tone of a colour. Darkening toward ink rather than black keeps the shadow
## in the same warm family as the outline it touches.
static func dark_of(base: Color, amount: float = 0.26) -> Color:
	return base.lerp(INK, amount)


## A point list for an ellipse, as a polygon. Used for heads, shoulders and the
## ground shadows, which are never plain circles.
static func ellipse_points(
	at: Vector2, rx: float, ry: float, segments: int = 26
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(at + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


## The ground shadow under an actor: a squashed ellipse, never a circle, so the
## body above it reads as standing rather than lying down.
static func shadow(
	item: CanvasItem, at: Vector2, radius: float, squash: float = 0.40,
	alpha: float = SHADOW_ALPHA
) -> void:
	item.draw_colored_polygon(
		ellipse_points(at, radius, radius * squash),
		Color(INK.r, INK.g, INK.b, alpha)
	)


## Pushes every point away from the polygon's centre by [param width]. The
## result is an even rim for a star-shaped polygon, which is every volume this
## game draws.
static func inflate(points: PackedVector2Array, width: float) -> PackedVector2Array:
	if points.is_empty():
		return points
	var centre := Vector2.ZERO
	for point in points:
		centre += point
	centre /= float(points.size())

	var out := PackedVector2Array()
	for point in points:
		var offset := point - centre
		if offset.length_squared() < 0.0001:
			out.append(point)
		else:
			out.append(point + offset.normalized() * width)
	return out


## A filled polygon with a single ink rim. This is the workhorse: every body
## volume in the game is one of these.
static func outlined(
	item: CanvasItem, points: PackedVector2Array, body: Color,
	width: float = OUTLINE
) -> void:
	item.draw_colored_polygon(inflate(points, width), INK)
	item.draw_colored_polygon(points, body)


## A circle with an ink rim.
static func circle(
	item: CanvasItem, at: Vector2, radius: float, body: Color,
	width: float = OUTLINE
) -> void:
	outlined(item, ellipse_points(at, radius, radius), body, width)


## An ellipse with an ink rim, for shoulders, skulls and capsules.
static func ellipse(
	item: CanvasItem, at: Vector2, rx: float, ry: float, body: Color,
	width: float = OUTLINE
) -> void:
	outlined(item, ellipse_points(at, rx, ry), body, width)


## An ink rim plus a light-then-base two-tone volume: the light tone on the
## upper-left third, the base everywhere else. Pass a polygon already shaped.
static func shaded(
	item: CanvasItem, points: PackedVector2Array, base: Color,
	width: float = OUTLINE
) -> void:
	outlined(item, points, base, width)
	var light := light_of(base)
	var centre := Vector2.ZERO
	for point in points:
		centre += point
	centre /= float(points.size())
	var highlight := PackedVector2Array()
	for point in points:
		var relative := point - centre
		# Only the points on the upper-left half take the light tone, so the
		# highlight has a hard edge instead of a gradient.
		if relative.x <= 0.0 and relative.y <= 0.0:
			highlight.append(point)
		else:
			highlight.append(centre.lerp(point, 0.55))
	if highlight.size() >= 3:
		item.draw_colored_polygon(highlight, light)


## A thin ink detail line inside a volume, e.g. a rib or a visor slit.
static func detail(
	item: CanvasItem, from: Vector2, to: Vector2, width: float = DETAIL,
	colour: Color = INK_SOFT
) -> void:
	item.draw_line(from, to, colour, width, true)


## A soft glow behind an accent, used for the boss's eyes and the gem's fleck.
static func glow(
	item: CanvasItem, at: Vector2, radius: float, colour: Color
) -> void:
	item.draw_circle(at, radius, Color(colour.r, colour.g, colour.b, 0.22))
	item.draw_circle(at, radius * 0.55, colour)


## Vertical offset of a breathing actor. Returns zero at [param t] = 0 so a
## capture taken at t = 0 is the neutral pose.
static func breathe(t: float, amount: float = 1.0, hz: float = 1.6) -> float:
	return -absf(sin(t * TAU * hz)) * amount
