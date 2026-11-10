## Derived statistics for one run.
##
## Plain data with no node access, scene tree or global state, so it can be
## unit-tested on its own. Since slice 0.2 the player carries several weapons, so
## the weapon-specific numbers (damage, cadence, reach) live on [WeaponData] and
## this class only holds the multipliers applied to all of them.
class_name Stats
extends RefCounted

## Highest crit chance a hit can reach, whatever the weapon's base chance and
## the player's bonus add up to.
const CRIT_CAP := 0.75

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
## Bonus damage fraction granted by the rage passive while the player is below
## [member rage_hp_threshold]. Zero when no worn piece carries the passive.
var rage_bonus: float = 0.0
## Health fraction below which [member rage_bonus] applies. Comes from the run
## config, never from the piece, so every piece that grants rage shares it.
var rage_hp_threshold: float = 0.5
## Current health fraction, refreshed by the run each frame. The rage
## multiplier is read when a hit resolves, so it never lags a threshold crossing
## by more than one frame (GDD E19's snapshot rule applies to the level, not to
## this).
var hp_ratio: float = 1.0
## Hit points restored on every level gained, summed from worn passives.
var level_up_heal: float = 0.0


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
			crit_chance_bonus = clampf(crit_chance_bonus + upgrade.amount, 0.0, CRIT_CAP)
		"range":
			range_mult += upgrade.amount


## Applies one equipment piece. Every percent stat adds to its multiplier
## instead of compounding: two rings at +10% damage give x1.20, not x1.21.
func apply_equipment(item: EquipmentData) -> void:
	if item == null:
		return

	_add_stat(item.stat, item.amount)


## Applies a completed set's bonus once. The caller rebuilds the derived stats
## from the base every time equipment changes, so a set that stays complete is
## never counted twice (GDD equipment AC5).
func apply_set_bonus(set_data: EquipmentSetData) -> void:
	if set_data == null:
		return

	_add_stat(set_data.stat, set_data.amount)


## Adds [param amount] to the multiplier of [param stat_key]. Unknown keys are
## ignored, as before.
func _add_stat(stat_key: String, amount: float) -> void:
	match stat_key:
		"damage":
			damage_mult += amount
		"attack_speed":
			attack_speed_mult += amount
		"max_hp":
			max_hp += amount
		"move_speed":
			move_speed_mult += amount
		"crit_chance":
			crit_chance_bonus = clampf(crit_chance_bonus + amount, 0.0, CRIT_CAP)
		"range":
			range_mult += amount


## Damage multiplier granted by the rage passive: active only while the player
## is strictly below [member rage_hp_threshold]. One frame of lag at most, since
## the run refreshes [member hp_ratio] every frame.
func rage_multiplier() -> float:
	if rage_bonus <= 0.0 or hp_ratio >= rage_hp_threshold:
		return 1.0
	return 1.0 + rage_bonus


## Damage multiplier granted by one weapon level alone. The step is additive on
## the base stat: level 4 with a 0.25 step is x1.75, not x1.25^3. This applies
## **before** [member damage_mult], so a level bonus and a global bonus compose
## as (base x level) x global.
static func level_damage_multiplier(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 1.0
	return 1.0 + maxf(weapon.level_damage_step, 0.0) * float(maxi(level, 1) - 1)


## Cadence multiplier granted by one weapon level alone, applied before
## [member attack_speed_mult].
static func level_cadence_multiplier(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 1.0
	return 1.0 + maxf(weapon.level_cadence_step, 0.0) * float(maxi(level, 1) - 1)


## Reach multiplier granted by one weapon level alone, applied before
## [member range_mult].
static func level_range_multiplier(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 1.0
	return 1.0 + maxf(weapon.level_range_step, 0.0) * float(maxi(level, 1) - 1)


## Multiplier applied to every reach-like value of [param weapon] at
## [param level]: range_px and orbit_radius. The level step applies first, then
## [member range_mult]; fuse_radius and chain_jump_radius are deliberately not
## scaled (GDD E20).
func weapon_range_multiplier(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 1.0
	return level_range_multiplier(weapon, level) * range_mult


## Effective damage of one weapon at [param level], before the crit roll.
## Order: base damage, then the level step, then [member damage_mult], then the
## rage passive. Offer numbers therefore show the damage the player would deal
## right now, low health included (GDD equipment F3).
func weapon_damage(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 0.0
	return (
		weapon.damage
		* level_damage_multiplier(weapon, level)
		* damage_mult
		* rage_multiplier()
	)


## Effective attacks per second of one weapon at [param level]. Order: base
## cadence, then the level step, then [member attack_speed_mult].
func weapon_attacks_per_second(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 0.0
	return maxf(
		weapon.attacks_per_second * level_cadence_multiplier(weapon, level) * attack_speed_mult,
		0.001
	)


## Effective reach of one weapon at [param level], in pixels. Order: base
## range, then the level step, then [member range_mult].
func weapon_range(weapon: WeaponData, level: int = 1) -> float:
	if weapon == null:
		return 0.0
	return weapon.range_px * level_range_multiplier(weapon, level) * range_mult


## Effective crit chance of one weapon, clamped so it never exceeds
## [constant CRIT_CAP].
func weapon_crit_chance(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	return clampf(weapon.crit_chance + crit_chance_bonus, 0.0, CRIT_CAP)


## True when [param stat] has reached a hard ceiling and another point would
## change nothing. Only crit chance has one today; every other stat is uncapped.
## Crit is capped on the bonus itself; a weapon's own base crit can reach the cap
## earlier, which [method crit_is_capped_for] checks per carried weapon.
func is_capped(stat: String) -> bool:
	if stat == "crit_chance":
		return crit_chance_bonus >= CRIT_CAP
	return false


## True when every carried weapon already crits at [constant CRIT_CAP], so a
## further crit bonus would change nothing. An empty loadout counts as capped:
## no weapon can benefit. Null entries are skipped.
func crit_is_capped_for(weapons: Array[WeaponData]) -> bool:
	for weapon in weapons:
		if weapon == null:
			continue
		if weapon_crit_chance(weapon) < CRIT_CAP - 0.0001:
			return false
	return true


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
