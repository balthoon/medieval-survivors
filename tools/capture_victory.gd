## Throwaway capture: plays a few seconds so the arena is not empty, then ends
## the run as won and photographs the victory card.
##
## Not a gameplay check — a look check. Run windowed: a headless viewport has no
## image to read.
##
##   godot --path . --script res://tools/capture_victory.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/victory.png"

## Let the run breathe first: the card is always read over a live arena, never
## over the empty one the scene starts as.
const ARM_AT_MS := 7000
const SETTLE_FRAMES := 6

## Values shown on the card. The run is forced, so they are stated here rather
## than earned by playing seven seconds.
const SHOWN_LEVEL := 7
const SHOWN_LAST_WAVE := 9

var _start_ms := 0
var _frame := 0
var _armed := false
var _arm_frame := 0
var _done := false
var _main: Node = null


func _initialize() -> void:
	_start_ms = Time.get_ticks_msec()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("capture: could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	if _done:
		return true
	_frame += 1
	if not _armed and Time.get_ticks_msec() - _start_ms >= ARM_AT_MS:
		_arm()
	if not _armed:
		return false
	if _frame - _arm_frame < SETTLE_FRAMES:
		return false
	_save()
	return true


## Forces the end state and calls the same entry point the real win calls.
func _arm() -> void:
	_armed = true
	_arm_frame = _frame
	_main._level = SHOWN_LEVEL
	# Put the wave clock where a real finish leaves it — last wave, zero seconds
	# left — and refresh the HUD, or the bars behind the card still read wave 1.
	_main._wave_director.wave_index = SHOWN_LAST_WAVE
	_main._wave_director.time_in_wave = _main._wave_director.data.duration
	_main._refresh_hud()
	_main._win()


func _save() -> void:
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		quit(1)
		_done = true
		return
	var abs_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := image.save_png(abs_path)
	print("capture: frame=%d save_err=%d path=%s" % [_frame, err, abs_path])
	_done = true
	quit(0 if err == OK else 1)
