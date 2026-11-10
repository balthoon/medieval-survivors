## One thrown censer: flies to a point, lands, then detonates after its fuse.
##
## It never collides in flight. The landing point is the position the target
## occupied when the censer was thrown, so the payload rewards prediction rather
## than tracking (GDD edge case E11). WeaponSystem owns the loop and applies the
## blast; this node only reports where and when.
class_name CenserBomb
extends Node2D

## Emitted once the fuse burns out, with the blast centre and its radius.
signal detonated(at: Vector2, radius: float)

## Radius the censer is drawn at, in pixels.
const DRAW_RADIUS := 7.0

## Colour of the fuse telegraph. Danger red, translucent, as on the boss disc.
const FUSE_COLOR := Color(0.75, 0.20, 0.14)

## Alpha of the fuse ring when it lands and just before the blast.
const FUSE_MIN_ALPHA := 0.22
const FUSE_MAX_ALPHA := 0.70

## Weapon this censer came from. Set by create().
var weapon: WeaponData = null
## Point the censer was thrown at, in world space.
var _landing: Vector2 = Vector2.ZERO
## True while still in flight; the fuse only burns once it is on the ground.
var _flying: bool = true
## Seconds left before the detonation.
var _fuse_left: float = 0.0


## Builds a censer thrown from [param from] toward [param to]. Returns it
## unattached.
static func create(fired_weapon: WeaponData, from: Vector2, to: Vector2) -> CenserBomb:
	var bomb := CenserBomb.new()
	bomb.weapon = fired_weapon
	bomb.position = from
	bomb._landing = to
	bomb._fuse_left = maxf(fired_weapon.fuse_seconds, 0.0) if fired_weapon != null else 0.0
	return bomb


## Moves the censer and burns the fuse. Returns true once it has detonated.
func step(delta: float) -> bool:
	if weapon == null:
		return true

	if _flying:
		var distance := weapon.projectile_speed * delta
		var offset := _landing - position
		if offset.length() <= distance:
			position = _landing
			_flying = false
			queue_redraw()
		else:
			position += offset.normalized() * distance
		return false

	_fuse_left = maxf(_fuse_left - delta, 0.0)
	queue_redraw()
	if _fuse_left <= 0.0:
		detonated.emit(position, weapon.fuse_radius)
		return true
	return false


## Draws the censer and, once landed, the blast ring growing toward its radius.
func _draw() -> void:
	if weapon == null:
		return
	if not _flying:
		var total := maxf(weapon.fuse_seconds, 0.001)
		var progress := clampf(1.0 - _fuse_left / total, 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			weapon.fuse_radius,
			0.0,
			TAU,
			48,
			Color(FUSE_COLOR.r, FUSE_COLOR.g, FUSE_COLOR.b,
				lerpf(FUSE_MIN_ALPHA, FUSE_MAX_ALPHA, progress)),
			2.0
		)
	InkStyle.circle(self, Vector2.ZERO, DRAW_RADIUS, weapon.color, 1.4)
	InkStyle.detail(self, Vector2(0.0, -DRAW_RADIUS), Vector2(0.0, -DRAW_RADIUS - 5.0), 1.2)
