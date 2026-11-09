## One choice shown on the level-up panel.
##
## Three kinds of choice share the same panel: a stat upgrade, a weapon, or a
## piece of equipment. Exactly one of the payload fields is set, and [member kind]
## says which. Pure data, so the panel and the choice logic stay testable.
class_name Offer
extends RefCounted

## Kind of choice: "stat", "weapon" or "equipment".
var kind: String = "stat"
## Relative weight when rolling the three choices, set by the caller.
var weight: float = 1.0
## Title shown on the button.
var title: String = ""
## Effect text shown under the title.
var description: String = ""
## Set when kind is "stat".
var stat_upgrade: UpgradeData = null
## Set when kind is "weapon".
var weapon: WeaponData = null
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


## Builds a new-weapon choice.
static func for_weapon(new_weapon: WeaponData) -> Offer:
	var offer := Offer.new()
	offer.kind = "weapon"
	offer.weapon = new_weapon
	if new_weapon != null:
		offer.title = "Arme : %s" % new_weapon.display_name
		offer.description = "%.0f degats, %.1f attaque/s, portee %.0f" % [
			new_weapon.damage, new_weapon.attacks_per_second, new_weapon.range_px
		]
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
