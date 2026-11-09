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


## Fills the inventory with the class's starting weapon. Call once at run start.
func setup_starting(weapon: WeaponData) -> void:
	weapons.clear()
	equipment.clear()
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


## Adds a weapon when a slot is free and it is not already carried.
## Returns true when it was added.
func add_weapon(weapon: WeaponData) -> bool:
	if weapon == null or not can_add_weapon() or has_weapon(weapon):
		return false
	weapons.append(weapon)
	return true


## Puts [param weapon] in the slot at [param index], discarding what was there.
func replace_weapon(index: int, weapon: WeaponData) -> void:
	if weapon == null or index < 0 or index >= weapons.size():
		return
	weapons[index] = weapon


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
