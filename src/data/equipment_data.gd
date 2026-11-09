## One piece of wearable equipment: a single stat modifier on one body slot.
##
## Values live in .tres resources under res://data/equipment/. The rarity is a
## label and a colour; the strength of the piece is its [member amount].
class_name EquipmentData
extends Resource

## Offer weight per rarity when rolling random equipment choices; the rarer
## the piece, the lower its chance of being offered.
const RARITY_WEIGHTS := {
	"commun": 1.0,
	"peu_commun": 0.8,
	"rare": 0.55,
	"epique": 0.35,
	"legendaire": 0.22,
	"mythique": 0.12,
}

## Stable identifier, used to spot duplicates.
@export var id: String = ""
## Name shown in the HUD and on the upgrade panel.
@export var display_name: String = ""
## Body slot, one of Inventory.SLOTS: casque, plastron, bottes, gants, anneau,
## amulette. Equipping a piece replaces whatever occupies its slot.
@export var slot: String = "casque"
## Rarity label: commun, peu_commun, rare, epique, legendaire, mythique.
@export var rarity: String = "commun"
## Stat key understood by Stats.apply_equipment.
@export var stat: String = "damage"
## Amount applied to the stat; percentage stats use fractions (0.1 == +10%).
@export var amount: float = 0.05
## Short effect text shown under the name.
@export var description: String = ""


## Offer weight for [param rarity]; unknown rarities fall back to 0.5.
static func offer_weight_for_rarity(rarity: String) -> float:
	return float(RARITY_WEIGHTS.get(rarity, 0.5))


## Effect of the piece formatted for the HUD, for example "+22 % dégâts".
## Unknown stat keys fall back to [member description].
func effect_text() -> String:
	match stat:
		"max_hp":
			return "+%d PV" % int(round(amount))
		"damage":
			return "+%d %% dégâts" % int(round(amount * 100.0))
		"attack_speed":
			return "+%d %% cadence" % int(round(amount * 100.0))
		"move_speed":
			return "+%d %% vitesse" % int(round(amount * 100.0))
		"crit_chance":
			return "+%d %% critique" % int(round(amount * 100.0))
		"range":
			return "+%d %% portée" % int(round(amount * 100.0))
	return description
