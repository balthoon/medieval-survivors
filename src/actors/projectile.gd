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

## Enemies this bolt has already hit. Only a piercing bolt can meet the same
## body twice, and it must not repeat the hit.
var _hit_enemies: Array[Enemy] = []
## Living enemies already pierced by this bolt: the rank of the next hit. Dead
## enemies never reach this counter (GDD edge case E4).
var _pierce_rank: int = 0


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
	return bolt


## Moves the bolt, resolves the enemies it reaches, and returns true when the
## bolt is spent. A plain bolt is spent on its first victim; a piercing one
## keeps flying until its range runs out.
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
			for enemy in hits:
				if enemy == null or _hit_enemies.has(enemy):
					continue
				_resolve_hit(enemy)
				_hit_enemies.append(enemy)
				if weapon.mechanic != &"pierce":
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
	var amount := mechanic_damage(
		weapon, float(hit["amount"]), travelled, stats.weapon_range(weapon), _pierce_rank
	)
	var is_crit := bool(hit["is_crit"])
	if weapon.mechanic == &"pierce":
		_pierce_rank += 1
	enemy.take_damage(amount, is_crit)
	enemy.apply_knockback(position - direction * LENGTH, weapon.knockback)
	hit_resolved.emit(amount, is_crit, enemy.position)


## Applies the mechanic's damage rule to one rolled hit. Pure math on purpose:
## the bow's range bonus (GDD F6) and the crossbow's falloff (GDD F8) are
## unit-tested without a scene.
##
## [param pierce_rank] is the number of living enemies already pierced by this
## bolt, so the first victim is rank 0 and keeps the full damage.
static func mechanic_damage(
	from_weapon: WeaponData,
	amount: float,
	travelled: float,
	max_range: float,
	pierce_rank: int
) -> float:
	if from_weapon == null:
		return amount
	match from_weapon.mechanic:
		&"distance":
			var ratio := clampf(travelled / maxf(max_range, 1.0), 0.0, 1.0)
			return amount * (1.0 + from_weapon.distance_damage_bonus * ratio)
		&"pierce":
			return amount * pow(from_weapon.pierce_falloff, pierce_rank)
	return amount


## Draws the bolt pointing along its direction of travel. In local space +x is
## forward, which is where step() puts it with [member Node2D.rotation].
##
## An arrow, not a dart: a dark shaft reads against the pale grass where a pale
## one vanishes at this size, and the fletching tells the player which way it is
## going even when the head is already inside an enemy.
func _draw() -> void:
	var colour := Color(0.72, 0.74, 0.78)
	if weapon != null:
		colour = weapon.color

	var back := -LENGTH * 0.5
	InkStyle.detail(self, Vector2(back + 1.0, 0.0), Vector2(LENGTH * 0.16, 0.0), 2.0, ActorArt.WOOD)
	InkStyle.detail(
		self, Vector2(back + 2.0, 0.0), Vector2(back + 6.5, -3.0), 1.4, ActorArt.BONE
	)
	InkStyle.detail(
		self, Vector2(back + 2.0, 0.0), Vector2(back + 6.5, 3.0), 1.4, ActorArt.BONE
	)

	InkStyle.outlined(self, PackedVector2Array([
		Vector2(1.0, -2.6),
		Vector2(LENGTH * 0.5, 0.0),
		Vector2(1.0, 2.6),
	]), colour, 1.2)
