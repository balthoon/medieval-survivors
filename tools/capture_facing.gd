## Throwaway evidence capture for the blade-follows-facing fix.
##
## Holds W (walk up) for the first stretch of the run, then saves the root
## viewport. With nothing in weapon range the blade must be pointing up; the
## player's default facing is to the right, so the shot distinguishes the two.
##
##   godot --path . --script res://tools/capture_facing.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/slice-0.1-facing.png"
## How long W is held before the frame is taken, in milliseconds.
const HOLD_MS := 1500
const MIN_FRAMES := 90

var _frames := 0
var _start_ms := 0
var _pressed := false
var _done := false


func _initialize() -> void:
	_start_ms = Time.get_ticks_msec()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("capture: could not load main scene")
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("capture: could not instantiate main scene")
		quit(1)
		return
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if _done:
		return true
	_frames += 1

	if not _pressed:
		var press := InputEventKey.new()
		press.physical_keycode = KEY_W
		press.keycode = KEY_W
		press.pressed = true
		Input.parse_input_event(press)
		_pressed = true

	var elapsed := Time.get_ticks_msec() - _start_ms
	if elapsed < HOLD_MS or _frames < MIN_FRAMES:
		return false

	var release := InputEventKey.new()
	release.physical_keycode = KEY_W
	release.keycode = KEY_W
	release.pressed = false
	Input.parse_input_event(release)

	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		quit(1)
		_done = true
		return true

	var abs_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := image.save_png(abs_path)
	print("capture: frames=%d elapsed_ms=%d save_err=%d path=%s" % [_frames, elapsed, err, abs_path])
	_done = true
	quit(0 if err == OK else 1)
	return true
