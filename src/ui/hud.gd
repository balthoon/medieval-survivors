## Heads-up display over the arena. Owns the level-up panel and its input so the
## three choices work from the number keys, the mouse and a focused gamepad.
class_name HUD extends CanvasLayer

## Emitted once per press on one of the three level-up choices, with its index.
signal upgrade_chosen(index: int)

## Emitted when the player asks for a fresh set of level-up choices.
signal reroll_requested

## Width of the health and experience bars in pixels, matching the scene.
const BAR_WIDTH := 320.0
## Height of the health bar in pixels.
const HP_BAR_HEIGHT := 24.0
## Height of the experience bar in pixels.
const XP_BAR_HEIGHT := 10.0
## Width of the wave progress bar in pixels.
const WAVE_BAR_WIDTH := 376.0
## Height of the wave progress bar in pixels.
const WAVE_BAR_HEIGHT := 8.0
## Width of one weapon recharge bar in pixels.
const WEAPON_BAR_WIDTH := 576.0
## Height of one weapon recharge bar in pixels.
const WEAPON_BAR_HEIGHT := 4.0
## Width of the boss health bar in pixels, matching the scene.
const BOSS_BAR_WIDTH := 560.0
## Height of the boss health bar in pixels.
const BOSS_BAR_HEIGHT := 24.0
## Title shown on the level-up panel.
const LEVEL_UP_TITLE := "Montée de niveau"
## Seconds the red damage flash takes to fade out.
const DAMAGE_FLASH_TIME := 0.25
## Starting alpha of the red damage flash.
const DAMAGE_FLASH_ALPHA := 0.22
## Seconds the wave banner stays on screen before fading.
const BANNER_TIME := 1.2
## Health fraction below which the screen edges pulse.
const LOW_HP_RATIO := 0.3

## Seconds the wave banner spends fading during its last moments.
const _BANNER_FADE_TIME := 0.4
## Player-facing title of every body slot, keyed by Inventory.SLOTS entries.
const _SLOT_TITLES := {
	"casque": "Casque",
	"plastron": "Plastron",
	"bottes": "Bottes",
	"gants": "Gants",
	"anneau": "Anneau",
	"amulette": "Amulette",
}

var _options: Array[Button] = []
var _desc_labels: Array[Label] = []
var _choice_count := 0
var _accepting := false

var _weapon_labels: Array[Label] = []
var _weapon_statuses: Array[Label] = []
var _weapon_fills: Array[ColorRect] = []
var _weapon_bgs: Array[ColorRect] = []
var _equipment_labels: Array[Label] = []
var _low_hp_rects: Array[ColorRect] = []

var _hp_ratio := 1.0
var _flash_time := 0.0
var _banner_time := 0.0
var _elapsed := 0.0

@onready var _hp_fill: ColorRect = $HpBarFill
@onready var _hp_label: Label = $HpLabel
@onready var _xp_fill: ColorRect = $XpBarFill
@onready var _xp_label: Label = $XpLabel
@onready var _wave_label: Label = $WaveLabel
@onready var _timer_label: Label = $TimerLabel
@onready var _wave_fill: ColorRect = $WaveBarFill
@onready var _death_label: Label = $DeathLabel
@onready var _wave_banner: Label = $WaveBanner
@onready var _damage_flash: ColorRect = $DamageFlash
@onready var _upgrade_panel: Control = $UpgradePanel
@onready var _panel_title: Label = $UpgradePanel/Title
@onready var _reroll_label: Label = $UpgradePanel/RerollLabel
@onready var _boss_bar: Control = $BossBar
@onready var _boss_name: Label = $BossBar/BossName
@onready var _boss_fill: ColorRect = $BossBar/BossBarFill
@onready var _frame: HudFrame = $Frame
@onready var _victory_panel: Control = $VictoryPanel
@onready var _victory_detail: Label = $VictoryPanel/Detail


