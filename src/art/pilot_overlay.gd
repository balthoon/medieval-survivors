## Foreground atmosphere for the shipped storybook direction and the comparison
## mockups.
##
## Added by [Main] above the actors and below the HUD's CanvasLayer, and by the
## capture tool for its fixed tableaux. It owns the clock the fog and motes drift
## on, and finds the player so the mist's lantern pool follows the knight.
class_name PilotOverlay
extends Node2D

const VisualPilot := preload("res://src/art/visual_pilot.gd")

## Set by [Main] and the capture tool; the lantern pool centres on this node.
var player: Node2D = null

var _time: float = 0.0


func _ready() -> void:
	z_index = 20
	queue_redraw()


func _process(delta: float) -> void:
	if not VisualPilot.is_active():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not VisualPilot.is_active():
		return
	var at := Vector2(640.0, 360.0)
	if player != null and is_instance_valid(player):
		at = player.global_position
	VisualPilot.draw_atmosphere(self, _time, at)
