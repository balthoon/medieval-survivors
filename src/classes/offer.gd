## One choice shown on the level-up panel.
##
## Five kinds of choice share the same panel: a stat upgrade, a new weapon, a
## weapon level, a weapon evolution, or a piece of equipment. Exactly one of the
## payload fields is set, and [member kind] says which. Pure data, so the panel
## and the choice logic stay testable.
class_name Offer
extends RefCounted

## Kind of choice: "stat", "weapon", "weapon_upgrade", "weapon_evolution" or
## "equipment".
var kind: String = "stat"
## Relative weight when rolling the three choices, set by the caller.
var weight: float = 1.0
## Title shown on the button.
var title: String = ""
## Effect text shown under the title.
var description: String = ""
## Set when kind is "stat".
var stat_upgrade: UpgradeData = null
## Set when kind is "weapon", "weapon_upgrade" or "weapon_evolution". For an
## evolution it is the weapon carried, the one that leaves the slot.
var weapon: WeaponData = null
## Level the weapon reaches if this upgrade is chosen. One for a new weapon; for
## an evolution, the level the evolved weapon keeps.
var target_level: int = 1
## Set when kind is "weapon_evolution": the weapon [member weapon] becomes.
var evolved_weapon: WeaponData = null
## Set when kind is "equipment".
var equipment: EquipmentData = null


## Builds a stat-bonus choice.
static func for_stat(upgrade: UpgradeData) -> Offer:
	var offer := Offer.new()
	offer.kind = "stat"
	offer.stat_upgrade = upgrade
	if upgrade != null:
		offer.title = upgrade.display_name
		offer.description = upgrade.description
	return offer


## Builds a new-weapon choice. The description starts with the weapon's own
## pitch — the sentence that names its mechanic — before any number (AC8).
static func for_weapon(new_weapon: WeaponData) -> Offer:
	var offer := Offer.new()
	offer.kind = "weapon"
	offer.weapon = new_weapon
	offer.target_level = 1
	if new_weapon != null:
		offer.title = Loc.format("offer.weapon_new", "Arme : %s", [new_weapon.display_name])
		offer.description = new_weapon.description
	return offer


## Builds a weapon-level choice. The description starts as the weapon's own
## pitch; main rewrites it with the numbers the next level actually reaches.
static func for_weapon_upgrade(carried: WeaponData, level: int) -> Offer:
	var offer := Offer.new()
	offer.kind = "weapon_upgrade"
	offer.weapon = carried
	offer.target_level = maxi(level, 1)
	if carried != null:
		offer.title = Loc.format(
			"offer.weapon_upgrade",
			"↑ %s +1 (niv. %d)",
			[carried.display_name, offer.target_level]
		)
		offer.description = carried.description
	return offer


## Builds a weapon-evolution choice. The description starts as the evolved
## weapon's own pitch; main rewrites it with the stats the evolution actually
## reaches and the level it keeps.
static func for_weapon_evolution(carried: WeaponData, evolved: WeaponData, level: int) -> Offer:
	var offer := Offer.new()
	offer.kind = "weapon_evolution"
	offer.weapon = carried
	offer.evolved_weapon = evolved
	offer.target_level = maxi(level, 1)
	if carried != null and evolved != null:
		offer.title = Loc.format(
			"offer.weapon_evolution",
			"★ %s → %s",
			[carried.display_name, evolved.display_name]
		)
		offer.description = evolved.description
	return offer


## Builds an equipment choice.
static func for_equipment(item: EquipmentData) -> Offer:
	var offer := Offer.new()
	offer.kind = "equipment"
	offer.equipment = item
	if item != null:
		offer.title = "%s (%s)" % [item.display_name, item.rarity.replace("_", " ")]
		offer.description = item.description
	return offer
