## One expanding ink ring, used for level ups and other loud beats.
##
## Self-contained: create() builds it, _process animates it, and it frees itself
## at the end of its life, so the caller only adds it to the tree.
class_name RingBurst
extends Node2D

## Seconds the ring takes to expand and fade.
const DURATION := 0.45

## Starting radius of the ring, in pixels.
const START_RADIUS := 8.0

## Ending radius of the ring, in pixels.
const END_RADIUS := 96.0

## Starting width of the ring stroke, in pixels.
const START_WIDTH := 3.0

## Colour of the ring, set by create().
var _color: Color = Color.WHITE
## Seconds since the ring was created.
var _time: float = 0.0


## Builds a ring centred on [param at], drawn in [param color]. Returns it
## unattached; the caller adds it to the scene.
static func create(at: Vector2, color: Color) -> RingBurst:
	var burst := RingBurst.new()
	burst.position = at
	burst._color = color
	return burst


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()


func _draw() -> void:
	var t := clampf(_time / DURATION, 0.0, 1.0)
	var radius := lerpf(START_RADIUS, END_RADIUS, t)
	var width := lerpf(START_WIDTH, 0.0, t)
	if width <= 0.0:
		return
	var colour := Color(_color.r, _color.g, _color.b, 1.0 - t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, colour, width, true)
