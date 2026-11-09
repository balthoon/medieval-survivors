## Enemy archetype: health, movement, contact damage, spawn weight and look.
##
## Values live in .tres resources under res://data/enemies/.
class_name EnemyData
extends Resource

## Keys understood by [method ActorArt.draw_creature]. The look is data, not a
## branch in the enemy: a new archetype is a new `.tres` with an art key, and the
## unknown-key fallback is the plain skeleton.
##
## - `skeleton` — narrow and vertical, round skull over a ribcage
## - `orc` — wide and low, shoulders outside the torso, carries a club
## - `wolf` — horizontal, cold grey, snout and tail
## - `boss` — tall, caped, crowned, staff in hand
const ART_KEYS := ["skeleton", "orc", "wolf", "boss"]

## Stable machine identifier for this archetype, never renamed once saved: code
## and saved data key on it. [member display_name] is UI text and will be
## localized or renamed, so it must never be used as a lookup key. Must be
## non-empty and unique across every enemy, the boss included.
@export var id: String = ""
## Name used by debug output and future UI. Localizable, and therefore not a
## stable key: use [member id] whenever code needs to identify an archetype.
@export var display_name: String = ""
## Which drawing [method ActorArt.draw_creature] paints for this archetype. Must
## be one of [constant ART_KEYS]; the skeleton is drawn for any unknown key, so a
## typo shows a plain enemy instead of an invisible one.
@export var art: String = "skeleton"
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
## First wave index in which the normal spawner may pick this archetype. 0 makes
## it available from the run's first wave. The boss ignores this field: the wave
## director spawns it on boss waves, never the normal pool.
@export var unlock_wave: int = 0

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
