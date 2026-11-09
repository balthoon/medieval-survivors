## Throwaway crowd check: a mixed horde around the player at 1x, which is the
## only scale at which the art bible's first rule can be judged — is each
## archetype identifiable on grass, in a crowd, at a glance?
##
##   godot --path . --script res://tools/capture_horde.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/art-horde.png"

## Archetypes placed around the player, in the order they are laid out.
const POOL := [
	"res://data/enemies/squelette.tres",
	"res://data/enemies/orc.tres",
	"res://data/enemies/loup_maudit.tres",
]

## How many enemies surround the player, and the radii they are placed at.
const COUNT := 30
const RING_MIN := 90.0
const RING_MAX := 330.0

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


func _arm() -> void:
	_armed = true
	_arm_frame = _frame
	_main.is_paused = true
	_main._enemy_pool.clear()
	_main.get_node("EnemyManager").remove_dead(Callable())
	for old in _main.get_node("Enemies").get_children():
		old.queue_free()

	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var host: Node2D = _main.get_node("Enemies")
	var centre: Vector2 = _main._player.position
	for index in COUNT:
		var data := load(POOL[index % POOL.size()]) as EnemyData
		var enemy := Enemy.create(data, 1.0, 1.0)
		var angle := TAU * float(index) / float(COUNT) + rng.randf_range(-0.11, 0.11)
		var distance := rng.randf_range(RING_MIN, RING_MAX)
		enemy.position = centre + Vector2(cos(angle), sin(angle)) * distance
		host.add_child(enemy)


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
