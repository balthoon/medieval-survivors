## Retained evidence for lot 3 — equipment identity.
##
## Launches the real main scene, wears the Colosse pair plus the two passive
## pieces, then stages a level-up panel whose rows are equipment offers. Three
## shots are stacked: the HUD with its set summary, rage marker and completed-set
## diamonds; the offer panel with the set/passive lines; and the real level-up
## panel, whose title reports the health the amulet actually restored.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --windowed --resolution 1280x720 -s res://tools/capture_lot3.gd
extends SceneTree

const OUT_DIR := "res://production/qa/evidence/"
const HUD_SHOT := "lot3-hud.png"
const OFFER_SHOT := "lot3-offer.png"
const HEAL_SHOT := "lot3-levelup-heal.png"
const SHEET := "lot3-equipment-identity.png"

## Long enough for the scene to boot and the wave banner to clear.
const BOOT_FRAMES := 90
## Frames between staging a panel and capturing it, so the redraw reaches the GPU.
const SETTLE_FRAMES := 4
## Gap between the two shots in the composed sheet.
const GAP := 12

var _frames := 0
var _stage := 0
var _wait := 0
var _finished := false
var _main: Node = null


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("capture: could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	if _main == null:
		push_error("capture: could not instantiate main scene")
		quit(1)
		return
	root.add_child(_main)


func _process(_delta: float) -> bool:
	if _finished or _main == null:
		return true
	_frames += 1

	match _stage:
		0:
			if _frames < BOOT_FRAMES:
				return false
			if not _stage_hud():
				return _fail()
			_stage = 1
			_wait = 0
		1:
			if not _settle():
				return false
			if not _save(HUD_SHOT):
				return _fail()
			if not _stage_offer():
				return _fail()
			_stage = 2
			_wait = 0
		2:
			if not _settle():
				return false
			if not _save(OFFER_SHOT):
				return _fail()
			if not _stage_level_up():
				return _fail()
			_stage = 3
			_wait = 0
		3:
			if not _settle():
				return false
			if not _save(HEAL_SHOT):
				return _fail()
			if not _compose():
				return _fail()
			_finished = true
			quit(0)
			return true
	return false


## Wears a complete Colosse set and both passive pieces, then refreshes the HUD.
func _stage_hud() -> bool:
	_main.is_paused = true
	if not _equip("casque_fer") or not _equip("plastron_mailles"):
		return false
	if not _equip("anneau_rubis") or not _equip("amulette_sang"):
		return false
	_main._recompute_stats()
	# Below half health, so the HUD shows the rage word marker on the ring line
	# and the summary line carries a completed set.
	_main._player.hp = _main._player.stats.max_hp * 0.4
	_main._recompute_stats()
	_main._refresh_hud()
	return true


## A panel of equipment offers: the Duelliste helmet (progress), its gloves, and
## the Coureur ring. Each row carries its own stat line, passive or set line.
func _stage_offer() -> bool:
	var items := ["casque_ancien", "gants_precis", "anneau_argent"]
	var choices: Array[Offer] = []
	for id in items:
		var item: EquipmentData = _main.catalogue.equipment_by_id(id)
		if item == null:
			push_error("capture: catalogue has no '%s'" % id)
			return false
		var offer := Offer.for_equipment(item)
		_main._decorate_offer(offer)
		choices.append(offer)
	_main._offer_choices(choices)
	return true


## Closes the staged panel and opens the real level-up panel. The amulet is worn
## and the player is hurt, so the title reports the health actually restored.
func _stage_level_up() -> bool:
	_main._hud.hide_upgrade_choices()
	_main.is_paused = false
	_main._xp = _main._xp_needed
	_main._check_level_up()
	if not _main._hud.panel_open():
		push_error("capture: the level-up panel did not open")
		return false
	return true


## Equips a catalogue piece through the run's own path and reports its absence.
func _equip(id: String) -> bool:
	var item: EquipmentData = _main.catalogue.equipment_by_id(id)
	if item == null:
		push_error("capture: catalogue has no '%s'" % id)
		return false
	_main._inventory.equip(item)
	return true


func _settle() -> bool:
	_wait += 1
	return _wait > SETTLE_FRAMES


## Saves the last rendered frame, or reports why it could not.
func _save(file_name: String) -> bool:
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty for " + file_name)
		return false
	var abs_path := ProjectSettings.globalize_path(OUT_DIR + file_name)
	var err := image.save_png(abs_path)
	print("capture: %s save_err=%d path=%s" % [file_name, err, abs_path])
	return err == OK


## Stacks the three shots on a parchment backdrop, keeping every pixel readable.
func _compose() -> bool:
	var shots: Array[Image] = [_load(HUD_SHOT), _load(OFFER_SHOT), _load(HEAL_SHOT)]
	for shot in shots:
		if shot == null:
			return false
	var width := 0
	var height := GAP
	for shot in shots:
		shot.convert(Image.FORMAT_RGBA8)
		width = maxi(width, shot.get_width())
		height += shot.get_height() + GAP
	var sheet := Image.create_empty(width + GAP * 2, height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.91, 0.86, 0.72))
	var y := GAP
	for shot in shots:
		sheet.blit_rect(
			shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(GAP, y)
		)
		y += shot.get_height() + GAP
	var abs_path := ProjectSettings.globalize_path(OUT_DIR + SHEET)
	var err := sheet.save_png(abs_path)
	print("capture: %s save_err=%d path=%s" % [SHEET, err, abs_path])
	return err == OK


func _load(file_name: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(OUT_DIR + file_name))
	if image == null or image.is_empty():
		push_error("capture: could not load " + file_name)
		return null
	return image


func _fail() -> bool:
	_finished = true
	quit(1)
	return true
