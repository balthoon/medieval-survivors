## The drawn half of one melee weapon: a blade or a hammer on a pivot, plus the
## fading ink fan showing the arc that was actually struck.
##
## The weapon itself is drawn in the same hand as the actors — ink rim, three
## tones, light from the top-left — see `design/art/art-bible.md`. It is drawn
## in local space pointing along +x, so the pivot's rotation aims it.
##
## One view per equipped melee weapon, added as a child of the player node. It
## never reads game state: WeaponSystem tells it where to point and when to swing.
class_name WeaponView
extends Node2D

## Seconds a swing lasts when no weapon is set, used as a fallback.
const DEFAULT_SWING_DURATION := 0.12

## Alpha of the ink trail at the instant the swing starts.
const TRAIL_ALPHA := 0.28

## Colour of the outline and of the swing trail.
const INK := Color(0.16, 0.14, 0.12)

## Shortest reach the drawn weapon is squashed to, so a dagger stays readable.
const MIN_DRAW_REACH := 28.0

## Weapon this view draws. Set by setup().
var weapon: WeaponData = null

## Pivot carrying the weapon head; rotated to the facing or swept during a swing.
var _pivot: Node2D = null
## Translucent fan showing the cone actually struck.
var _trail: Polygon2D = null
## Seconds left in the current swing, zero when idle.
var _swing_time: float = 0.0
## Direction the current swing is centred on, locked at start_swing().
var _swing_center: float = 0.0
## Full width of the current swing, in radians.
var _swing_arc: float = 0.0
## Direction the weapon points when idle.
var _facing: float = 0.0
## Reach the weapon is drawn at, in pixels.
var _draw_reach: float = MIN_DRAW_REACH
## Seconds the current weapon's swing lasts.
var _swing_duration: float = DEFAULT_SWING_DURATION


## Builds the visual for one weapon. Reach is the weapon's current range in
## pixels, used to scale the drawn head. The swing duration comes from the
## weapon, so a hammer winds up slower than a dagger.
func setup(draw_weapon: WeaponData, reach: float) -> void:
	weapon = draw_weapon
	if draw_weapon != null:
		_swing_duration = maxf(draw_weapon.swing_duration, 0.01)
	else:
		_swing_duration = DEFAULT_SWING_DURATION
	_draw_reach = maxf(reach, MIN_DRAW_REACH)
	_build()


## Points the weapon, used when no swing is running.
func set_facing(angle: float) -> void:
	_facing = angle


## Starts a swing centred on [param angle]. The sweep is animated by step().
func start_swing(angle: float) -> void:
	_swing_time = _swing_duration
	_swing_center = angle
	var arc := 120.0
	if weapon != null:
		arc = weapon.arc_degrees
	_swing_arc = deg_to_rad(arc)


## Advances the sweep and the fading trail. Parks the weapon on the facing when
## no swing is running.
func step(delta: float) -> void:
	if _pivot == null:
		return

	if _swing_time <= 0.0:
		_pivot.rotation = _facing
		if _trail != null:
			_trail.visible = false
		return

	_swing_time = maxf(_swing_time - delta, 0.0)
	var progress := 1.0 - _swing_time / _swing_duration
	# Smoothstep, so the weapon accelerates into the cut and settles at the end.
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var half := _swing_arc * 0.5
	var from_angle := _swing_center - half
	var to_angle := _swing_center + half
	var current := lerpf(from_angle, to_angle, eased)

	_pivot.rotation = current
	_update_trail(from_angle, current, TRAIL_ALPHA * (1.0 - progress))
	if _trail != null:
		_trail.visible = true


## Builds the trail and the weapon head, once. The trail is added first so it
## draws behind the weapon.
func _build() -> void:
	_trail = Polygon2D.new()
	_trail.visible = false
	_trail.color = Color(INK.r, INK.g, INK.b, TRAIL_ALPHA)
	add_child(_trail)

	_pivot = Node2D.new()
	add_child(_pivot)

	var head := Head.new()
	head.reach = _draw_reach
	head.colour = weapon.color if weapon != null else INK
	head.shape = weapon.shape if weapon != null else "blade"
	_pivot.add_child(head)


