## Every content resource one run draws from.
##
## Loaded from `res://data/catalogue.tres`; lists the enemies, weapons,
## equipment, upgrades, boss, wave tuning and starting class a run may use.
## The run copies each list into its own pool before touching it, so trimming or
## clearing a pool never mutates this resource. No autoload and no global state:
## a caller owns the catalogue it was given.
class_name Catalogue
extends Resource

## Enemy archetypes the spawner may draw from, in declaration order. The boss is
## deliberately absent: it is spawned on boss waves only.
@export var enemies: Array[EnemyData] = []
## Weapons offered on level up, the starting weapon included.
@export var weapons: Array[WeaponData] = []
## Equipment offered on level up.
@export var equipment: Array[EquipmentData] = []
## Equipment sets. A piece points at one through its [member EquipmentData.set_id];
## a set whose id no piece names simply never completes.
@export var sets: Array[EquipmentSetData] = []
## Stat upgrades offered on level up.
@export var upgrades: Array[UpgradeData] = []
## Last-resort level-up offer, used when every normal candidate is filtered out.
## It must carry an uncapped stat, so it can never become a dead choice itself.
@export var fallback_upgrade: UpgradeData = null
## Elite spawned on every boss wave. Never added to [member enemies].
@export var boss: EnemyData = null
## Wave pacing: duration, spawn cadence and the run's finish line.
@export var wave: WaveData = null
## Class the run starts with: base statistics and starting weapon.
@export var starting_class: ClassData = null


## Enemy archetype whose stable [member EnemyData.id] is [param id], or null when
## the catalogue holds no such archetype. The boss is not searched: it lives in
## [member boss], never in [member enemies].
func enemy_by_id(id: String) -> EnemyData:
	for enemy in enemies:
		if enemy != null and enemy.id == id:
			return enemy
	return null


## Weapon whose stable [member WeaponData.id] is [param id], or null when the
## catalogue holds no such weapon.
func weapon_by_id(id: String) -> WeaponData:
	for weapon in weapons:
		if weapon != null and weapon.id == id:
			return weapon
	return null


## Equipment whose stable [member EquipmentData.id] is [param id], or null when
## the catalogue holds no such piece.
func equipment_by_id(id: String) -> EquipmentData:
	for item in equipment:
		if item != null and item.id == id:
			return item
	return null


## Equipment set whose stable [member EquipmentSetData.id] is [param id], or
## null when the catalogue holds no such set.
func set_by_id(id: String) -> EquipmentSetData:
	for set_data in sets:
		if set_data != null and set_data.id == id:
			return set_data
	return null
