# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09

class_name ProtoPlayer
extends Node2D

## Player avatar: moves inside the arena and casts an area burst.
## Owns only its cooldown and burst-ring visuals; main.gd wires input to it.

const RADIUS := 14.0
const SPEED := 240.0
const CAST_COOLDOWN := 0.35

const BASE_BURST_RADIUS := 110.0
const BASE_DAMAGE := 1
const ON_BEAT_RADIUS_MULT := 1.6
const ON_BEAT_DAMAGE_MULT := 2

const ARENA_MIN := Vector2(40.0, 40.0)
const ARENA_MAX := Vector2(1240.0, 680.0)

const RING_DURATION := 0.28

var _cooldown_left: float = 0.0
var _ring_time: float = 0.0
var _ring_radius: float = 0.0
var _ring_color: Color = Color(0.85, 0.85, 0.95)


func _process(delta: float) -> void:
	var dirty := false
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
		dirty = true
	if _ring_time > 0.0:
		_ring_time = maxf(_ring_time - delta, 0.0)
		dirty = true
	if dirty:
		queue_redraw()


## Moves the player along `dir` (any length) for `delta`, clamped to the arena.
func move(dir: Vector2, delta: float) -> void:
	if dir.length_squared() > 0.0:
		position += dir.normalized() * SPEED * delta
	position = position.clamp(ARENA_MIN, ARENA_MAX)


## True when the cast cooldown has elapsed.
func can_cast() -> bool:
	return _cooldown_left <= 0.0


## Area burst centred on the player. Returns how many enemies it hit.
## On the beat the burst is larger and hits harder; either way the cooldown
## starts and a ring is drawn. An off-beat cast is not a failure.
func cast(on_beat: bool, enemies: Array) -> int:
	if not can_cast():
		return 0

	var radius := BASE_BURST_RADIUS
	var damage := BASE_DAMAGE
	if on_beat:
		radius *= ON_BEAT_RADIUS_MULT
		damage *= ON_BEAT_DAMAGE_MULT

	var hit_count := 0
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var enemy_radius: float = 0.0
		var radius_prop: Variant = enemy.get("RADIUS")
		if radius_prop != null:
			enemy_radius = float(radius_prop)
		var distance := global_position.distance_to((enemy as Node2D).global_position)
		if distance <= radius + enemy_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			hit_count += 1

	_cooldown_left = CAST_COOLDOWN
	_ring_time = RING_DURATION
	_ring_radius = radius
	_ring_color = Color(1.0, 0.80, 0.25) if on_beat else Color(0.85, 0.85, 0.95)
	queue_redraw()
	return hit_count


func _draw() -> void:
	# Cooldown pip: a thin arc around the body that fills as the cast recharges.
	if _cooldown_left > 0.0:
		var ready_ratio := 1.0 - _cooldown_left / CAST_COOLDOWN
		var pip_radius := RADIUS + 7.0
		draw_arc(
			Vector2.ZERO,
			pip_radius,
			-PI * 0.5,
			-PI * 0.5 + TAU * ready_ratio,
			32,
			Color(1.0, 0.95, 0.75, 0.55),
			2.0,
			true
		)

	# Burst ring: fixed at the burst radius, fading over RING_DURATION.
	# 4.7 draws thinner lines with no AA feather, so keep the width generous.
	if _ring_time > 0.0:
		var alpha := _ring_time / RING_DURATION
		var ring := _ring_color
		ring.a = 0.85 * alpha
		var fill := _ring_color
		fill.a = 0.12 * alpha
		draw_circle(Vector2.ZERO, _ring_radius, fill, true, -1.0, true)
		draw_arc(Vector2.ZERO, _ring_radius, 0.0, TAU, 64, ring, 4.0, true)
