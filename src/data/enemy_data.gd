## Enemy archetype: health, movement, contact damage and spawn weight.
##
## Values live in .tres resources under res://data/enemies/.
class_name EnemyData
extends Resource

## Name used by debug output and future UI.
@export var display_name: String = ""
## Maximum hit points.
@export var max_hp: int = 12
## Movement speed in pixels per second.
@export var move_speed: float = 70.0
## Collision and drawing radius in pixels.
@export var radius: float = 13.0
## Body colour used by the enemy visual.
@export var color: Color = Color(0.75, 0.20, 0.14)
## Experience dropped on death.
@export var xp_value: int = 1
## Damage dealt on contact.
@export var contact_damage: float = 8.0
## Relative weight when picking a spawn archetype; 0 disables it.
@export var spawn_weight: float = 1.0

## True for a boss. The normal spawner never picks an elite, and the run spawns
## it on boss waves only, one at a time.
@export var is_elite: bool = false
## Fraction of an incoming knockback that is ignored, in 0..1. A boss at 0.85
## barely moves; a minion at 0 takes the full push.
@export var knockback_resistance: float = 0.0
## Damage of the ground slam. Zero disables the slam, which is how a plain
## enemy and an elite share this resource without a subclass.
@export var slam_damage: float = 0.0
## Radius of the ground slam, in pixels.
@export var slam_radius: float = 0.0
## Seconds between the slam telegraph starting and the blow landing. This is the
## warning the player gets; below ~0.6 it stops being readable.
@export var slam_telegraph: float = 0.85
## Seconds the boss must wait after a slam before telegraphing the next one.
@export var slam_cooldown: float = 4.5