func _ready() -> void:
	# Explicit: the number-key and reroll shortcuts must still fire while a
	# Button holds focus.
	set_process_unhandled_key_input(true)

	_options = [$UpgradePanel/Option0, $UpgradePanel/Option1, $UpgradePanel/Option2]
	_desc_labels = [$UpgradePanel/Desc0, $UpgradePanel/Desc1, $UpgradePanel/Desc2]
	for index in _options.size():
		_options[index].pressed.connect(_on_option_pressed.bind(index))

	_weapon_labels = [$Weapon0Label, $Weapon1Label, $Weapon2Label]
	_weapon_statuses = [$Weapon0Status, $Weapon1Status, $Weapon2Status]
	_weapon_fills = [$Weapon0Fill, $Weapon1Fill, $Weapon2Fill]
	_weapon_bgs = [$Weapon0Bg, $Weapon1Bg, $Weapon2Bg]

	_equipment_labels = [$Equip0, $Equip1, $Equip2, $Equip3, $Equip4, $Equip5]
	_low_hp_rects = [$LowHpTop, $LowHpBottom, $LowHpLeft, $LowHpRight]

	_damage_flash.visible = false
	_damage_flash.color = Color(0.75, 0.12, 0.10, 0.0)

	hide_upgrade_choices()
	hide_boss()
	hide_dead()
	hide_victory()
	_update_low_hp_edges(0.0)


## Advances the timed effects: damage flash, wave banner and the low-HP pulse.
func _process(delta: float) -> void:
	_elapsed += delta
	_update_damage_flash(delta)
	_update_banner(delta)
	_update_low_hp_edges(_elapsed)


## Refreshes the health and experience bars plus their labels.
func update_bars(hp: float, hp_max: float, xp: float, xp_to_next: float, level: int) -> void:
	var hp_ratio := 0.0
	if hp_max > 0.0:
		hp_ratio = clampf(hp / hp_max, 0.0, 1.0)
	_hp_ratio = hp_ratio
	_hp_fill.size = Vector2(BAR_WIDTH * hp_ratio, HP_BAR_HEIGHT)
	_hp_label.text = "VIE %d / %d" % [int(ceilf(hp)), int(ceilf(hp_max))]

	var xp_ratio := 0.0
	if xp_to_next > 0.0:
		xp_ratio = clampf(xp / xp_to_next, 0.0, 1.0)
	_xp_fill.size = Vector2(BAR_WIDTH * xp_ratio, XP_BAR_HEIGHT)
	_xp_label.text = "XP %d / %d · NIV. %d" % [int(xp), int(xp_to_next), level]


## Refreshes the wave number, remaining seconds and wave progress bar.
func update_wave(wave_index: int, seconds_left: float, progress: float) -> void:
	_wave_label.text = "Vague %d" % (wave_index + 1)
	_timer_label.text = "%d s" % int(ceilf(seconds_left))
	_wave_fill.size = Vector2(WAVE_BAR_WIDTH * clampf(progress, 0.0, 1.0), WAVE_BAR_HEIGHT)


## Refreshes the three weapon rows. Each bar fills as that weapon recharges:
## the ratio is 0 when the weapon is ready and 1 right after firing. A carried
## weapon also shows its level, so an upgrade taken on the panel is visible
## without opening the panel again.
func update_weapons(
	weapons: Array[WeaponData],
	levels: Array[int],
	ratios: Array[float],
	seconds: Array[float]
) -> void:
	for index in _weapon_labels.size():
		var label := _weapon_labels[index]
		var status := _weapon_statuses[index]
		var fill := _weapon_fills[index]
		var background := _weapon_bgs[index]

		label.visible = true
		status.visible = true
		fill.visible = true
		background.visible = true

		if index >= weapons.size() or weapons[index] == null:
			label.text = "— emplacement libre"
			status.text = ""
			fill.size = Vector2(0.0, WEAPON_BAR_HEIGHT)
			continue

		label.text = weapons[index].display_name
		if index < levels.size():
			label.text = "%s · %s" % [
				weapons[index].display_name,
				Loc.format("hud.weapon_level", "niv. %d", [levels[index]]),
			]

		var ratio := 0.0
		if index < ratios.size():
			ratio = clampf(ratios[index], 0.0, 1.0)
		fill.size = Vector2(WEAPON_BAR_WIDTH * (1.0 - ratio), WEAPON_BAR_HEIGHT)

		var remaining := 0.0
		if index < seconds.size():
			remaining = seconds[index]
		status.text = "PRÊTE" if remaining <= 0.001 else "%.1f s" % remaining


