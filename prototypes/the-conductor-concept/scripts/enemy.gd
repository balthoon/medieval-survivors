# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09
#
# Enemy: flat-colour Polygon2D body built in code. No physics nodes - movement
# and collision are distance checks driven by main.gd.

class_name ProtoEnemy
extends Node2D

var RADIUS := 13.0        # must be a var, each kind sets it
var speed: float
var hp: int
var kind: String

var _max_hp: int = 1
var _body: Polygon2D


## Build an enemy of the requested kind at `at`.
static func create(kind_name: String, at: Vector2) -> ProtoEnemy:
	var e := ProtoEnemy.new()
	e.position = at
	e.kind = kind_name
	match kind_name:
		"fast":
			e.speed = 150.0
			e.RADIUS = 10.0
			e.hp = 1
			e._build_visual(Color(0.85, 0.65, 0.15))
		"tank":
			e.speed = 55.0
			e.RADIUS = 20.0
			e.hp = 3
			e._build_visual(Color(0.18, 0.16, 0.14))
		_:
			e.kind = "chaser"
			e.speed = 85.0
			e.RADIUS = 13.0
			e.hp = 1
			e._build_visual(Color(0.75, 0.20, 0.14))
	e._max_hp = e.hp
	return e


## Apply damage. Returns true when this hit killed the enemy.
func take_damage(amount: int) -> bool:
	hp -= amount
	if hp <= 0:
		return true
	_update_visual_health()
	return false


## Move `speed` pixels per second toward `target`. Plain arithmetic, no physics.
func step_toward(target: Vector2, delta: float) -> void:
	var to := target - position
	var dist := to.length()
	if dist > 0.001:
		position += to / dist * speed * delta


func _build_visual(tint: Color) -> void:
	_body = Polygon2D.new()
	_body.name = "Body"
	_body.color = tint
	_body.polygon = _shape_points()
	add_child(_body)


func _shape_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	match kind:
		"fast":  # diamond
			pts.append(Vector2(0.0, -RADIUS))
			pts.append(Vector2(RADIUS, 0.0))
			pts.append(Vector2(0.0, RADIUS))
			pts.append(Vector2(-RADIUS, 0.0))
		"tank":  # octagon
			for i in 8:
				var a := TAU * float(i) / 8.0
				pts.append(Vector2(cos(a), sin(a)) * RADIUS)
		_:  # chaser square
			pts.append(Vector2(-RADIUS, -RADIUS))
			pts.append(Vector2(RADIUS, -RADIUS))
			pts.append(Vector2(RADIUS, RADIUS))
			pts.append(Vector2(-RADIUS, RADIUS))
	return pts


func _update_visual_health() -> void:
	if _body == null:
		return
	# Shrink the body a little as it takes damage so multi-hp tanks read as wounded.
	var ratio := float(maxi(hp, 0)) / float(maxi(_max_hp, 1))
	_body.scale = Vector2.ONE * (0.74 + 0.26 * ratio)
