## Throwaway evidence capture for slice 0.2.
##
## Loads the main scene, hands the player a marteau and an arc court so all three
## weapon slots are full, lets the run settle, then saves the frame. The shot
## should show three weapons listed with their recharge bars, the equipment line,
## and bolts in flight.
##
##   godot --path . --script res://tools/capture_slice02.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/slice-0.2-weapons.png"
const WAIT_MS := 3600
const MIN_FRAMES := 120
const EXTRA_WEAPONS := [
	"res://data/weapons/marteau.tres",
	"res://data/weapons/arc_court.tres",
]

var _frames := 0
var _start_ms := 0
var _armed := false
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
	if _main == null:
		push_error("capture: could not instantiate main scene")
		quit(1)
		return
	root.add_child(_main)


func _process(_delta: float) -> bool:
	if _done:
		return true
	_frames += 1

	if not _armed and _frames >= 3:
		_armed = true
		for path in EXTRA_WEAPONS:
			_main._gain_weapon(load(path))

	var elapsed := Time.get_ticks_msec() - _start_ms
	if elapsed < WAIT_MS or _frames < MIN_FRAMES:
		return false

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
