## One fired bolt. A plain Node2D moved by distance math, like the enemies.
##
## The weapon system owns the loop: it calls step() every frame and frees the
## bolt once step() reports it spent. Collision is a radius query against the
## enemy manager, not a physics body.
class_name Projectile
extends Node2D

## Emitted after a hit lands, with the rolled damage, whether it was a crit, and
## the enemy position at impact.
signal hit_resolved(amount: float, is_crit: bool, at: Vector2)

## Hit radius of the bolt, in pixels.
const RADIUS := 7.0

## Length of the drawn bolt, in pixels.
const LENGTH := 16.0

## Weapon the bolt was fired from. Copied so a later inventory change cannot
## alter a bolt already in flight.
var weapon: WeaponData = null
## Player stats at the moment of firing.
var stats: Stats = null
## Roll source shared with the run, for deterministic crits.
var rng: RandomNumberGenerator = null
## Unit direction of travel.
var direction: Vector2 = Vector2.RIGHT
## Distance travelled so far, in pixels.
var travelled: float = 0.0


## Builds a bolt travelling from [param from] along [param dir]. Returns it
## unattached.
static func create(
	fired_weapon: WeaponData,
	from_stats: Stats,
	from_rng: RandomNumberGenerator,
	from: Vector2,
	dir: Vector2
) -> Projectile:
	var bolt := Projectile.new()
	bolt.weapon = fired_weapon
	bolt.stats = from_stats
	bolt.rng = from_rng
	bolt.position = from
	bolt.direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	bolt._build_visual()
	return bolt


## Moves the bolt, resolves the first enemy it reaches, and returns true when
## the bolt is spent (hit something, or flew its full range).
##
## The move is split into sub-steps no longer than RADIUS. A bolt covers 10 px
## at 60 fps but far more on a slow frame, and a single jump can land past an
## enemy without ever being inside it — the sub-steps make the bolt sweep the
## ground it crosses instead of sampling a point.
func step(delta: float, enemy_manager: EnemyManager) -> bool:
	if weapon == null or stats == null or rng == null:
		return true

	rotation = direction.angle()
	var distance := weapon.projectile_speed * delta
	var sub_steps := maxi(1, int(ceilf(distance / RADIUS)))
	var step_length := distance / float(sub_steps)
	var max_range := stats.weapon_range(weapon)

	for _index in sub_steps:
		position += direction * step_length
		travelled += step_length

		if enemy_manager != null:
			var hits := enemy_manager.query_circle(position, RADIUS)
			if not hits.is_empty():
				_resolve_hit(hits[0])
				return true

		if travelled >= max_range:
			return true

	return false


## Applies the rolled damage and the knockback to one enemy, then reports the
## resolved hit so the weapon system can add numbers, sound and hitstop.
func _resolve_hit(enemy: Enemy) -> void:
	if enemy == null:
		return
	var hit := DamageCalc.roll(stats, weapon, rng)
	var amount := float(hit["amount"])
	var is_crit := bool(hit["is_crit"])
	enemy.take_damage(amount, is_crit)
	enemy.apply_knockback(position - direction * LENGTH, weapon.knockback)
	hit_resolved.emit(amount, is_crit, enemy.position)


## Draws the bolt, once.
func _build_visual() -> void:
	var colour := Color(0.72, 0.74, 0.78)
	if weapon != null:
		colour = weapon.color

	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-LENGTH * 0.5, -1.6),
		Vector2(LENGTH * 0.2, -1.6),
		Vector2(LENGTH * 0.5, 0.0),
		Vector2(LENGTH * 0.2, 1.6),
		Vector2(-LENGTH * 0.5, 1.6),
	])
	shaft.color = colour
	add_child(shaft)
