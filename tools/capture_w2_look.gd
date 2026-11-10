## Retained evidence for the shipped "Édition enluminée" look.
##
## Launches the real main scene untouched — default art direction, atmosphere
## overlay, starting weapon, live wave — and saves one frame once the welcome
## banner has faded and the first enemies are on screen. Nothing is rearranged:
## the screenshot is what a player sees a few seconds into a run.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --script res://tools/capture_w2_look.gd
extends SceneTree

const VisualPilot := preload("res://src/art/visual_pilot.gd")

const OUT_PATH := "res://production/qa/evidence/w2-look-storybook.png"
## Long enough for the 1.2 s wave banner to fade and a couple of enemies to walk
## in; short enough that no level-up panel has opened yet.
const WAIT_MS := 2600
const MIN_FRAMES := 150

var _frames := 0
var _start_ms := 0
var _done := false
var _main: Node = null


func _initialize() -> void:
	_start_ms = Time.get_ticks_msec()
	if VisualPilot.style != VisualPilot.STYLE_STORYBOOK:
		push_error(
			"capture: shipped style is %d, expected STYLE_STORYBOOK (%d)"
			% [VisualPilot.style, VisualPilot.STYLE_STORYBOOK]
		)
		quit(1)
		return

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

	var elapsed := Time.get_ticks_msec() - _start_ms
	if elapsed < WAIT_MS or _frames < MIN_FRAMES:
		return false

	if _main.get("_atmosphere") == null:
		push_error("capture: the real scene has no atmosphere overlay")
		quit(1)
		_done = true
		return true

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
