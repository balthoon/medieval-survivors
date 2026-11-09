# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09
#
# Spawner: density-only difficulty. The spawn interval tightens with elapsed
# time and the kind mix widens at 60 s and 120 s. Enemy hp and speed never
# change with time.

class_name ProtoSpawner
extends Node2D

const ARENA_MIN := Vector2(40.0, 40.0)
const ARENA_MAX := Vector2(1240.0, 680.0)
const MIN_SPAWN_DISTANCE := 220.0
const SPAWN_ATTEMPTS := 24

var _accumulator: float = 0.0
var _last_elapsed: float = 0.0


## Advance the spawner. Call every frame from main.gd while the player is alive.
func tick(elapsed: float, container: Node2D, player_pos: Vector2) -> void:
	if container == null:
		return
	var delta := elapsed - _last_elapsed
	_last_elapsed = elapsed
	if delta < 0.0:
		delta = 0.0
	_accumulator += delta

	var interval: float = clampf(1.2 - elapsed * 0.004, 0.28, 1.2)
	while _accumulator >= interval:
		_accumulator -= interval
		_spawn_one(elapsed, container, player_pos)


func _spawn_one(elapsed: float, container: Node2D, player_pos: Vector2) -> void:
	var kind_name := _pick_kind(elapsed)
	var spawn_pos := _pick_spawn_position(player_pos)
	var enemy := ProtoEnemy.create(kind_name, spawn_pos)
	container.add_child(enemy)


func _pick_kind(elapsed: float) -> String:
	var roll := randf()
	if elapsed < 60.0:
		return "chaser"
	if elapsed < 120.0:
		return "fast" if roll < 0.30 else "chaser"
	# 55 / 25 / 20 chaser / fast / tank
	if roll < 0.20:
		return "tank"
	if roll < 0.45:
		return "fast"
	return "chaser"


func _pick_spawn_position(player_pos: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var best_dist_sq := -1.0
	var min_sq := MIN_SPAWN_DISTANCE * MIN_SPAWN_DISTANCE
	for _attempt in SPAWN_ATTEMPTS:
		var p := _random_border_point()
		var d := p.distance_squared_to(player_pos)
		if d > best_dist_sq:
			best_dist_sq = d
			best = p
		if d >= min_sq:
			return p
	return best


func _random_border_point() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MIN.y)
		1:
			return Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MAX.y)
		2:
			return Vector2(ARENA_MIN.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))
		_:
			return Vector2(ARENA_MAX.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))
