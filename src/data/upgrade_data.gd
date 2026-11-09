## A single stat upgrade offered on level up.
##
## Values live in .tres resources under res://data/upgrades/.
class_name UpgradeData
extends Resource

## Name shown on the upgrade button.
@export var display_name: String = ""
## Short effect text shown under the name.
@export var description: String = ""
## Stat key understood by Stats.apply_upgrade.
@export var stat: String = "damage"
## Amount applied to the stat; percentage stats use fractions (0.2 == +20%).
@export var amount: float = 0.1
## Relative weight when rolling random upgrade choices.
@export var weight: float = 1.0
