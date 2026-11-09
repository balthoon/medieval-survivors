## Throwaway evidence capture for the grassy arena.
##
## Loads the main scene, silences the wave spawner, places one enemy of each
## archetype near the player plus two XP gems, guarantees a normal and a critical
## damage number, then saves one frame showing the lawn, the trees, the rocks and
## the readability of every entity on the new floor.
##
##   godot --path . --script res://tools/capture_map.gd
extends SceneTree

const OUT := "res://production/qa/evidence/map-grass.png"
const ENEMY_PATHS := [
	"res://data/enemies/squelette.tres",
	"res://data/enemies/loup_maudit.tres",
	"res://data/enemies/orc.tres",
]
const OFFSETS := [
	Vector2(116.0, -82.0),
	Vector2(-136.0, -46.0),
	Vector2(62.0, 118.0),
]
const SAVE_MS := 1800

## Numbers are spawned slightly before the save so the frame between the spawn
## and the capture is actually rendered.
const NUMBERS_LEAD_MS := 240

var _frames := 0
var _start_ms := 0
var _armed := false
var _numbers_spawned := false
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
		_arm()

	# Dismiss any level-up panel that opened organically: the frame must show the
	# arena, not the menu.
	if _main.is_paused:
		_main.is_paused = false
		_main._pending_choices.clear()
		_main._hud.hide_upgrade_choices()

	if not _numbers_spawned and Time.get_ticks_msec() - _start_ms >= SAVE_MS - NUMBERS_LEAD_MS:
		_numbers_spawned = true
		_spawn_numbers()

	if Time.get_ticks_msec() - _start_ms >= SAVE_MS:
		_save()
		return true

	return false


func _arm() -> void:
	_armed = true
	_main._enemy_pool.clear()
	var enemies := _main.get_node_or_null("Enemies")
	var pickups := _main.get_node_or_null("Pickups")
	if enemies == null or pickups == null:
		return

	for index in ENEMY_PATHS.size():
		var data := load(ENEMY_PATHS[index]) as EnemyData
		if data == null:
			continue
		# Freeze and silence them: the frame must show each archetype cleanly, not
		# a huddle under the player.
		data.xp_value = 0
		data.move_speed = 0.0
		_main._enemy_manager.spawn(data, _main._player.position + OFFSETS[index], enemies)

	for offset in [Vector2(-186.0, 96.0), Vector2(196.0, -124.0)]:
		pickups.add_child(XpPickup.create(1, _main._player.position + offset))


## Spawns one normal and one critical number over two of the placed enemies.
func _spawn_numbers() -> void:
	if _main._fx == null:
		return
	var centre: Vector2 = _main._player.position
	_main._fx.spawn_number(centre + OFFSETS[0] + Vector2(0.0, -26.0), 12.0, false)
	_main._fx.spawn_number(centre + OFFSETS[1] + Vector2(0.0, -26.0), 31.0, true)


func _save() -> void:
	_done = true

	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		quit(1)
		return

	var abs_path := ProjectSettings.globalize_path(OUT)
	var err := image.save_png(abs_path)
	print("capture: frames=%d save_err=%d path=%s" % [_frames, err, abs_path])
	if err != OK:
		quit(1)
		return
	quit(0)
