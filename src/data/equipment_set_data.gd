## One equipment set: a bonus granted once when enough of its pieces are worn.
##
## Sets live in res://data/sets/. [member EquipmentData.set_id] links a piece to
## its set; the run counts the worn pieces and applies this bonus once, on top of
## the pieces themselves, whenever the count reaches [member required_pieces].
class_name EquipmentSetData
extends Resource

## Stable identifier, matched against EquipmentData.set_id.
@export var id: String = ""
## Name shown on the level-up panel and in the HUD.
@export var display_name: String = ""
## Pieces that must be worn together for the bonus to apply.
@export var required_pieces: int = 2
## Stat key understood by Stats.apply_set_bonus.
@export var stat: String = "damage"
## Amount applied once; percentage stats use fractions (0.12 == +12%).
@export var amount: float = 0.05
## Short flavour text; the HUD shows the formatted bonus instead when empty.
@export var description: String = ""


## Bonus formatted for the panel and the HUD, for example "+12 % critique".
func bonus_text() -> String:
	return EquipmentData.stat_text(stat, amount)
