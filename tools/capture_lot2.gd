## Retained evidence for lot 2 — weapon evolutions.
##
## Launches the real main scene, brings the starting sword to its evolution
## level, and builds the real level-up panel: the evolution is the first row,
## highlighted, with the kept level and the new cap in its description. The
## second shot takes the offer through the run's own path, so the evolution
## banner and the weapon row after the evolution are the ones a player sees.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --windowed --resolution 1280x720 --position -2400,-1400 \
##     -s res://tools/capture_lot2.gd
extends SceneTree

const OUT_DIR := "res://production/qa/evidence/"
const OFFER_SHOT := "lot2-evolution-offer.png"
const HUD_SHOT := "lot2-evolution-hud.png"
const SHEET := "lot2-weapon-evolutions.png"

## Long enough for the scene to boot and the wave banner to clear.
const BOOT_FRAMES := 90
## Frames between staging a panel and capturing it, so the redraw reaches the GPU.
const SETTLE_FRAMES := 4
## Gap above and between the two shots in the composed sheet.
const GAP := 12

var _frames := 0
var _stage := 0
var _wait := 0
var _finished := false
var _main: Node = null
var _evolution: Offer = null


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
			if not _stage_offer():
				return _fail()
			_stage = 1
			_wait = 0
		1:
			if not _settle():
				return false
			if not _save(OFFER_SHOT):
				return _fail()
			if not _stage_evolution():
				return _fail()
			_stage = 2
			_wait = 0
		2:
			if not _settle():
				return false
			if not _save(HUD_SHOT):
				return _fail()
			if not _compose():
				return _fail()
			_finished = true
			quit(0)
			return true
	return false


## Brings the carried sword to its evolution level and opens the real panel, so
## the first row is the highlighted evolution offer the player would see.
func _stage_offer() -> bool:
	_main.is_paused = true
	if _main._inventory.weapons.is_empty():
		push_error("capture: the run carries no weapon")
		return false
	var weapon: WeaponData = _main._inventory.weapons[0]
	_main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var choices: Array[Offer] = _main._build_offers(3)
	if choices.is_empty() or choices[0].kind != "weapon_evolution":
		push_error("capture: the evolution is not the first row of its panel")
		return false
	_evolution = choices[0]
	_main._offer_choices(choices)
	return _main._hud.panel_open()


## Takes the evolution through the run's own path, then clears the panel so the
## HUD, its banner and the evolved weapon row are visible together.
func _stage_evolution() -> bool:
	if _evolution == null:
		return false
	_main._hud.hide_upgrade_choices()
	_main._apply_offer(_evolution)
	_main.is_paused = true
	_main._refresh_hud()
	if not _main._inventory.evolved_weapon_id.is_empty():
		return true
	push_error("capture: the evolution did not apply")
	return false


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


## Stacks the two shots on a parchment backdrop, keeping every pixel readable.
func _compose() -> bool:
	var shots: Array[Image] = [_load(OFFER_SHOT), _load(HUD_SHOT)]
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