## One melee weapon, drawn in ink and pointing along +x.
##
## A node of its own rather than a pile of [Polygon2D]s: an ink rim, a highlight
## band and a detail line are strokes, not fills, and every actor in the game is
## built the same way. It reads nothing — [WeaponView] hands it its three values
## once in `setup()`.
class Head extends Node2D:
	## "blade" or "hammer", from [member WeaponData.shape].
	var shape: String = "blade"
	## Distance from the pivot to the end of the weapon, in pixels.
	var reach: float = 48.0
	## The weapon's own colour: the blade's steel, or the hammer's head.
	var colour: Color = Color(0.72, 0.74, 0.78)

	func _draw() -> void:
		if shape == "hammer":
			_draw_hammer()
		else:
			_draw_blade()


	## An axis-aligned rectangle from [param x0] to [param x1], [param half] tall.
	static func _rect(x0: float, x1: float, half: float) -> PackedVector2Array:
		return PackedVector2Array([
			Vector2(x0, -half), Vector2(x1, -half), Vector2(x1, half), Vector2(x0, half),
		])


	## A tapered blade with a grip, a crossguard and a fuller down the middle.
	## The guard is the one perpendicular stroke on the whole weapon: without it
	## a blade is a stick, however well it is tapered.
	func _draw_blade() -> void:
		var r := reach
		var leather := InkStyle.dark_of(ActorArt.WOOD, 0.28)
		InkStyle.outlined(self, _rect(0.10 * r, 0.26 * r, 1.7), leather, 1.2)

		var guard_half := clampf(0.10 * r, 3.2, 6.0)
		InkStyle.outlined(
			self, _rect(0.24 * r, 0.30 * r, guard_half), InkStyle.dark_of(colour, 0.20), 1.4
		)

		var blade := PackedVector2Array([
			Vector2(0.28 * r, -2.6),
			Vector2(0.86 * r, -2.0),
			Vector2(r, 0.0),
			Vector2(0.86 * r, 2.0),
			Vector2(0.28 * r, 2.6),
		])
		InkStyle.outlined(self, blade, colour, 1.6)

		# Light along the upper edge, shade along the lower one, ink fuller
		# between them: three tones on a 5 px blade, which is all it takes.
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.29 * r, -2.0),
			Vector2(0.87 * r, -1.4),
			Vector2(r - 1.6, 0.0),
			Vector2(0.87 * r, -0.3),
			Vector2(0.29 * r, -0.6),
		]), InkStyle.light_of(colour, 0.34))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.29 * r, 2.0),
			Vector2(0.87 * r, 1.4),
			Vector2(r - 1.6, 0.0),
			Vector2(0.87 * r, 0.3),
			Vector2(0.29 * r, 0.6),
		]), InkStyle.dark_of(colour, 0.24))
		InkStyle.detail(self, Vector2(0.36 * r, 0.0), Vector2(0.80 * r, 0.0), 1.0)


	## A wooden shaft under a heavy block of a head, with a steel band where the
	## two meet and a lit top face on the block.
	func _draw_hammer() -> void:
		var r := reach
		var head_start := maxf(r - 20.0, r * 0.62)

		InkStyle.outlined(self, _rect(0.08 * r, head_start + 2.0, 1.9), ActorArt.WOOD, 1.4)
		InkStyle.detail(
			self, Vector2(head_start - 4.0, -1.9), Vector2(head_start - 4.0, 1.9), 1.2,
			InkStyle.INK
		)

		var head := PackedVector2Array([
			Vector2(head_start, -7.0),
			Vector2(r + 1.0, -8.0),
			Vector2(r + 4.0, 0.0),
			Vector2(r + 1.0, 8.0),
			Vector2(head_start, 7.0),
		])
		InkStyle.outlined(self, head, colour, 2.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(head_start + 1.0, -6.0),
			Vector2(r + 1.0, -6.8),
			Vector2(r + 2.8, -0.4),
			Vector2(head_start + 1.0, -0.4),
		]), InkStyle.light_of(colour, 0.22))
		InkStyle.detail(
			self, Vector2(head_start + 1.0, 1.2), Vector2(r + 2.6, 1.2), 1.0
		)


## Replaces the trail polygon with a fan swept between two angles.
func _update_trail(from_angle: float, to_angle: float, alpha: float) -> void:
	if _trail == null:
		return
	var steps := 10
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for index in range(steps + 1):
		var angle := lerpf(from_angle, to_angle, float(index) / float(steps))
		points.append(Vector2.RIGHT.rotated(angle) * _draw_reach)
	_trail.polygon = points
	_trail.color = Color(INK.r, INK.g, INK.b, maxf(alpha, 0.0))
