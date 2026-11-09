## The drawn half of one melee weapon: a blade or a hammer on a pivot, plus the
## fading ink fan showing the arc that was actually struck.
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

	var colour := INK
	if weapon != null:
		colour = weapon.color

	if weapon != null and weapon.shape == "hammer":
		_build_hammer(_pivot, colour)
	else:
		_build_blade(_pivot, colour)


## Long tapered blade, scaled to the drawn reach.
func _build_blade(pivot: Node2D, colour: Color) -> void:
	var reach := _draw_reach
	var outline := Polygon2D.new()
	outline.polygon = PackedVector2Array([
		Vector2(reach * 0.22, -3.0),
		Vector2(reach * 0.94, -2.2),
		Vector2(reach, 0.0),
		Vector2(reach * 0.94, 2.2),
		Vector2(reach * 0.22, 3.0),
	])
	outline.color = INK
	pivot.add_child(outline)

	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([
		Vector2(reach * 0.24, -2.2),
		Vector2(reach * 0.94, -1.4),
		Vector2(reach * 0.97, 0.0),
		Vector2(reach * 0.94, 1.4),
		Vector2(reach * 0.24, 2.2),
	])
	blade.color = colour
	pivot.add_child(blade)


## Short handle with a heavy head at the end, scaled to the drawn reach.
func _build_hammer(pivot: Node2D, colour: Color) -> void:
	var reach := _draw_reach
	var head_start := maxf(reach - 18.0, reach * 0.6)

	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(reach * 0.18, -2.0),
		Vector2(head_start, -2.0),
		Vector2(head_start, 2.0),
		Vector2(reach * 0.18, 2.0),
	])
	shaft.color = INK
	pivot.add_child(shaft)

	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(head_start, -8.0),
		Vector2(reach, -8.0),
		Vector2(reach + 3.0, 0.0),
		Vector2(reach, 8.0),
		Vector2(head_start, 8.0),
	])
	head.color = colour
	pivot.add_child(head)


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
