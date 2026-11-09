## Playable class archetype: starting stats plus the weapon it wields.
##
## Values live in .tres resources under res://data/classes/ so designers can
## tune them without touching code.
class_name ClassData
extends Resource

## Name shown in the HUD and on the upgrade panel.
@export var display_name: String = ""
## Starting maximum hit points.
@export var max_hp: int = 100
## Movement speed in pixels per second.
@export var move_speed: float = 220.0
## Weapon the class starts the run with.
@export var weapon: WeaponData = null
