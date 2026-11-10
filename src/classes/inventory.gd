## What the player carries: up to three weapons and one item per body slot.
##
## Plain data with no node access, scene tree or global state, so the rules of
## equipping can be unit-tested on their own. It never applies anything by
## itself: [method apply_to] pushes every equipped item into a [Stats].
class_name Inventory
extends RefCounted

## How many weapons the player can carry at once.
const MAX_WEAPONS := 3

## Body slots, in the order the HUD lists them.
const SLOTS := ["casque", "plastron", "bottes", "gants", "anneau", "amulette"]

## Equipped weapons, in acquisition order.
var weapons: Array[WeaponData] = []
## Equipped item per body slot: slot name -> EquipmentData.
var equipment: Dictionary = {}
## Level of each carried weapon, keyed by its stable [member WeaponData.id].
## A weapon absent from this map reads as level 1. Kept here, not on
## [WeaponData]: the .tres is shared by every run and must never carry run
## state. Using the id rather than the resource instance keeps the lookup
## stable when a duplicate .tres carries the same weapon.
var weapon_levels: Dictionary = {}


## Fills the inventory with the class's starting weapon. Call once at run start.
func setup_starting(weapon: WeaponData) -> void:
	weapons.clear()
	equipment.clear()
	weapon_levels.clear()
	add_weapon(weapon)


## True when [param weapon] is already carried, compared by id.
func has_weapon(weapon: WeaponData) -> bool:
	if weapon == null:
		return false
	for carried in weapons:
		if carried != null and carried.id == weapon.id:
			return true
	return false


## True while a weapon slot is free.
func can_add_weapon() -> bool:
	return weapons.size() < MAX_WEAPONS


## Number of weapon slots still free. The offer builder caps weapon choices to
## it: two spare slots never justify three weapon rows in one panel.
func free_weapon_slots() -> int:
	return maxi(MAX_WEAPONS - weapons.size(), 0)


## Level of [param weapon] in this run. A weapon that is not carried yet reads
## as level 1, because that is the level a newly acquired weapon starts at.
func level_of(weapon: WeaponData) -> int:
	if weapon == null:
		return 1
	return maxi(int(weapon_levels.get(weapon.id, 1)), 1)


## True when [param weapon] is carried and still below its own
## [member WeaponData.max_level]. The offer builder offers an upgrade only then.
func can_upgrade_weapon(weapon: WeaponData) -> bool:
	if weapon == null or not has_weapon(weapon):
		return false
	return level_of(weapon) < maxi(weapon.max_level, 1)


## Raises a carried weapon by one level, refusing a weapon that is not carried
## or already at its maximum. Returns true when the level changed.
func upgrade_weapon(weapon: WeaponData) -> bool:
	if not can_upgrade_weapon(weapon):
		return false
	weapon_levels[weapon.id] = level_of(weapon) + 1
	return true


## Adds a weapon when a slot is free and it is not already carried. A newly
## acquired weapon starts at level 1. Returns true when it was added.
func add_weapon(weapon: WeaponData) -> bool:
	if weapon == null or not can_add_weapon() or has_weapon(weapon):
		return false
	weapons.append(weapon)
	weapon_levels[weapon.id] = 1
	return true


## Puts [param weapon] in the slot at [param index], discarding what was there.
## The replacement starts at level 1: a level belongs to the weapon carried,
## not to the slot.
func replace_weapon(index: int, weapon: WeaponData) -> void:
	if weapon == null or index < 0 or index >= weapons.size():
		return
	var previous := weapons[index]
	if previous != null:
		weapon_levels.erase(previous.id)
	weapons[index] = weapon
	weapon_levels[weapon.id] = 1


## Equips an item, replacing whatever occupied its slot. Returns the item that
## was displaced, or null when the slot was empty.
func equip(item: EquipmentData) -> EquipmentData:
	if item == null:
		return null
	var previous: EquipmentData = equipment.get(item.slot, null)
	equipment[item.slot] = item
	return previous


## The item in a body slot, or null when the slot is empty.
func item_in_slot(slot: String) -> EquipmentData:
	return equipment.get(slot, null)


## Pushes every equipped item into [param stats], in slot order so the result is
## independent of the order the items were picked up.
func apply_to(stats: Stats) -> void:
	if stats == null:
		return
	for slot in SLOTS:
		stats.apply_equipment(item_in_slot(slot))
