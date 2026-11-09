## Throwaway evidence capture for slice 0.3.
##
## Loads the main scene, fills the three weapon slots, silences the wave spawner
## and keeps placing enemies around the player so the frame shows hits, floating
## numbers, death shards, the new HUD strips and the recharge bars. Then it opens
## the level-up panel and saves a second frame.
##
##   godot --path . --script res://tools/capture_slice03.gd
extends SceneTree

const OUT_COMBAT := "res://production/qa/evidence/slice-0.3-combat.png"
const OUT_LEVELUP := "res://production/qa/evidence/slice-0.3-levelup.png"
const EXTRA_WEAPONS := [
	"res://data/weapons/marteau.tres",
	"res://data/weapons/arc_court.tres",
]
const ENEMY_PATHS := [
	"res://data/enemies/squelette.tres",
	"res://data/enemies/loup_maudit.tres",
	"res://data/enemies/orc.tres",
]
const OFFSETS := [
	Vector2(100.0, -60.0),
	Vector2(120.0, 80.0),
	Vector2(-100.0, 40.0),
	Vector2(-90.0, -70.0),
	Vector2(30.0, 120.0),
]
const COMBAT_MS := 3000
const PANEL_MS := 2500
const SPAWN_EVERY := 30

var _frames := 0
var _start_ms := 0
var _armed := false
var _spawn_index := 0
var _panel_opened := false
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

	if _armed and _frames % SPAWN_EVERY == 0:
		_spawn_one()

	# A level up may still fire from an XP gem dropped before the arm call.
	# Dismiss the panel so the combat frame shows the fight, not the menu.
	if not _panel_opened and _main.is_paused:
		_main.is_paused = false
		_main._pending_choices.clear()
		_main._hud.hide_upgrade_choices()

	var elapsed := Time.get_ticks_msec() - _start_ms

	if not _panel_opened and elapsed >= COMBAT_MS:
		if not _save(OUT_COMBAT):
			return true
		_panel_opened = true
		_main._offer_choices()

	if _panel_opened and elapsed >= COMBAT_MS + PANEL_MS:
		_save(OUT_LEVELUP)
		return true

	return false


func _arm() -> void:
	_armed = true
	for path in EXTRA_WEAPONS:
		_main._gain_weapon(load(path))
	# The wave director stops spawning: every enemy in the shot is placed here,
	# so the frame is reproducible. Placed enemies drop no XP, so the level-up
	# panel cannot open before the combat frame is saved; it is opened on cue.
	_main._enemy_pool.clear()
	for path in ENEMY_PATHS:
		var data := load(path) as EnemyData
		if data != null:
			data.xp_value = 0
	for i in 3:
		_spawn_one()


func _spawn_one() -> void:
	var enemies := _main.get_node_or_null("Enemies")
	if enemies == null:
		return
	var path: String = ENEMY_PATHS[_spawn_index % ENEMY_PATHS.size()]
	var offset: Vector2 = OFFSETS[_spawn_index % OFFSETS.size()]
	_spawn_index += 1
	var data := load(path) as EnemyData
	if data == null:
		return
	var at: Vector2 = _main._player.position + offset
	_main._enemy_manager.spawn(data, at, enemies)


func _save(out_path: String) -> bool:
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		quit(1)
		_done = true
		return false

	var abs_path := ProjectSettings.globalize_path(out_path)
	var err := image.save_png(abs_path)
	print("capture: frames=%d save_err=%d path=%s" % [_frames, err, abs_path])
	if err != OK:
		quit(1)
		_done = true
		return false
	return true
