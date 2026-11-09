## Throwaway weapon sheet: the three melee weapons side by side at 3x, so the
## blade and the hammer can be judged as drawings rather than as 2 px sticks.
##
## Not a gameplay check — a look check. Run windowed: a headless viewport has no
## image to read.
##
##   godot --path . --script res://tools/capture_weapons.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/art-weapons.png"

## Camera zoom. A 64 px sword at 1x is mostly ink rim; at 3x the drawing is what
## is being judged.
const SHEET_ZOOM := 3.0
const SHEET_CENTRE := Vector2(400.0, 340.0)

## Every weapon is drawn pointing up-right, so its length and its guard both
## show. Parked left to right at these x positions, all at WEAPON_Y.
const WEAPON_Y := 350.0
const WEAPON_FACING := -PI * 0.25
const WEAPONS := [
	["res://data/weapons/dague.tres", 230.0],
	["res://data/weapons/epee_longue.tres", 380.0],
	["res://data/weapons/marteau.tres", 545.0],
]

const ARM_AT_MS := 300
const SETTLE_FRAMES := 6

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


## Freezes the run, hides the arena's own actors, and parks one [WeaponView] per
## melee weapon across the screen.
func _arm() -> void:
	_armed = true
	_arm_frame = _frame
	_main.is_paused = true
	_main._enemy_pool.clear()
	_main.get_node("EnemyManager").remove_dead(Callable())
	for old in _main.get_node("Enemies").get_children():
		old.queue_free()
	for old in _main.get_node("Pickups").get_children():
		old.queue_free()

	_main._player.visible = false
	_main.get_node("HUD").visible = false

	var camera := _main.get_node("Camera") as Camera2D
	camera.position = SHEET_CENTRE
	camera.zoom = Vector2(SHEET_ZOOM, SHEET_ZOOM)

	var host: Node2D = _main.get_node("Enemies")
	for entry in WEAPONS:
		var data := load(entry[0]) as WeaponData
		var view := WeaponView.new()
		view.setup(data, data.range_px)
		view.position = Vector2(entry[1], WEAPON_Y)
		host.add_child(view)
		view.set_facing(WEAPON_FACING)
		view.step(0.0)


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
