## Weapon tuning: either a melee arc or a fired projectile.
##
## Values live in .tres resources under res://data/weapons/. The player keeps up
## to three of these at once; each one attacks on its own cadence.
class_name WeaponData
extends Resource

## Stable identifier, used to tell two weapons apart in the inventory.
@export var id: String = ""
## Name shown in the HUD and on the upgrade panel.
@export var display_name: String = ""
## "melee" sweeps an arc in front of the player; "projectile" fires a bolt.
@export var kind: String = "melee"
## How the melee weapon is drawn: "blade" or "hammer". Ignored by projectiles.
@export var shape: String = "blade"
## Base damage per hit, before the player's damage multiplier.
@export var damage: float = 12.0
## Attacks per second, before the player's attack-speed multiplier.
@export var attacks_per_second: float = 1.8
## Reach in pixels: the arc radius, or the distance a projectile flies.
@export var range_px: float = 70.0
## Full width of the swing cone in degrees. Ignored by projectiles.
@export var arc_degrees: float = 120.0
## Seconds one melee swing lasts. Damage lands at 45 % of it, not at the swing's
## start. Ignored by projectile weapons.
@export var swing_duration: float = 0.12
## Probability in 0..1 that a hit crits, before the player's bonus.
@export var crit_chance: float = 0.05
## Damage multiplier applied on a crit.
@export var crit_multiplier: float = 2.0
## Distance an enemy is pushed away on each hit.
@export var knockback: float = 28.0
## Travel speed of a projectile, in pixels per second.
@export var projectile_speed: float = 520.0
## Colour of the weapon's visual.
@export var color: Color = Color(0.72, 0.74, 0.78)
