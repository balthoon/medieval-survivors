## Floating combat feedback: damage numbers and enemy death shards.
##
## Every effect is prebuilt once in _ready() and hidden, then reused round-robin:
## a busy wave spawns dozens of numbers per second, and allocating a Label per
## hit would stutter the very frame that caused it. main.gd adds this node once.
class_name Fx
extends Node2D

## Number of floating damage labels kept in the pool.
const NUMBER_POOL_SIZE := 24

## Number of death-shard polygons kept in the pool.
const SHARD_POOL_SIZE := 24

## Shards spawned by one enemy death.
const SHARDS_PER_DEATH := 4

## Seconds a normal damage number lives.
const NUMBER_LIFE := 0.45

## Seconds a critical damage number lives.
const CRIT_LIFE := 0.55

## Pixels a normal damage number rises over its life.
const NUMBER_RISE := 46.0

## Pixels a critical damage number rises over its life.
const CRIT_RISE := 64.0

## Fraction of a number's life after which it starts fading out.
const FADE_START := 0.6

## Font size of a normal damage number.
const FONT_SIZE := 16

## Font size of a critical damage number.
const CRIT_FONT_SIZE := 22

## Colour of a normal damage number.
const NUMBER_COLOR := Color(0.16, 0.14, 0.12)

## Colour of a critical damage number.
const CRIT_COLOR := Color(0.72, 0.52, 0.08)

## Ink outline drawn around every damage number. On a grassy floor the number
## colour alone is low contrast, so the outline carries the readability.
const OUTLINE_COLOR := Color(0.16, 0.14, 0.12)

## Outline thickness of a damage number, in pixels.
const OUTLINE_SIZE := 4

## Box each damage number is centred in, in pixels.
const NUMBER_BOX := Vector2(90.0, 28.0)

## Seconds a death shard lives.
const SHARD_LIFE := 0.35

## Gravity pulling death shards down, in pixels per second squared.
const SHARD_GRAVITY := 220.0

## Lowest initial shard speed, in pixels per second.
const SHARD_SPEED_MIN := 60.0

## Highest initial shard speed, in pixels per second.
const SHARD_SPEED_MAX := 140.0

## Smallest shard side, in pixels.
const SHARD_SIZE_MIN := 4.0

## Largest shard side, in pixels.
const SHARD_SIZE_MAX := 6.0

## Pooled labels, hidden until used.
var _labels: Array[Label] = []
## Pooled shard polygons, hidden until used.
var _shards: Array[Polygon2D] = []
## Runtime state of each label, index-aligned with _labels.
var _number_states: Array[Dictionary] = []
## Runtime state of each shard, index-aligned with _shards.
var _shard_states: Array[Dictionary] = []
## Round-robin cursor into the label pool.
var _next_number := 0
## Round-robin cursor into the shard pool.
var _next_shard := 0
## Roll source for shard directions, randomized once.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_pools()


## Spawns one floating damage number over [param at]. Critical hits are bigger,
## gold, rise further and live longer.
func spawn_number(at: Vector2, amount: float, is_crit: bool) -> void:
	_ensure_pools()
	var label := _labels[_next_number]
	var state := _number_states[_next_number]
	_next_number = (_next_number + 1) % NUMBER_POOL_SIZE

	var colour := CRIT_COLOR if is_crit else NUMBER_COLOR
	label.text = "%d" % int(round(amount))
	label.add_theme_font_size_override("font_size", CRIT_FONT_SIZE if is_crit else FONT_SIZE)
	label.modulate = colour
	label.size = NUMBER_BOX
	label.position = at - NUMBER_BOX * 0.5
	label.visible = true

	state["active"] = true
	state["age"] = 0.0
	state["life"] = CRIT_LIFE if is_crit else NUMBER_LIFE
	state["rise"] = CRIT_RISE if is_crit else NUMBER_RISE
	state["start"] = label.position
	state["color"] = colour


