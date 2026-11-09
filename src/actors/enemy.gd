## One enemy. A plain Node2D: movement and hit tests are distance math, so the
## enemy manager owns the spatial hash instead of the physics server.
class_name Enemy extends Node2D

## Emitted on a boss the frame its ground slam lands, with the impact centre, the
## radius and the scaled damage. main.gd is the only listener: the enemy knows
## nothing about the player.
signal slam_struck(at: Vector2, radius: float, damage: float)

## Seconds a hit flash lasts.
const FLASH_DURATION := 0.08

## Colour the body flashes on a normal hit.
const HIT_FLASH := Color(1.0, 1.0, 1.0)

## Colour the body flashes on a critical hit.
const CRIT_FLASH := Color(0.95, 0.78, 0.25)

## Distance an enemy is pushed away from the attacker on each hit.
const KNOCKBACK_DISTANCE := 28.0

## Ink rim drawn around every enemy, in pixels. On a grassy floor the body colour
## of the wolf is close to the lawn, so the rim is what keeps the silhouette
## readable; it must never flash with the body.
const RIM_WIDTH := 2.0

## Colour of the rim. Same ink as the rest of the game.
const RIM_COLOR := Color(0.16, 0.14, 0.12)

## Colour of the ground-slam telegraph. Danger red, translucent: it must be
## unmistakable over green grass without hiding the enemies behind it.
const TELEGRAPH_COLOR := Color(0.75, 0.20, 0.14)

## Number of sides of the telegraph disc. Few enough to stay cheap, many enough
## that the edge reads as a circle.
const TELEGRAPH_SEGMENTS := 32

## Scale the telegraph starts at, as a fraction of its final radius.
const TELEGRAPH_MIN_SCALE := 0.15

## Alpha of the telegraph at the start and at the moment of impact.
const TELEGRAPH_MIN_ALPHA := 0.22
const TELEGRAPH_MAX_ALPHA := 0.55

## Tuning data this enemy was built from.
var data: EnemyData = null
## Current hit points.
var hp: float = 1.0
## Maximum hit points for this instance, already scaled by the boss tier.
var max_hp: float = 1.0
## Body radius, copied from data.
var radius: float = 13.0
## Contact damage for this instance, already scaled by the boss tier.
var contact_damage: float = 0.0
## Slam damage for this instance, already scaled by the boss tier. Zero on a
## plain enemy.
var slam_damage: float = 0.0
## Radius of the ground slam, in pixels. Zero on a plain enemy.
var slam_radius: float = 0.0
## Seconds until this enemy may deal contact damage again.
var contact_cooldown: float = 0.0

## The diamond drawn for this enemy, recoloured during a hit flash.
var _visual: Polygon2D = null
## Seconds left in the current hit flash.
var _flash_time: float = 0.0
## Colour the current flash set; the archetype colour returns when it ends.
var _flash_color: Color = HIT_FLASH
## The danger disc drawn under the body while a slam is winding up. Null when the
## archetype has no slam.
var _telegraph: Polygon2D = null
## Seconds left of the current windup; zero when not winding up.
var _windup_left: float = 0.0
## Total length of the windup that is running, for the disc's growth curve.
var _windup_total: float = 0.0
## Seconds until the next slam may start winding up.
var _slam_cooldown: float = 0.0


## Builds a complete enemy node, visual included, from data. Returns it unattached.
## [param hp_scale] and [param damage_scale] are the boss-tier multipliers; a
## plain enemy uses the defaults and is exactly its archetype.
static func create(
	enemy_data: EnemyData, hp_scale: float = 1.0, damage_scale: float = 1.0
) -> Enemy:
	var enemy := Enemy.new()
	enemy.data = enemy_data
	enemy.max_hp = float(enemy_data.max_hp) * hp_scale
	enemy.hp = enemy.max_hp
	enemy.radius = enemy_data.radius
	enemy.contact_damage = enemy_data.contact_damage * damage_scale
	enemy.slam_damage = enemy_data.slam_damage * damage_scale
	enemy.slam_radius = enemy_data.slam_radius

	# Added before the rim so the disc is painted under the body and the rim.
	if enemy_data.slam_damage > 0.0 and enemy_data.slam_radius > 0.0:
		var telegraph := Polygon2D.new()
		telegraph.polygon = _circle(enemy_data.slam_radius)
		telegraph.color = TELEGRAPH_COLOR
		telegraph.modulate.a = TELEGRAPH_MIN_ALPHA
		telegraph.visible = false
		enemy.add_child(telegraph)
		enemy._telegraph = telegraph

	var rim := Polygon2D.new()
	rim.polygon = _diamond(enemy_data.radius + RIM_WIDTH)
	rim.color = RIM_COLOR
	enemy.add_child(rim)

	var visual := Polygon2D.new()
	visual.polygon = _diamond(enemy_data.radius)
	visual.color = enemy_data.color
	enemy.add_child(visual)
	enemy._visual = visual
	return enemy


