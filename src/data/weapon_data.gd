## Weapon tuning: either a melee arc or a fired projectile, plus the one rule
## that sets it apart from the other nine.
##
## Values live in .tres resources under res://data/weapons/. The player keeps up
## to three of these at once; each one attacks on its own cadence.
##
## W2-E1 fixes the contract only: [member mechanic] and the mechanic-specific
## fields below are data. W2-E2 resolves them in WeaponSystem; until then they
## change no behaviour.
class_name WeaponData
extends Resource

## Every token [member mechanic] may take. One weapon = one rule; a weapon that
## only changes a number is not content (product brief W2). Kept as readable
## tokens rather than an integer enum so a `.tres` diff says `&"pierce"` instead
## of a number, and so adding a mechanic never renumbers saved data.
const MECHANICS := [
	&"cleave", &"execution", &"stagger", &"distance", &"whirl",
	&"pierce", &"chain", &"orbit", &"fuse", &"lifesteal",
]

## Stable identifier, used to tell two weapons apart in the inventory.
@export var id: String = ""
## Name shown in the HUD and on the upgrade panel. French source text; the
## localized string lives under [member name_key].
@export var display_name: String = ""
## Localization key of the name: "weapon.<id>.name" (W8 convention). The source
## text stays in [member display_name] until W8-E2 extracts it.
@export var name_key: String = ""
## One-sentence pitch naming the mechanic, French source text. The localized
## string lives under [member description_key] and is what the offer must show
## before the numbers.
@export var description: String = ""
## Localization key of the description: "weapon.<id>.desc" (W8 convention).
@export var description_key: String = ""
## "melee" sweeps an arc in front of the player; "projectile" fires a bolt.
@export var kind: String = "melee"
## How the melee weapon is drawn: "blade" or "hammer". Ignored by projectiles.
@export var shape: String = "blade"
## The rule that sets this weapon apart, one of [constant MECHANICS]. W2-E2
## switches on this token. An unknown token falls back to "cleave" with a
## warning, so a typo never makes a weapon inert.
@export var mechanic: StringName = &"cleave"
## Presentation and future shop label: commun, peu_commun, rare, epique,
## legendaire, mythique. W2 offers every weapon at the same weight and the same
## price (one of the three weapon slots); rarity must never become a power tier.
@export var rarity: String = "commun"
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

## Dagger (`execution`): cooldown left after a killing blow, in seconds. A floor
## above zero keeps the refund independent of the frame rate. Zero disables it.
@export var execution_floor: float = 0.0
## Hammer (`stagger`): seconds added to the next attack of an interrupted enemy.
## Zero disables the interruption. Elites are immune (see EnemyData.is_elite).
@export var stagger_seconds: float = 0.0
## Bow (`distance`): extra damage at full range as a fraction of the base hit.
## At half range, half the bonus applies. Zero disables the scaling.
@export var distance_damage_bonus: float = 0.0
## Crossbow (`pierce`): multiplier applied to each enemy pierced after the
## first. 1.0 means no falloff.
@export var pierce_falloff: float = 1.0
## Staff (`chain`): jumps after the first target. Zero means no chain.
@export var chain_jumps: int = 0
## Staff (`chain`): maximum distance between two links, in pixels.
@export var chain_jump_radius: float = 0.0
## Staff (`chain`): multiplier applied to each jump's damage. 1.0 means none.
@export var chain_falloff: float = 1.0
## Orb (`orbit`): distance from the player, in pixels. Zero means no orbit.
@export var orbit_radius: float = 0.0
## Orb (`orbit`): angular speed in radians per second.
@export var orbit_speed: float = 0.0
## Orb (`orbit`): minimum seconds before the same enemy can be hit again.
@export var orbit_hit_cooldown: float = 0.0
## Censer (`fuse`): seconds between landing and detonation. Zero means no fuse.
@export var fuse_seconds: float = 0.0
## Censer (`fuse`): blast radius in pixels.
@export var fuse_radius: float = 0.0
## Vampire blade (`lifesteal`): fraction of damage actually dealt returned as
## health, in 0..1. Elites are immune (see EnemyData.is_elite).
@export var lifesteal_ratio: float = 0.0


## True when [member mechanic] is one of [constant MECHANICS]. W2-E2 falls back
## to "cleave" with a warning when this is false.
func has_known_mechanic() -> bool:
	return MECHANICS.has(mechanic)
