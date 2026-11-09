## Derived statistics for one run.
##
## Plain data with no node access, scene tree or global state, so it can be
## unit-tested on its own. Since slice 0.2 the player carries several weapons, so
## the weapon-specific numbers (damage, cadence, reach) live on [WeaponData] and
## this class only holds the multipliers applied to all of them.
class_name Stats
extends RefCounted

## Base hit points.
var max_hp: float = 100.0
## Movement speed in pixels per second.
var move_speed: float = 220.0
## Multiplier applied on top of [member move_speed]; additive across upgrades
## and equipment, so two +10% bonuses give x1.20, not x1.21.
var move_speed_mult: float = 1.0
## Multiplier applied to every weapon's base damage.
var damage_mult: float = 1.0
## Multiplier applied to every weapon's base cadence.
var attack_speed_mult: float = 1.0
## Reach multiplier applied to every weapon's range.
var range_mult: float = 1.0
## Added to every weapon's crit chance, clamped to 0.75 when read.
var crit_chance_bonus: float = 0.0


## Builds the run's base Stats from a class. Weapons are not read here: the
## starting weapon goes into the [Inventory] instead.
static func from_class(class_data: ClassData) -> Stats:
	var stats := Stats.new()
	if class_data == null:
		return stats

	stats.max_hp = float(class_data.max_hp)
	stats.move_speed = class_data.move_speed
	return stats


## Applies one stat upgrade. Unknown stat names are ignored.
## Every percent stat adds to its multiplier, so two +20% upgrades give x1.40,
## not x1.44. crit_chance is clamped to 0.75.
func apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return

	match upgrade.stat:
		"damage":
			damage_mult += upgrade.amount
		"attack_speed":
			attack_speed_mult += upgrade.amount
		"max_hp":
			max_hp += upgrade.amount
		"move_speed":
			move_speed_mult += upgrade.amount
		"crit_chance":
			crit_chance_bonus = clampf(crit_chance_bonus + upgrade.amount, 0.0, 0.75)
		"range":
			range_mult += upgrade.amount


## Applies one equipment piece. Every percent stat adds to its multiplier
## instead of compounding: two rings at +10% damage give x1.20, not x1.21.
func apply_equipment(item: EquipmentData) -> void:
	if item == null:
		return

	match item.stat:
		"damage":
			damage_mult += item.amount
		"attack_speed":
			attack_speed_mult += item.amount
		"max_hp":
			max_hp += item.amount
		"move_speed":
			move_speed_mult += item.amount
		"crit_chance":
			crit_chance_bonus = clampf(crit_chance_bonus + item.amount, 0.0, 0.75)
		"range":
			range_mult += item.amount


## Effective damage of one weapon, before the crit roll.
func weapon_damage(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	return weapon.damage * damage_mult


## Effective attacks per second of one weapon.
func weapon_attacks_per_second(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	return maxf(weapon.attacks_per_second * attack_speed_mult, 0.001)


## Effective reach of one weapon, in pixels.
func weapon_range(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	return weapon.range_px * range_mult


## Effective crit chance of one weapon, clamped so it never exceeds 0.75.
func weapon_crit_chance(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	return clampf(weapon.crit_chance + crit_chance_bonus, 0.0, 0.75)


## Movement speed after every speed multiplier, in pixels per second.
func effective_move_speed() -> float:
	return move_speed * move_speed_mult


## Returns a deep copy.
func clone() -> Stats:
	var copy := Stats.new()
	copy.max_hp = max_hp
	copy.move_speed = move_speed
	copy.move_speed_mult = move_speed_mult
	copy.damage_mult = damage_mult
	copy.attack_speed_mult = attack_speed_mult
	copy.range_mult = range_mult
	copy.crit_chance_bonus = crit_chance_bonus
	return copy
