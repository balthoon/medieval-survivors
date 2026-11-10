## Run tuning: XP curve, offer weights, rerolls, hitstop, shake and boss scaling.
##
## Values live in res://data/run_config.tres. Every number here was a constant in
## src/main.gd before W0-E3; moving them to a resource changed where tuning is
## edited, not what the run does. Defaults below are the historical constants and
## are the fallback when the resource cannot be loaded.
class_name RunConfig
extends Resource

## Flat XP cost of the first level curve step.
@export var xp_base: int = 5
## Extra XP per level added to the curve.
@export var xp_per_level: int = 4
## Seconds an enemy must wait after dealing contact damage.
@export var contact_cooldown: float = 1.0
## How many choices a level up offers.
@export var upgrade_offer_count: int = 3
## Deadzone applied to the joypad movement axes.
@export var joy_axis_deadzone: float = 0.25
## Relative weight of a new-weapon choice against a stat or equipment choice.
@export var weapon_offer_weight: float = 1.4
## Relative weight of a weapon-level choice against a stat or equipment choice.
## A new weapon and an upgrade compete for the panel's single weapon row (A2),
## so this is what decides how often a carried weapon levels up instead.
@export var weapon_upgrade_weight: float = 1.4
## Relative weight of a common piece of equipment against a stat or weapon choice.
@export var equipment_offer_weight: float = 0.9
## Health fraction below which the rage passive grants its damage bonus. One
## value for the whole run, so every rage piece behaves the same.
@export var rage_hp_threshold: float = 0.5
## Rerolls the player starts the run with.
@export var reroll_base: int = 2
## Levels that grant one extra reroll.
@export var reroll_levels: Array[int] = [10, 20]
## Duration of the camera shake when the player is hit, in seconds.
@export var shake_duration: float = 0.18
## Peak offset of the camera shake, in pixels.
@export var shake_strength: float = 4.0
## Hitstop applied on a critical hit, in seconds.
@export var crit_hitstop: float = 0.055
## Hitstop applied on a heavy hit, in seconds.
@export var heavy_hitstop: float = 0.04
## Hitstop applied when the level-up panel opens, in seconds.
@export var level_up_hitstop: float = 0.12
## Minimum damage of a hit treated as heavy for hitstop purposes.
@export var heavy_hit_damage: float = 22.0
## Minimum real-time gap between two hitstops, in seconds.
@export var hitstop_rest: float = 0.3
## Time scale during a hitstop. Small but not zero, so the scene keeps stepping.
@export var hitstop_scale: float = 0.05
## Colour of the ring drawn when the level-up panel opens.
@export var level_up_color: Color = Color(0.85, 0.65, 0.15)
## Health multiplier granted to a boss per tier above the first.
@export var boss_hp_per_tier: float = 0.9
## Damage multiplier granted to a boss per tier above the first.
@export var boss_damage_per_tier: float = 0.35
## Relative weight of a weapon in the boss loot panel.
@export var boss_loot_weapon_weight: float = 3.0
## Relative weight of a piece of equipment in the boss loot panel.
@export var boss_loot_equipment_weight: float = 2.5
## Title of the panel opened by a boss death.
@export var boss_loot_title: String = "Butin du boss"
## Colour of the impact ring drawn where a slam lands.
@export var boss_slam_color: Color = Color(0.75, 0.20, 0.14)
## Duration of the camera shake when a slam lands, in seconds.
@export var boss_slam_shake_duration: float = 0.3
## Peak offset of the camera shake when a slam lands, in pixels.
@export var boss_slam_shake_strength: float = 7.0
