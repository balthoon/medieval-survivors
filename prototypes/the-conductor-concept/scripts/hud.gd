# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09
#
# Flat-colour HUD: beat bar, Crescendo counter, one hint line, status line, timer.
# All text is ASCII so the file needs no special encoding handling.

class_name ProtoHUD
extends CanvasLayer

const BAR_WIDTH := 400.0
const BAR_HEIGHT := 18.0
const FILL_COLOR := Color(0.85, 0.65, 0.15, 1.0)
const FLASH_COLOR := Color(1.0, 0.9, 0.5, 1.0)
const DEAD_TEXT := "MORT - R pour relancer"

@onready var bar_fill: ColorRect = $BeatBarFill
@onready var crescendo_label: Label = $CrescendoLabel
@onready var hint_label: Label = $HintLabel
@onready var status_label: Label = $StatusLabel
@onready var timer_label: Label = $TimerLabel

var _flash_tween: Tween = null


func _ready() -> void:
	hint_label.text = "ZQSD / fleches : bouger    ESPACE : lancer    lancer sur le temps remplit le Crescendo"
	crescendo_label.text = "Crescendo : 0 / 10"
	status_label.text = ""
	timer_label.text = "0:00"
	bar_fill.color = FILL_COLOR


## Refresh the Crescendo counter, the survival timer and the Forte indicator.
func update_state(crescendo: int, max_crescendo: int, elapsed: float, forte: bool) -> void:
	var line := "Crescendo : %d / %d" % [crescendo, max_crescendo]
	if forte:
		line += "    FORTE"
	crescendo_label.text = line
	timer_label.text = _format_time(elapsed)


## Move the beat-bar fill to `p` (0.0 .. 1.0) through the current beat.
func update_beat_phase(p: float) -> void:
	var ratio := clampf(p, 0.0, 1.0)
	bar_fill.size = Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)


## Pulse the beat bar on every beat.
func flash_beat() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	bar_fill.color = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(bar_fill, "color", FILL_COLOR, 0.20)


func show_dead() -> void:
	status_label.text = DEAD_TEXT


func show_alive() -> void:
	status_label.text = ""


func _format_time(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	return "%d:%02d" % [total / 60, total % 60]
