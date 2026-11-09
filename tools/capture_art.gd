## Throwaway art sheet: draws every actor the new pass touches, side by side, on
## the real grass, and saves one frame.
##
## Not a gameplay check — a look check. Run windowed: a headless viewport has no
## image to read.
##
##   godot --path . --script res://tools/capture_art.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/art-sheet.png"

## Camera zoom for the sheet. The actors are 30–60 px tall in play; at 1x a
## silhouette cannot be judged, which is the whole point of this capture.
const SHEET_ZOOM := 3.0
const SHEET_CENTRE := Vector2(400.0, 340.0)

## Knight positions for the four drawn orientations, in the order saved.
const KNIGHT_ROW := Vector2(240.0, 275.0)
const KNIGHT_GAP := 62.0
const KNIGHT_FACING := [0.0, PI * 0.5, PI, PI * 1.5]

## Creature row: art resource path and the x it is parked at.
const CREATURE_Y := 410.0
const CREATURES := [
	["res://data/enemies/squelette.tres", 240.0],
	["res://data/enemies/orc.tres", 330.0],
	["res://data/enemies/loup_maudit.tres", 430.0],
	["res://data/enemies/seigneur_squelette.tres", 560.0],
]

## Frames to let the scene settle before saving. Nodes added to the tree paint on
## the *next* frame, so saving on the arming frame photographs an empty arena.
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


## Freezes the run and builds the sheet: four knight orientations, then one of
## each archetype. The live player is hidden so it does not duplicate a pose.
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

	var students: Node2D = _main.get_node("Enemies")
	var class_data := load("res://data/classes/chevalier.tres") as ClassData
	for index in KNIGHT_FACING.size():
		var knight := Player.new()
		knight.setup(class_data)
		knight.facing = KNIGHT_FACING[index]
		knight.position = KNIGHT_ROW + Vector2(KNIGHT_GAP * float(index), 0.0)
		students.add_child(knight)

	for entry in CREATURES:
		var data := load(entry[0]) as EnemyData
		var enemy := Enemy.create(data, 1.0, 1.0)
		enemy.position = Vector2(entry[1], CREATURE_Y)
		students.add_child(enemy)


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
