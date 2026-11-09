## An XP crystal dropped by a dead enemy. It drifts toward the player once close.
##
## Drawn as a faceted gem rather than a flat diamond: the ink rim and the two
## facets are what keep a gold speck readable on gold-ish grass — see
## `design/art/art-bible.md`.
class_name XpPickup extends Node2D

## XP granted when collected.
var value: int = 1

## Distance at which the gem starts magnetising toward the target.
const MAGNET_RADIUS := 140.0
## Collection distance.
const RADIUS := 8.0

## Travel speed while magnetised, in pixels per second.
const _MAGNET_SPEED := 480.0

## Seconds since the gem appeared, used only to turn the specular fleck.
var _anim_time: float = 0.0


## Builds a pickup gem. Returns it unattached.
static func create(xp_value: int, at: Vector2) -> XpPickup:
	var pickup := XpPickup.new()
	pickup.value = xp_value
	pickup.position = at
	return pickup


func _draw() -> void:
	ActorArt.draw_gem(self, RADIUS, _anim_time)


## Magnets toward the target when inside MAGNET_RADIUS.
func step_toward(target: Vector2, delta: float) -> void:
	_anim_time += delta
	queue_redraw()
	var offset := target - position
	var distance := offset.length()
	if distance <= 0.0 or distance > MAGNET_RADIUS:
		return
	var travel := minf(_MAGNET_SPEED * delta, distance)
	position += offset / distance * travel


## True when the target is close enough to collect.
func collected_by(target: Vector2) -> bool:
	return position.distance_squared_to(target) <= RADIUS * RADIUS