## Builds the diamond body of one enemy at the given radius.
static func _diamond(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
	])


## Builds a circle polygon of the given radius, used by the slam telegraph.
static func _circle(radius: float, segments: int = TELEGRAPH_SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / float(segments)) * radius)
	return points


## Moves toward target at data.move_speed.
func step_toward(target: Vector2, delta: float) -> void:
	if data == null:
		return
	var offset := target - position
	if offset.length_squared() > 0.0:
		position += offset.normalized() * data.move_speed * delta


## Pushes the enemy away from a point by the given distance. Knockback is
## feedback, not physics: it has no collision response and no wall handling.
## An archetype's knockback_resistance cuts the distance it actually travels.
func apply_knockback(from_point: Vector2, distance: float) -> void:
	var offset := position - from_point
	if offset.length_squared() <= 0.0:
		return
	var resistance := 0.0
	if data != null:
		resistance = clampf(data.knockback_resistance, 0.0, 1.0)
	var pushed := distance * (1.0 - resistance)
	if pushed <= 0.0:
		return
	position += offset.normalized() * pushed


## Advances the ground slam. Returns nothing: the blow is reported through the
## slam_struck signal, so the caller stays the only thing that can hurt the
## player. [param target] is the position the slam aims at (the player).
##
## The cycle is: cooldown ticks down; once it is spent and the target is inside
## slam range, the telegraph disc grows for slam_telegraph seconds; then the blow
## lands and the cooldown restarts.
func step_special(target: Vector2, delta: float) -> void:
	if data == null or slam_damage <= 0.0 or slam_radius <= 0.0:
		return

	if _windup_left > 0.0:
		_windup_left = maxf(_windup_left - delta, 0.0)
		_update_telegraph()
		if _windup_left <= 0.0:
			_strike()
		return

	_slam_cooldown = maxf(_slam_cooldown - delta, 0.0)
	if _slam_cooldown > 0.0:
		return
	if position.distance_to(target) > slam_radius:
		return
	_start_windup()


## True while the enemy is rooted, winding up a slam. The manager skips its
## movement for those frames, so the telegraph marks a real commitment.
func is_telegraphing() -> bool:
	return _windup_left > 0.0


## Fraction of the current windup already elapsed, in 0..1. Used by tests and by
## the HUD if it ever wants to mirror the disc.
func windup_progress() -> float:
	if _windup_total <= 0.0:
		return 0.0
	return clampf(1.0 - _windup_left / _windup_total, 0.0, 1.0)


## Begins a windup and shows the disc at its smallest.
func _start_windup() -> void:
	_windup_total = maxf(data.slam_telegraph, 0.05)
	_windup_left = _windup_total
	if _telegraph != null:
		_telegraph.visible = true
		_telegraph.scale = Vector2.ONE * TELEGRAPH_MIN_SCALE
		_telegraph.modulate.a = TELEGRAPH_MIN_ALPHA


## Grows the disc as the windup runs out.
func _update_telegraph() -> void:
	if _telegraph == null:
		return
	var progress := windup_progress()
	var scale := lerpf(TELEGRAPH_MIN_SCALE, 1.0, progress)
	_telegraph.scale = Vector2.ONE * scale
	_telegraph.modulate.a = lerpf(TELEGRAPH_MIN_ALPHA, TELEGRAPH_MAX_ALPHA, progress)


## Lands the blow: hides the disc, restarts the cooldown and reports the strike.
func _strike() -> void:
	if _telegraph != null:
		_telegraph.visible = false
	_slam_cooldown = maxf(data.slam_cooldown, 0.0)
	slam_struck.emit(position, slam_radius, slam_damage)


## Applies damage and flashes the visual — gold on a crit, white otherwise.
## Returns true when this hit was the one that killed the enemy.
func take_damage(amount: float, is_crit: bool = false) -> bool:
	if hp <= 0.0:
		return false
	hp = maxf(hp - amount, 0.0)
	_flash_time = FLASH_DURATION
	_flash_color = CRIT_FLASH if is_crit else HIT_FLASH
	if _visual != null:
		_visual.color = _flash_color
	return hp <= 0.0


## Advances the hit flash back to the archetype colour. Called every frame by the
## enemy manager.
func step_visual(delta: float) -> void:
	if _flash_time <= 0.0:
		return
	_flash_time = maxf(_flash_time - delta, 0.0)
	if _flash_time <= 0.0 and _visual != null and data != null:
		_visual.color = data.color
