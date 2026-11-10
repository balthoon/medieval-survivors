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
## Rule the piece grants while worn; empty means no passive. Known ids:
## "rage" (bonus damage below a health threshold) and "level_up_heal" (hit
## points restored on every level gained).
@export var passive_id: StringName = &""
## Magnitude of [member passive_id]: a fraction for rage, hit points for the
## heal. Ignored when [member passive_id] is empty.
@export var passive_value: float = 0.0
## Stable id of the set the piece belongs to; empty means no set.
@export var set_id: String = ""
## Short effect text shown under the name.
@export var description: String = ""


## Offer weight for [param rarity]; unknown rarities fall back to 0.5.
static func offer_weight_for_rarity(rarity: String) -> float:
	return float(RARITY_WEIGHTS.get(rarity, 0.5))


## Effect of the piece formatted for the HUD, for example "+22 % dégâts".
## Unknown stat keys fall back to [member description].
func effect_text() -> String:
	return stat_text(stat, amount, description)


## Formats a stat modifier for display, shared with [EquipmentSetData] so a set
## bonus reads exactly like the piece that grants it.
## Unknown stat keys fall back to [param fallback].
static func stat_text(stat_key: String, value: float, fallback: String = "") -> String:
	match stat_key:
		"max_hp":
			return "+%d PV" % int(round(value))
		"damage":
			return "+%d %% dégâts" % int(round(value * 100.0))
		"attack_speed":
			return "+%d %% cadence" % int(round(value * 100.0))
		"move_speed":
			return "+%d %% vitesse" % int(round(value * 100.0))
		"crit_chance":
			return "+%d %% critique" % int(round(value * 100.0))
		"range":
			return "+%d %% portée" % int(round(value * 100.0))
	return fallback


## Effect of the passive formatted for the HUD, or an empty string when the
## piece carries none. [param rage_hp_threshold] is the run's configured health
## fraction, so the sentence matches what Stats actually applies.
func passive_text(rage_hp_threshold: float = 0.5) -> String:
	match passive_id:
		&"rage":
			return Loc.format(
				"equipment.passive_rage",
				"Rage : +%d %% dégâts sous %d %% PV",
				[
					int(round(passive_value * 100.0)),
					int(round(rage_hp_threshold * 100.0)),
				]
			)
		&"level_up_heal":
			return Loc.format(
				"equipment.passive_level_heal",
				"Soin : +%d PV par niveau",
				[int(round(passive_value))]
			)
	return ""