## Refreshes the six equipment rows, one per body slot in Inventory.SLOTS order.
func update_equipment(inventory: Inventory) -> void:
	for index in _equipment_labels.size():
		var slot := String(Inventory.SLOTS[index])
		var title := String(_SLOT_TITLES.get(slot, slot))
		var item: EquipmentData = null
		if inventory != null:
			item = inventory.item_in_slot(slot)

		if item == null:
			_equipment_labels[index].text = "%s : —" % title
		else:
			_equipment_labels[index].text = "%s : %s · %s" % [
				title, item.display_name, item.effect_text()
			]


## Shows the large wave banner and restarts its fade timer. [param suffix] is
## appended after the wave number — a boss wave passes its boss line.
func show_wave_banner(wave_index: int, suffix: String = "") -> void:
	_wave_banner.text = "VAGUE %d" % (wave_index + 1)
	if not suffix.is_empty():
		_wave_banner.text += " · " + suffix
	_wave_banner.visible = true
	_wave_banner.modulate.a = 1.0
	_banner_time = BANNER_TIME


## Shows the boss health bar under its name, full.
func show_boss(display_name: String) -> void:
	_boss_name.text = display_name.to_upper()
	_boss_name.visible = true
	_boss_bar.visible = true
	_frame.set_boss_visible(true)
	update_boss(1.0, 1.0)


## Refreshes the boss health bar. The bar is a fraction, so a boss at 25 % shows
## a quarter of the strip whatever its maximum is.
func update_boss(hp: float, hp_max: float) -> void:
	var ratio := 0.0
	if hp_max > 0.0:
		ratio = clampf(hp / hp_max, 0.0, 1.0)
	_boss_fill.size = Vector2(BOSS_BAR_WIDTH * ratio, BOSS_BAR_HEIGHT)


## Hides the boss bar. Called when the boss dies, when the player dies and at
## run start.
func hide_boss() -> void:
	_boss_bar.visible = false
	if _frame != null:
		_frame.set_boss_visible(false)


## Flashes the whole screen red. The fade runs in _process, panel open or not.
func flash_damage() -> void:
	_flash_time = DAMAGE_FLASH_TIME
	_damage_flash.color = Color(0.75, 0.12, 0.10, DAMAGE_FLASH_ALPHA)
	_damage_flash.visible = true


## Shows the death banner.
func show_dead() -> void:
	_death_label.visible = true


## Hides the death banner.
func hide_dead() -> void:
	_death_label.visible = false


## Shows the end-of-run victory card with the level reached and the number of
## waves survived.
func show_victory(level: int, waves: int) -> void:
	_victory_detail.text = "Niveau %d · %d vagues" % [level, waves]
	_victory_panel.visible = true
	# The card owns the screen; a wave banner still fading behind it would cut
	# through the title.
	_banner_time = 0.0
	_wave_banner.visible = false


## Hides the victory card. Called at run start.
func hide_victory() -> void:
	_victory_panel.visible = false


## True while the level-up or boss-loot panel owns the screen, so a caller about
## to interrupt the run knows to wait for the choice first.
func panel_open() -> bool:
	return _upgrade_panel.visible


