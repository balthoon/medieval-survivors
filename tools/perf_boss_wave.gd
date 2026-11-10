## Throwaway performance probe for the boss wave.
##
## Instantiates the real main scene, silences its wave director, then fills the
## arena with a wave-5-sized crowd plus the boss and lets the shipped game run
## for 900 frames while printing the measured FPS, draw calls and process time.
## Player and enemies are topped up so nothing dies and the load stays constant.
##
## Must run windowed, not headless: the renderer is what is being measured.
##
##   godot --path . --windowed --resolution 1280x720 --script res://tools/perf_boss_wave.gd
extends SceneTree

const SPAWN_FRAME := 10
const MEASURE_FRAMES := 900
const SHOT_FRAME := 150
const SHOT_PATH := "res://production/qa/evidence/w2-boss-wave.png"
const CENTER := Vector2(640.0, 360.0)

const BOSS_PATH := "res://data/enemies/seigneur_squelette.tres"
const POOL: Array[String] = [
	"res://data/enemies/squelette.tres",
	"res://data/enemies/orc.tres",
	"res://data/enemies/loup_maudit.tres",
]

var _main: Node = null
var _player: Player = null
var _manager: EnemyManager = null
var _container: Node2D = null
var _frames := 0
var _samples: Array[float] = []
## Crowd size, overridable: `-- 0` measures the arena and player alone.
var _crowd := 41
var _with_boss := true


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("perf: cannot load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_crowd = int(args[0])
	if args.size() > 1:
		_with_boss = args[1] == "boss"


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < SPAWN_FRAME:
		return false
	if _frames == SPAWN_FRAME:
		_stage()
		return false

	# Keep the load constant: nothing dies during the measurement.
	_player.hp = 100000.0
	for enemy in _manager.enemies:
		enemy.hp = 1e9

	if _frames == SHOT_FRAME and _with_boss:
		var image := root.get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path(SHOT_PATH))
		print("PERF_SHOT saved")

	if _frames % 60 == 0:
		var fps := Engine.get_frames_per_second()
		_samples.append(fps)
		print(
			"PERF fps=%d draw_calls=%d process_ms=%.2f" % [
				fps,
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			]
		)

	if _frames >= SPAWN_FRAME + MEASURE_FRAMES:
		var total := 0.0
		var worst := 999.0
		for sample in _samples:
			total += sample
			worst = minf(worst, sample)
		print(
			"PERF_SUMMARY samples=%d avg=%.1f worst=%.1f enemies=%d" % [
				_samples.size(), total / maxf(float(_samples.size()), 1.0), worst,
				_manager.count(),
			]
		)
		quit(0)
		return true
	return false


func _stage() -> void:
	_main._enemy_pool.clear()
	_player = _main.get_node("Player") as Player
	_manager = _main.get_node("EnemyManager") as EnemyManager
	_container = _main.get_node("Enemies") as Node2D
	_player.position = CENTER

	var boss := load(BOSS_PATH) as EnemyData
	if _with_boss and boss != null:
		_manager.spawn(boss, CENTER + Vector2(140.0, 0.0), _container)

	var types: Array[EnemyData] = []
	for path in POOL:
		var data := load(path) as EnemyData
		if data != null:
			types.append(data)
	if types.is_empty() or _crowd <= 0:
		return

	for index in _crowd:
		var angle := TAU * float(index) / float(_crowd)
		var radius := 120.0 + 70.0 * float(index % 3)
		var at := CENTER + Vector2.RIGHT.rotated(angle) * radius
		_manager.spawn(types[index % types.size()], at, _container)
