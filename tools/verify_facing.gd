## Throwaway verification for the blade-tracks-nearest-enemy rule in main.gd.
##
## Loads the real main scene, silences spawning, then asserts three cases:
##   1. no living enemy        -> the blade follows the movement direction;
##   2. one enemy far outside weapon range -> the blade still aims at it;
##   3. a nearer enemy appears -> the blade switches to the nearer one.
## Prints PASS/FAIL lines and exits non-zero on any failure.
##
##   godot --path . --script res://tools/verify_facing.gd
extends SceneTree

const ANGLE_EPSILON := 0.05

var _frame := 0
var _failures := 0
var _main: Node = null
var _player: Player = null
var _manager: EnemyManager = null


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("verify: could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	_player = _main.get_node_or_null("Player") as Player
	_manager = _main.get_node_or_null("EnemyManager") as EnemyManager
	if _player == null or _manager == null:
		print("FAIL: could not find Player / EnemyManager")
		quit(1)
		return true

	# Silence the wave director for the rest of the run: with an empty enemy pool
	# _on_spawn_tick() returns immediately, so the only enemies are ours.
	_main._enemy_pool.clear()
	_manager.remove_dead(Callable())

	# Case 1: nothing alive -> the blade follows the movement direction.
	_expect_empty_field()
	_main._update_facing(Vector2.DOWN)
	_expect("no enemy alive, facing down", _player.facing, PI * 0.5)

	# Case 2: one enemy far outside weapon range -> still tracked.
	var far_at := _player.position + Vector2(400.0, 0.0)
	_manager.spawn(_sample_enemy(), far_at, _main.get_node("Enemies"))
	_main._update_facing(Vector2.DOWN)
	_expect("far enemy, facing it", _player.facing, 0.0)

	# Case 3: a nearer enemy appears -> it wins over the far one.
	var near_at := _player.position + Vector2(-120.0, 0.0)
	_manager.spawn(_sample_enemy(), near_at, _main.get_node("Enemies"))
	_main._update_facing(Vector2.UP)
	_expect("nearer enemy wins", absf(_player.facing), PI)

	print("verify: failures=%d" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _expect_empty_field() -> void:
	var living := 0
	for enemy in _manager.enemies:
		if enemy != null and enemy.hp > 0.0:
			living += 1
	if living == 0:
		print("PASS: field cleared before case 1")
		return
	_failures += 1
	print("FAIL: field not cleared, %d enemies still alive" % living)


func _sample_enemy() -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = 10
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data


func _expect(label: String, actual: float, expected: float) -> void:
	var delta := absf(wrapf(actual - expected, -PI, PI))
	if delta <= ANGLE_EPSILON:
		print("PASS: %s (%.3f rad)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s — got %.3f rad, expected %.3f rad" % [label, actual, expected])