## Fills the three buttons from the given offers and shows the panel.
## Buttons must also respond to keys 1 2 3, to R for a reroll, and to gamepad
## focus + ui_accept. [param title] lets the caller label a boss-loot panel
## without a second panel scene.
func show_upgrade_choices(
	choices: Array[Offer], rerolls: int, title: String = LEVEL_UP_TITLE
) -> void:
	_panel_title.text = title
	_choice_count = mini(choices.size(), _options.size())
	for index in _options.size():
		var button := _options[index]
		var desc := _desc_labels[index]
		if index < _choice_count:
			var offer: Offer = choices[index]
			button.text = "%d. %s" % [index + 1, offer.title]
			desc.text = offer.description
			button.visible = true
			button.disabled = false
			desc.visible = true
		else:
			button.text = ""
			button.visible = false
			button.disabled = true
			desc.text = ""
			desc.visible = false

	if rerolls > 0:
		_reroll_label.text = "Relancer — R (%d restantes)" % rerolls
	else:
		_reroll_label.text = "Plus de relance"

	_accepting = true
	_upgrade_panel.visible = true
	# A modal panel owns the screen: the wave banner behind it would otherwise
	# cut through the first option.
	_banner_time = 0.0
	_wave_banner.visible = false
	if _choice_count > 0:
		_options[0].grab_focus()


## Hides the upgrade panel and releases the button focus.
func hide_upgrade_choices() -> void:
	_accepting = false
	_choice_count = 0
	_upgrade_panel.visible = false
	for button in _options:
		button.release_focus()


## Emits the choice for a completed press, once per press. Ignored when the
## panel is closed, so a leaked event cannot start a second upgrade.
func _on_option_pressed(index: int) -> void:
	if not _accepting or index < 0 or index >= _choice_count:
		return
	_accepting = false
	upgrade_chosen.emit(index)


## Number keys pick a choice, R asks for a reroll. Both are actions defined in
## `project.godot` (their key events are physical, so the number row works on
## non-QWERTY layouts). A reroll leaves the panel accepting input: the caller
## answers with a fresh show_upgrade_choices().
func _unhandled_key_input(event: InputEvent) -> void:
	if not _accepting:
		return

	if event.is_action_pressed("reroll"):
		get_viewport().set_input_as_handled()
		reroll_requested.emit()
		return

	var index := -1
	if event.is_action_pressed("choice_1"):
		index = 0
	elif event.is_action_pressed("choice_2"):
		index = 1
	elif event.is_action_pressed("choice_3"):
		index = 2
	if index < 0 or index >= _choice_count:
		return

	get_viewport().set_input_as_handled()
	_on_option_pressed(index)


## Fades the damage flash linearly to zero, then hides it.
func _update_damage_flash(delta: float) -> void:
	if _flash_time <= 0.0:
		return
	_flash_time = maxf(_flash_time - delta, 0.0)
	if _flash_time <= 0.0:
		_damage_flash.visible = false
		_damage_flash.color = Color(0.75, 0.12, 0.10, 0.0)
		return
	var alpha := DAMAGE_FLASH_ALPHA * (_flash_time / DAMAGE_FLASH_TIME)
	_damage_flash.color = Color(0.75, 0.12, 0.10, alpha)


## Fades the wave banner over its last moments, then hides it.
func _update_banner(delta: float) -> void:
	if _banner_time <= 0.0:
		return
	_banner_time = maxf(_banner_time - delta, 0.0)
	if _banner_time <= 0.0:
		_wave_banner.visible = false
		_wave_banner.modulate.a = 1.0
		return
	if _banner_time < _BANNER_FADE_TIME:
		_wave_banner.modulate.a = _banner_time / _BANNER_FADE_TIME
	else:
		_wave_banner.modulate.a = 1.0


## Pulses the four red screen edges while hp sits below LOW_HP_RATIO.
func _update_low_hp_edges(time: float) -> void:
	var low := _hp_ratio > 0.0 and _hp_ratio < LOW_HP_RATIO
	for rect in _low_hp_rects:
		rect.visible = low
		if low:
			var alpha := 0.25 + 0.15 * sin(time * 6.0)
			rect.color = Color(0.75, 0.2, 0.14, alpha)
