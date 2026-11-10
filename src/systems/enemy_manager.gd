## Owns every enemy in the run and the spatial hash used to query them.
##
## Enemies are plain Node2D nodes moved by distance math, so this manager is the
## only place that knows where they are. The index of an enemy in [member enemies]
## is its id inside the spatial hash.
class_name EnemyManager
extends Node

## All living enemies, in spawn order. An enemy's index is its spatial-hash id.
var enemies: Array[Enemy] = []

## Static props every enemy walks around, shared by the whole run. Null means
## open ground, so tests and tool scenes keep their straight-line movement.
var obstacles: ObstacleField = null

## Slack on the arc boundary, in radians. Vector2.angle_to returns a float32-
## rounded PI, so without it an enemy exactly behind the player falls a hair
## outside a 360° sweep and a target sitting on a cone's edge is a coin flip.
const ARC_EPSILON := 0.0001

var _hash := SpatialHash.new()
var _max_radius: float = 0.0


## Creates an enemy from data, adds it to container, registers it. Returns it.
## A spawn point inside a static prop is pushed out, so a trunk never hides a
## body that the weapons cannot reach. [param hp_scale] and [param damage_scale]
## are the boss-tier multipliers; the defaults build the archetype exactly as
## authored.
func spawn(
	enemy_data: EnemyData,
	at: Vector2,
	container: Node2D,
	hp_scale: float = 1.0,
	damage_scale: float = 1.0
) -> Enemy:
	var enemy := Enemy.create(enemy_data, hp_scale, damage_scale)
	enemy.position = at
	if obstacles != null:
		enemy.position = obstacles.resolve(at, enemy.radius)
	container.add_child(enemy)
	enemies.append(enemy)
	# Indexed immediately: a weapon may query in the same frame, before step_all()
	# has had a chance to rebuild the hash.
	_rebuild_hash()
	return enemy


## Steps every living enemy toward target and rebuilds the spatial hash. An enemy
## winding up a slam is rooted: the telegraph is a commitment the player can
## dodge, not decoration. When [member obstacles] is set, the frame's movement is
## slid along any prop in the way before the hash and the visuals see the
## resolved position.
func step_all(target: Vector2, delta: float) -> void:
	_hash.clear()
	_max_radius = 0.0
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy == null or enemy.hp <= 0.0:
			continue
		var before := enemy.position
		enemy.step_special(target, delta)
		if not enemy.is_telegraphing():
			enemy.step_toward(target, delta)
		if obstacles != null:
			enemy.position = obstacles.slide(before, enemy.position, enemy.radius)
		enemy.step_visual(delta)
		_hash.insert(index, enemy.position)
		_max_radius = maxf(_max_radius, enemy.radius)


## Enemies inside a cone: origin, facing angle in radians, radius, half-angle in radians.
func query_arc(origin: Vector2, facing: float, radius: float, half_angle: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var facing_vec := Vector2.RIGHT.rotated(facing)
	for id in _hash.query_circle(origin, radius + _max_radius):
		var enemy := _enemy_at(id)
		if enemy == null:
			continue
		var offset := enemy.position - origin
		# The enemy body counts toward reach, exactly as in query_circle, so a
		# target the player aims at is always a target the swing can hit.
		var reach := radius + enemy.radius
		if offset.length_squared() > reach * reach:
			continue
		# angle_to returns the shortest signed angle, wrapped to [-PI, PI], so the
		# comparison holds on both sides of the facing direction.
		if absf(offset.angle_to(facing_vec)) > half_angle + ARC_EPSILON:
			continue
		result.append(enemy)
	return result


## Nearest living enemy to a point, or null when none are alive. Unlike
## query_circle() this is not bounded by a radius: the blade tracks the closest
## threat wherever it stands in the arena.
func nearest_to(center: Vector2) -> Enemy:
	var nearest: Enemy = null
	var best := INF
	for enemy in enemies:
		if enemy == null or enemy.hp <= 0.0:
			continue
		var distance := center.distance_squared_to(enemy.position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest


## Nearest living enemy whose body is within [param radius] of a point, or null
## when nothing is in reach. This is the targeting rule of a single weapon: each
## weapon only shoots what it can actually touch.
func nearest_within(center: Vector2, radius: float) -> Enemy:
	var nearest: Enemy = null
	var best := INF
	for enemy in query_circle(center, radius):
		var distance := center.distance_squared_to(enemy.position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest


## Enemies within radius of a point.
func query_circle(center: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for id in _hash.query_circle(center, radius + _max_radius):
		var enemy := _enemy_at(id)
		if enemy == null:
			continue
		var reach := radius + enemy.radius
		if center.distance_squared_to(enemy.position) > reach * reach:
			continue
		result.append(enemy)
	return result


## Frees dead enemies and drops their loot via the provided callback, called with
## (position, xp_value, enemy_data). Returns the total XP dropped.
func remove_dead(on_drop: Callable) -> int:
	var total_xp := 0
	var survivors: Array[Enemy] = []
	for enemy in enemies:
		if enemy == null:
			continue
		if enemy.hp > 0.0:
			survivors.append(enemy)
			continue
		var xp_value := 0
		if enemy.data != null:
			xp_value = enemy.data.xp_value
		total_xp += xp_value
		if on_drop.is_valid():
			on_drop.call(enemy.position, xp_value, enemy.data)
		# The body squashes and fades where it fell. The fade is a plain Node2D in
		# the same container as the enemies, so it draws at their depth while never
		# entering the spatial hash and never being targetable.
		var parent: Node = enemy.get_parent()
		if enemy.data != null and parent != null:
			var fade := DeathFade.create(enemy.data.art, enemy.radius, enemy.data.color)
			fade.position = enemy.position
			parent.add_child(fade)
		enemy.queue_free()
	enemies = survivors
	# Indices moved while compacting, so the old ids would point at the wrong nodes.
	_rebuild_hash()
	return total_xp


## Number of enemies currently registered.
func count() -> int:
	return enemies.size()


## Clears the hash and inserts every living enemy at its current position.
func _rebuild_hash() -> void:
	_hash.clear()
	_max_radius = 0.0
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy == null or enemy.hp <= 0.0:
			continue
		_hash.insert(index, enemy.position)
		_max_radius = maxf(_max_radius, enemy.radius)


## Returns the living enemy for a hash id, or null when the id is stale.
func _enemy_at(id: int) -> Enemy:
	if id < 0 or id >= enemies.size():
		return null
	var enemy := enemies[id]
	if enemy == null or enemy.hp <= 0.0:
		return null
	return enemy
