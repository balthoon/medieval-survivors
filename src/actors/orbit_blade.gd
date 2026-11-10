## One orbiting moon: the gameplay node behind the `orbit` mechanic.
##
## It is never fired and has no cooldown of its own. It circles the player,
## damages every enemy it touches, and remembers both the current revolution and
## the last contact so one enemy is never hit twice in the same turn (GDD edge
## case E2). WeaponSystem owns it beside the other weapon nodes.
##
## [member range_mult] grows the ring radius, never the contact radius: a range
## upgrade moves the moon outward, it does not make it fatter (GDD edge case
## E20).
class_name OrbitBlade
extends Node2D

## Emitted after every contact that landed, so WeaponSystem can add the damage
## number, the sound and the shared hit signal.
signal hit_landed(is_crit: bool, amount: float, at: Vector2)

## Contact radius of the moon, in pixels. The enemy body radius is added by the
## manager query, exactly as for a swing.
const CONTACT_RADIUS := 12.0

## Radius the moon is drawn at, in pixels.
const DRAW_RADIUS := 9.0

## Weapon this moon belongs to. Set by setup().
var weapon: WeaponData = null
## Player statistics, for damage and ring radius. Set by setup().
var stats: Stats = null
## Roll source shared with the run, so crits stay deterministic. Set by setup().
var rng: RandomNumberGenerator = null
## Node the moon orbits. Set by setup().
var player: Player = null
## Source of enemies. Set by setup().
var enemy_manager: EnemyManager = null

## Current angle around the player, in radians. Zero points right.
var _angle: float = 0.0
## Seconds before each enemy may be hit again, keyed by enemy instance.
var _hit_cooldowns: Dictionary = {}
## Enemies already hit during the current revolution.
var _turn_hits: Array[Enemy] = []


## Wires the moon. Call once when the weapon enters the inventory.
func setup(
	orbit_weapon: WeaponData,
	run_stats: Stats,
	run_rng: RandomNumberGenerator,
	run_player: Player,
	run_enemy_manager: EnemyManager
) -> void:
	weapon = orbit_weapon
	stats = run_stats
	rng = run_rng
	player = run_player
	enemy_manager = run_enemy_manager
	queue_redraw()


## Advances the orbit, ticks every per-enemy cooldown and strikes whatever the
## moon is currently touching.
func step(delta: float) -> void:
	if weapon == null or stats == null or player == null:
		return

	var spin := weapon.orbit_speed * delta
	if _angle + spin >= TAU:
		# A new revolution starts: an enemy already hit is eligible again.
		_turn_hits.clear()
	_angle = fmod(_angle + spin, TAU)
	position = Vector2.RIGHT.rotated(_angle) * weapon.orbit_radius * stats.range_mult

	for enemy in _hit_cooldowns.keys():
		var left := float(_hit_cooldowns[enemy]) - delta
		if left <= 0.0:
			_hit_cooldowns.erase(enemy)
		else:
			_hit_cooldowns[enemy] = left

	if enemy_manager == null:
		return

	# The moon is a child of the player, so its own position is local. The enemy
	# manager holds world positions: query with global_position or the ring is
	# tested against the arena origin instead of the player.
	for enemy in enemy_manager.query_circle(global_position, CONTACT_RADIUS):
		if enemy == null or enemy.hp <= 0.0:
			continue
		# The stricter of "once per turn" and "once per cooldown" wins.
		if _turn_hits.has(enemy) or _hit_cooldowns.has(enemy):
			continue
		_strike(enemy)


## Applies one contact and records it against both limits.
func _strike(enemy: Enemy) -> void:
	var hit := DamageCalc.roll(stats, weapon, rng)
	var amount := float(hit["amount"])
	var is_crit := bool(hit["is_crit"])
	enemy.take_damage(amount, is_crit)
	enemy.apply_knockback(global_position, weapon.knockback)
	_turn_hits.append(enemy)
	_hit_cooldowns[enemy] = maxf(weapon.orbit_hit_cooldown, 0.01)
	hit_landed.emit(is_crit, amount, enemy.position)


## Draws the moon: an ink-rimmed disc with one lit edge, in the weapon's colour.
func _draw() -> void:
	if weapon == null:
		return
	InkStyle.circle(self, Vector2.ZERO, DRAW_RADIUS, weapon.color, 1.6)
	InkStyle.circle(
		self, Vector2(-2.4, -2.4), 2.6, InkStyle.light_of(weapon.color, 0.42), 0.8
	)
