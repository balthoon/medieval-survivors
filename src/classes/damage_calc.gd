## One damage roll for a weapon hit.
##
## Takes an injected [RandomNumberGenerator] so callers control determinism in
## tests. No node access, scene tree or global state.
class_name DamageCalc
extends RefCounted

## Rolls one hit of [param weapon] at [param level] for the given player stats.
## A crit multiplies the damage by the weapon's own crit multiplier. The level
## is an explicit parameter so a hit already in flight keeps the level it was
## fired at, like the weapon resource it captured (GDD E19).
## Returns {"amount": float, "is_crit": bool}.
static func roll(
	stats: Stats,
	weapon: WeaponData,
	rng: RandomNumberGenerator,
	level: int = 1
) -> Dictionary:
	if stats == null or weapon == null or rng == null:
		return {"amount": 0.0, "is_crit": false}

	var is_crit := rng.randf() < stats.weapon_crit_chance(weapon)
	var amount := stats.weapon_damage(weapon, level)
	if is_crit:
		amount *= weapon.crit_multiplier

	return {"amount": amount, "is_crit": is_crit}