## Spawns four small shards at [param at], thrown in random directions and
## tinted [param color]. Used when an enemy dies.
func spawn_shards(at: Vector2, color: Color) -> void:
	_ensure_pools()
	for _count in SHARDS_PER_DEATH:
		var slot := _next_free_shard()
		var shard := _shards[slot]
		var state := _shard_states[slot]
		var size := _rng.randf_range(SHARD_SIZE_MIN, SHARD_SIZE_MAX)
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -size),
			Vector2(size * 0.9, size * 0.7),
			Vector2(-size * 0.9, size * 0.7),
		])
		shard.color = color
		shard.position = at
		shard.rotation = _rng.randf_range(0.0, TAU)
		shard.visible = true

		state["active"] = true
		state["age"] = 0.0
		state["velocity"] = (
			Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
			* _rng.randf_range(SHARD_SPEED_MIN, SHARD_SPEED_MAX)
		)
		state["color"] = color


func _process(delta: float) -> void:
	_step_numbers(delta)
	_step_shards(delta)


## Advances every active damage number, then hides the finished ones.
func _step_numbers(delta: float) -> void:
	for index in _labels.size():
		var state := _number_states[index]
		if not bool(state["active"]):
			continue

		var age := float(state["age"]) + delta
		var life := float(state["life"])
		if age >= life:
			state["active"] = false
			_labels[index].visible = false
			continue

		state["age"] = age
		var label := _labels[index]
		var t := age / life
		var start: Vector2 = state["start"]
		label.position = start - Vector2(0.0, float(state["rise"]) * t)

		var colour: Color = state["color"]
		var alpha := 1.0
		if t > FADE_START:
			alpha = 1.0 - (t - FADE_START) / (1.0 - FADE_START)
		label.modulate = Color(colour.r, colour.g, colour.b, alpha)


## Advances every active shard under gravity, then hides the finished ones.
func _step_shards(delta: float) -> void:
	for index in _shards.size():
		var state := _shard_states[index]
		if not bool(state["active"]):
			continue

		var age := float(state["age"]) + delta
		if age >= SHARD_LIFE:
			state["active"] = false
			_shards[index].visible = false
			continue

		state["age"] = age
		var velocity: Vector2 = state["velocity"]
		velocity.y += SHARD_GRAVITY * delta
		state["velocity"] = velocity

		var shard := _shards[index]
		shard.position += velocity * delta
		var colour: Color = state["color"]
		shard.color = Color(colour.r, colour.g, colour.b, 1.0 - age / SHARD_LIFE)


## Creates both pools once. Safe to call from _ready() and lazily before it.
func _build_pools() -> void:
	if not _labels.is_empty():
		return

	for _index in NUMBER_POOL_SIZE:
		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = NUMBER_BOX
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		add_child(label)
		_labels.append(label)
		_number_states.append({
			"active": false,
			"age": 0.0,
			"life": 0.0,
			"rise": 0.0,
			"start": Vector2.ZERO,
			"color": Color.WHITE,
		})

	for _index in SHARD_POOL_SIZE:
		var shard := Polygon2D.new()
		shard.visible = false
		add_child(shard)
		_shards.append(shard)
		_shard_states.append({
			"active": false,
			"age": 0.0,
			"velocity": Vector2.ZERO,
			"color": Color.WHITE,
		})


## Builds the pools if a spawn call beat _ready().
func _ensure_pools() -> void:
	if _labels.is_empty():
		_build_pools()


## Returns the next free shard slot, or reuses the round-robin one when the
## whole pool is busy.
func _next_free_shard() -> int:
	for offset in SHARD_POOL_SIZE:
		var index := (_next_shard + offset) % SHARD_POOL_SIZE
		if not bool(_shard_states[index]["active"]):
			_next_shard = (index + 1) % SHARD_POOL_SIZE
			return index
	var fallback := _next_shard
	_next_shard = (_next_shard + 1) % SHARD_POOL_SIZE
	return fallback
