## The player-controlled knight: position, hit points, facing and invulnerability.
##
## Reads no input and draws no weapon of its own. main.gd polls input and calls
## step_movement() and step(); WeaponSystem aims the weapons and attaches their
## views as children of this node.
class_name Player extends Node2D

## Emitted exactly once, when hp crosses zero.
signal died

## Collision radius, kept as margin from the playable rectangle edges.
const RADIUS := 14.0

## Playable rectangle. The HUD owns the bottom strip of the screen, so the arena
## stops above it and the player stays RADIUS inside the edges.
const PLAY_RECT := Rect2(40.0, 72.0, 1200.0, 536.0)

## Seconds of invulnerability granted after one hit lands.
const INVULNERABLE_TIME := 0.4

## Blink rate of the body while invulnerable, in toggles per second.
const BLINK_HZ := 12.0

## Seconds the body leans toward a firing weapon after it shoots.
const LUNGE_DURATION := 0.12

## Pixels the body is displaced toward the firing direction at the start of a
## lunge. The lean eases out, so it is already fading on the second frame.
const LUNGE_DISTANCE := 4.0

## Rate at which the walk phase advances while the player moves, in cycles per
## second. The bounce is the rectified sine of this phase, so the knight touches
## down twice per phase cycle.
const WALK_PHASE_HZ := 8.0

## Peak height of the walk bounce, in pixels. Negative y is up, matching the
## breathing offset.
const WALK_BOUNCE := 2.5

## Copy of the run stats. Set by setup().
var stats: Stats = null
## Current hit points.
var hp: float = 100.0
## Aiming angle in radians, followed by every idle weapon. Zero points right.
var facing: float = 0.0
## Seconds of invulnerability left. While above zero, take_damage() refuses hits.
var invulnerable_time: float = 0.0

## Seconds accumulated within the current invulnerability window, for the blink.
var _blink_time: float = 0.0
## False on the half-frames the player is blinked out of sight. The body is drawn
## in [method _draw], so hiding it is a redraw that paints nothing — the weapons
## are separate nodes and stay visible throughout, as the rules above say.
var _blink_on: bool = true
## Seconds since the run started, used only by the breathing offset.
var _anim_time: float = 0.0
## True while the last step_movement() call carried input. step() reads it to
## advance the walk phase only on frames the player actually moved.
var _is_walking: bool = false
## Radians accumulated by the walk cycle. Frozen while the player stands still.
var _walk_phase: float = 0.0
## Seconds left of the attack lunge. Zero when the body sits centred.
var _lunge_time: float = 0.0
## Unit direction of the current lunge, copied from the firing angle.
var _lunge_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	queue_redraw()


## Draws the knight. The parent draws before its children, so the body sits under
## the weapon views without any z-index work.
func _draw() -> void:
	if not _blink_on:
		return
	var bob := InkStyle.breathe(_anim_time)
	if _is_walking:
		bob += -absf(sin(_walk_phase)) * WALK_BOUNCE
	var is_lunging := _lunge_time > 0.0
	if is_lunging:
		# The lean lives in the draw transform, never in position: collision,
		# obstacle resolution and the weapons' attach point must not move.
		var remaining := _lunge_time / LUNGE_DURATION
		draw_set_transform(_lunge_direction * (LUNGE_DISTANCE * remaining * remaining))
	ActorArt.draw_knight(self, _view(), RADIUS, bob)
	if is_lunging:
		draw_set_transform(Vector2.ZERO)


## Which of the four drawn orientations matches the current facing. The
## comparison is on the dominant component, so the knight does not flicker
## between views when the aim sweeps diagonally.
func _view() -> String:
	var horizontal := cos(facing)
	var vertical := sin(facing)
	if absf(horizontal) >= absf(vertical):
		return "right" if horizontal >= 0.0 else "left"
	return "front" if vertical >= 0.0 else "back"


## Copies the class stats and resets hp to full. Call once at run start.
func setup(class_data: ClassData) -> void:
	stats = Stats.from_class(class_data)
	hp = stats.max_hp


## Moves the player by dir scaled by the effective move speed. Arguments: dir is
## a normalised Vector2 (zero allowed), delta in seconds. Clamps inside the
## playable rect. Also records whether this frame carried input, so step() can
## advance the walk cycle only while the knight is actually walking.
func step_movement(dir: Vector2, delta: float) -> void:
	if stats == null:
		_is_walking = false
		return
	_is_walking = dir.length_squared() > 0.0
	position += dir * stats.effective_move_speed() * delta
	clamp_inside()


## Keeps the player's centre RADIUS inside [constant PLAY_RECT]. Called after
## movement and, from main.gd, after obstacle resolution, so neither the arena
## edge nor a prop can leave the knight outside the playable area.
func clamp_inside() -> void:
	position.x = clampf(
		position.x, PLAY_RECT.position.x + RADIUS, PLAY_RECT.end.x - RADIUS
	)
	position.y = clampf(
		position.y, PLAY_RECT.position.y + RADIUS, PLAY_RECT.end.y - RADIUS
	)


## Advances the invulnerability window, the breathing offset, the walk cycle, the
## attack lunge and the blink. Display feedback only: the weapons stay visible
## and the player keeps moving.
func step(delta: float) -> void:
	_anim_time += delta
	if _is_walking:
		_walk_phase = fposmod(_walk_phase + delta * TAU * WALK_PHASE_HZ, TAU)
	_lunge_time = maxf(_lunge_time - delta, 0.0)
	queue_redraw()
	if invulnerable_time <= 0.0:
		return
	invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	_blink_time += delta
	_blink_on = int(_blink_time * BLINK_HZ) % 2 == 0
	if invulnerable_time <= 0.0:
		_blink_on = true


## Leans the body toward an attack fired along [param angle] for
## [constant LUNGE_DURATION] seconds. Visual feedback only: the node position
## never changes, so collision, obstacle resolution and the weapons' attach point
## are unaffected.
func play_attack_lunge(angle: float) -> void:
	_lunge_time = LUNGE_DURATION
	_lunge_direction = Vector2.RIGHT.rotated(angle)


## Points the player toward a world position.
func aim_at(world_pos: Vector2) -> void:
	var offset := world_pos - position
	if offset.length_squared() > 0.0:
		facing = offset.angle()


## Points the player along a direction. Used when no enemy is alive, so the
## weapons follow where the player is heading instead of freezing in place.
func face_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.0:
		facing = dir.angle()


## Applies damage unless the player is dead or still invulnerable. Returns true
## when the hit landed, so the caller knows whether to play hurt feedback.
## Crossing zero emits died exactly once.
func take_damage(amount: float) -> bool:
	if hp <= 0.0 or invulnerable_time > 0.0:
		return false
	hp = maxf(hp - amount, 0.0)
	invulnerable_time = INVULNERABLE_TIME
	_blink_time = 0.0
	if hp <= 0.0:
		died.emit()
	return true


## Restores hit points, never above the current max. Used by max-HP gains.
func heal(amount: float) -> void:
	if stats == null or amount <= 0.0 or hp <= 0.0:
		return
	hp = minf(hp + amount, stats.max_hp)


## True while hp > 0.
func is_alive() -> bool:
	return hp > 0.0
