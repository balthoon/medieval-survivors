## Retained evidence for lot 2 character animations.
##
## Launches the real main scene, then stages three deterministic poses a few
## seconds into the run: the knight mid-walk, the knight mid-lunge and a dead
## enemy caught halfway through its squash-and-fade. The scene's own wave keeps
## running until the first capture, so the frames show the shipped game rather
## than a staged test scene.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --script res://tools/capture_animations.gd
extends SceneTree

const OUT_DIR := "res://production/qa/evidence/"
const SKELETON_PATH := "res://data/enemies/squelette.tres"

## Long enough for the 1.2 s wave banner to fade and the first enemies to walk in.
const WAIT_FRAMES := 150
## Frames between staging a pose and capturing it, so the redraw reaches the GPU.
const SETTLE_FRAMES := 3

## Manual step length chosen so five walk frames land on the bounce's peak:
## phase = 5 * 0.03125 * 8 Hz = 1.25 cycles, sin = 1.
const MANUAL_DELTA := 0.03125
const WALK_FRAMES := 5

## Where the staged actors stand. All well inside the arena and clear of props.
const PLAYER_SPOT := Vector2(560.0, 380.0)
const WALK_ENEMY_SPOTS: Array[Vector2] = [
	Vector2(720.0, 320.0), Vector2(500.0, 280.0), Vector2(780.0, 440.0),
]
const DEATH_SPOT := Vector2(720.0, 430.0)
## Halfway through DeathFade.DURATION (0.22 s), the body is flat and half-faded.
const DEATH_PROGRESS_TIME := 0.11

var _frames := 0
var _stage := 0
var _wait := 0
var _finished := false
var _main: Node = null
var _player: Player = null
var _manager: EnemyManager = null
var _container: Node2D = null


func _initialize() -> void:
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
	if _finished or _main == null:
		return true
	_frames += 1

	match _stage:
		0:
			if _frames < WAIT_FRAMES:
				return false
			if not _setup_walk():
				return _fail()
			_stage = 1
			_wait = 0
		1:
			if not _settle():
				return false
			if not _save("w2-anim-walk.png"):
				return _fail()
			_player.play_attack_lunge(0.0)
			_player.queue_redraw()
			_stage = 2
			_wait = 0
		2:
			if not _settle():
				return false
			if not _save("w2-anim-lunge.png"):
				return _fail()
			if not _stage_death():
				return _fail()
			_stage = 3
			_wait = 0
		3:
			if not _settle():
				return false
			if not _save("w2-anim-death.png"):
				return _fail()
			_finished = true
			quit(0)
			return true
	return false


## Freezes the run, places the knight and three enemies, and advances five
## manual frames while move_right is held.
func _setup_walk() -> bool:
	_main.set_process(false)
	_player = _main.get_node_or_null("Player") as Player
	_manager = _main.get_node_or_null("EnemyManager") as EnemyManager
	_container = _main.get_node_or_null("Enemies") as Node2D
	if _player == null or _manager == null or _container == null:
		push_error("capture: the main scene is missing Player/EnemyManager/Enemies")
		return false

	var skeleton := load(SKELETON_PATH) as EnemyData
	if skeleton == null:
		push_error("capture: squelette.tres did not load as EnemyData")
		return false

	_player.position = PLAYER_SPOT
	for spot: Vector2 in WALK_ENEMY_SPOTS:
		_manager.spawn(skeleton, spot, _container)

	Input.action_press("move_right")
	for _i in WALK_FRAMES:
		_main._process(MANUAL_DELTA)
	Input.action_release("move_right")
	_player.queue_redraw()
	return true


## Places a dead enemy and catches its fade halfway through.
func _stage_death() -> bool:
	var skeleton := load(SKELETON_PATH) as EnemyData
	if skeleton == null:
		return false
	var enemy := _manager.spawn(skeleton, DEATH_SPOT, _container)
	enemy.take_damage(9999.0)
	_manager.remove_dead(Callable())

	var fade: DeathFade = null
	for child: Node in _container.get_children():
		if child is DeathFade:
			fade = child as DeathFade
	if fade == null:
		push_error("capture: remove_dead did not create a DeathFade")
		return false
	# Own the clock: the engine must not finish the fade before the capture.
	fade.set_process(false)
	fade._process(DEATH_PROGRESS_TIME)
	fade.queue_redraw()
	return true


## Counts settle frames; returns true once enough have passed.
func _settle() -> bool:
	_wait += 1
	return _wait > SETTLE_FRAMES


## Saves the last rendered frame, or reports why it could not.
func _save(file_name: String) -> bool:
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty for " + file_name)
		return false
	var abs_path := ProjectSettings.globalize_path(OUT_DIR + file_name)
	var err := image.save_png(abs_path)
	print("capture: %s save_err=%d path=%s" % [file_name, err, abs_path])
	return err == OK


func _fail() -> bool:
	_finished = true
	quit(1)
	return true
