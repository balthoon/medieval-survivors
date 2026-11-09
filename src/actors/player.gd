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
## The drawn body, hidden and shown to blink. May be null in a bare scene.
var _body: Node2D = null


func _ready() -> void:
	_body = get_node_or_null("Body") as Node2D
	queue_redraw()


## Draws the dark ground ring under the body, so the knight sits on the arena
## instead of floating over it. The parent draws before its children, so this is
## painted beneath the Body node and the weapon views.
func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 7.0, Color(0.16, 0.14, 0.12, 0.10))
	draw_arc(
		Vector2.ZERO, RADIUS + 4.0, 0.0, TAU, 32, Color(0.16, 0.14, 0.12, 0.35), 2.0, true
	)


## Copies the class stats and resets hp to full. Call once at run start.
func setup(class_data: ClassData) -> void:
	stats = Stats.from_class(class_data)
	hp = stats.max_hp


## Moves the player by dir scaled by the effective move speed. Arguments: dir is
## a normalised Vector2 (zero allowed), delta in seconds. Clamps inside the
## playable rect.
func step_movement(dir: Vector2, delta: float) -> void:
	if stats == null:
		return
	position += dir * stats.effective_move_speed() * delta
	position.x = clampf(
		position.x, PLAY_RECT.position.x + RADIUS, PLAY_RECT.end.x - RADIUS
	)
	position.y = clampf(
		position.y, PLAY_RECT.position.y + RADIUS, PLAY_RECT.end.y - RADIUS
	)


## Advances the invulnerability window and blinks the body while it lasts.
## Display feedback only: the weapons stay visible and the player keeps moving.
func step(delta: float) -> void:
	if invulnerable_time <= 0.0:
		return
	invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	_blink_time += delta
	if _body != null:
		_body.visible = int(_blink_time * BLINK_HZ) % 2 == 0
		if invulnerable_time <= 0.0:
			_body.visible = true


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
