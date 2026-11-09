## An XP gem dropped by a dead enemy. It drifts toward the player once close.
class_name XpPickup extends Node2D

## XP granted when collected.
var value: int = 1

## Distance at which the gem starts magnetising toward the target.
const MAGNET_RADIUS := 140.0
## Collection distance.
const RADIUS := 8.0

## Ink rim drawn around the gem, in pixels. Gold on grass is low contrast, so the
## rim and the diamond shape are what keep the gem readable.
const RIM_WIDTH := 1.5

## Colour of the rim.
const RIM_COLOR := Color(0.16, 0.14, 0.12)

## Travel speed while magnetised, in pixels per second.
const _MAGNET_SPEED := 480.0

## Builds a pickup gem. Returns it unattached.
static func create(xp_value: int, at: Vector2) -> XpPickup:
	var pickup := XpPickup.new()
	pickup.value = xp_value
	pickup.position = at
	var rim := Polygon2D.new()
	rim.polygon = _diamond(RADIUS + RIM_WIDTH)
	rim.color = RIM_COLOR
	pickup.add_child(rim)

	var visual := Polygon2D.new()
	visual.polygon = _diamond(RADIUS)
	visual.color = Color(0.85, 0.65, 0.15)
	pickup.add_child(visual)
	return pickup


## Builds the diamond outline of the gem at the given radius.
static func _diamond(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
	])

## Magnets toward the target when inside MAGNET_RADIUS.
func step_toward(target: Vector2, delta: float) -> void:
	var offset := target - position
	var distance := offset.length()
	if distance <= 0.0 or distance > MAGNET_RADIUS:
		return
	var travel := minf(_MAGNET_SPEED * delta, distance)
	position += offset / distance * travel

## True when the target is close enough to collect.
func collected_by(target: Vector2) -> bool:
	return position.distance_squared_to(target) <= RADIUS * RADIUS
