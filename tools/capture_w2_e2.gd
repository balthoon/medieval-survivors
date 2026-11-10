## Throwaway evidence capture for W2-E2.
##
## Loads the main scene, replaces the starting sword with three of the new
## weapons — the scythe (whirl), the orbital orb and the censer (fuse) — and
## rings the player with stationary dummies, then saves the frame. The shot
## should show the orbit moon in flight, the scythe sweep and its damage numbers,
## and the three new weapon names with their recharge bars.
##
##   godot --path . --script res://tools/capture_w2_e2.gd
extends SceneTree

const OUT_PATH := "res://production/qa/evidence/w2-e2-weapon-mechanics.png"
const WAIT_MS := 1500
const MIN_FRAMES := 90
const WEAPONS := [
	"res://data/weapons/faux.tres",
	"res://data/weapons/orbe.tres",
	"res://data/weapons/encensoir.tres",
]
const DUMMY_ENEMY := "res://data/enemies/squelette.tres"
## Stationary dummies around the player, so a single frame shows every mechanic.
const DUMMY_OFFSETS := [
	Vector2(-52.0, 0.0),
	Vector2(0.0, -58.0),
	Vector2(95.0, 25.0),
	Vector2(40.0, 70.0),
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
		_arm()

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


## Equips the three new weapons and spawns the dummies.
func _arm() -> void:
	_main._inventory.weapons.clear()
	for path in WEAPONS:
		_main._gain_weapon(load(path))

	# Duplicate the archetype: the dummies must stand still and deal no contact
	# damage, and the wave director still draws the shared resource.
	var data := (load(DUMMY_ENEMY) as EnemyData).duplicate() as EnemyData
	data.max_hp = 500
	data.move_speed = 0.0
	data.contact_damage = 0.0

	var player: Player = _main.get_node("Player")
	var container: Node2D = _main.get_node("Enemies")
	var manager: EnemyManager = _main.get_node("EnemyManager")
	for offset in DUMMY_OFFSETS:
		manager.spawn(data, player.position + offset, container)
