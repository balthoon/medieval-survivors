## Throwaway evidence capture for slice 0.4.
##
## Loads the main scene, drops a boss in front of the player and lets its slam
## telegraph wind up, then saves a frame. Kills the boss on cue and saves the
## loot panel. Run windowed: a headless viewport has no image to read.
##
##   godot --path . --script res://tools/capture_slice04.gd
extends SceneTree

const OUT_BOSS := "res://production/qa/evidence/slice-0.4-boss.png"
const OUT_LOOT := "res://production/qa/evidence/slice-0.4-loot.png"
const BOSS_WAVE := 4
## Distance in front of the player the boss is placed at, in pixels. Must stay
## inside the 96 px slam radius so the telegraph starts immediately, and is kept
## low and right so neither the disc nor the boss reaches the wave banner.
const BOSS_OFFSET := Vector2(60.0, 60.0)
## Seconds to wait for the extra frames to settle before acting.
const ARM_AT_MS := 250
## Safety net: capture the boss frame anyway after this long.
const BOSS_TIMEOUT_MS := 6000
## Delay between arming the loot panel and saving it.
const LOOT_DELAY_MS := 700

var _frame := 0
var _start_ms := 0
var _armed := false
var _boss_saved := false
var _kill_ms := 0
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
	_frame += 1

	var elapsed := Time.get_ticks_msec() - _start_ms
	if not _armed and elapsed >= ARM_AT_MS:
		_arm()
	if not _armed:
		return false

	if not _boss_saved:
		var ready: bool = (
			_main._boss != null
			and _main._boss.is_telegraphing()
			and _main._boss.windup_progress() >= 0.7
		)
		if ready or elapsed >= BOSS_TIMEOUT_MS:
			if not _save(OUT_BOSS):
				return true
			_boss_saved = true
			_kill_ms = Time.get_ticks_msec()
			_kill_boss()
		return false

	if Time.get_ticks_msec() - _kill_ms >= LOOT_DELAY_MS:
		_save(OUT_LOOT)
		return true
	return false


## Stops the horde, spawns the boss on a boss wave and parks it in front of the
## player. The boss's XP is zeroed so a level-up panel cannot cover either shot.
func _arm() -> void:
	_armed = true
	_main._enemy_pool.clear()
	if _main._boss_data != null:
		_main._boss_data.xp_value = 0
	# The director is moved to the boss wave first so the banner, the boss bar
	# and the tier all read as they would in a real run.
	_main._wave_director.wave_index = BOSS_WAVE
	_main._on_wave_started(BOSS_WAVE)
	if _main._boss != null:
		_main._boss.position = _main._player.position + BOSS_OFFSET


## Kills the boss through the normal removal path, which opens the loot panel.
func _kill_boss() -> void:
	if _main._boss == null:
		return
	_main._boss.hp = 0.0
	_main._collect_pickups(0.0)


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
	print("capture: frames=%d save_err=%d path=%s" % [_frame, err, abs_path])
	if err != OK:
		quit(1)
		_done = true
		return false
	return true
