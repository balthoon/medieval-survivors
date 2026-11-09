## Throwaway evidence capture script for slice 0.1 verification.
##
## Runs the main scene windowed for a while, then saves the root viewport as a
## PNG. Usage:
##   godot --path . --script res://tools/capture_evidence.gd -- <out_res_path> <min_ms>
## Both arguments are optional; the defaults reproduce the original capture.
extends SceneTree

## Default where the captured frame is written.
const DEFAULT_OUT_PATH := "res://production/qa/evidence/slice-0.1-play.png"
## Default wall-clock time to let the run settle before capturing.
const DEFAULT_MIN_MS := 2000
## Minimum number of rendered frames before capturing.
const MIN_FRAMES := 90

var _out_path := DEFAULT_OUT_PATH
var _min_ms := DEFAULT_MIN_MS
var _count := 1
var _interval_ms := 90
var _frames := 0
var _start_ms := 0
var _failed := false
var _saved := 0
var _next_ms := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and not args[0].is_empty():
		_out_path = args[0]
	if args.size() >= 2:
		_min_ms = int(args[1])
	if args.size() >= 3:
		_count = maxi(1, int(args[2]))
	if args.size() >= 4:
		_interval_ms = maxi(1, int(args[3]))

	_start_ms = Time.get_ticks_msec()
	_next_ms = _min_ms
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("capture: could not load main scene")
		_failed = true
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("capture: could not instantiate main scene")
		_failed = true
		quit(1)
		return
	root.add_child(scene)
	print("capture: scene added, waiting %d ms" % _min_ms)


func _process(_delta: float) -> bool:
	if _failed:
		return true

	_frames += 1
	var elapsed := Time.get_ticks_msec() - _start_ms
	if elapsed < _next_ms or _frames < MIN_FRAMES:
		return false

	var texture := root.get_texture()
	if texture == null:
		push_error("capture: root viewport has no texture")
		quit(1)
		return true

	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		quit(1)
		return true

	var target := _out_path
	if _count > 1:
		target = _out_path.get_basename() + "_" + str(_saved) + ".png"

	var abs_path := ProjectSettings.globalize_path(target)
	var err := image.save_png(abs_path)
	print(
		"capture: frames=%d elapsed_ms=%d size=%s save_err=%d path=%s"
		% [_frames, elapsed, str(image.get_size()), err, abs_path]
	)
	if err != OK:
		quit(1)
		return true

	_saved += 1
	if _saved >= _count:
		return true
	_next_ms = elapsed + _interval_ms
	return false
