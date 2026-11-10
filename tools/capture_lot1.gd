## Retained evidence for lot 1 — weapon levels.
##
## Launches the real main scene, then stages two level-up panels on the same
## run: one where the only weapon candidate is a level for the carried weapon
## (the weapon pool is emptied so the row cannot be an acquisition), and one
## where the weapon is at max level and the row can only be a new weapon. The
## HUD behind each panel shows the same weapon at the staged level.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --windowed --resolution 1280x720 -s res://tools/capture_lot1.gd
extends SceneTree

const OUT_DIR := "res://production/qa/evidence/"
const UPGRADE_SHOT := "lot1-upgrade.png"
const ACQUISITION_SHOT := "lot1-acquisition.png"
const SHEET := "lot1-weapon-levels.png"

## Long enough for the scene to boot and the wave banner to clear.
const BOOT_FRAMES := 90
## Frames between staging a panel and capturing it, so the redraw reaches the GPU.
const SETTLE_FRAMES := 4
## Gap between the two panels in the composed sheet.
const GAP := 12

## The panel is a three-row draw; this weight makes a weapon row certain while
## leaving the other two rows to stats and equipment.
const FORCED_WEAPON_WEIGHT := 50.0

var _frames := 0
var _stage := 0
var _wait := 0
var _finished := false
var _main: Node = null
var _weapon: WeaponData = null
var _saved_pool: Array[WeaponData] = []


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
			if not _stage_upgrade():
				return _fail()
			_stage = 1
			_wait = 0
		1:
			if not _settle():
				return false
			if not _save(UPGRADE_SHOT):
				return _fail()
			if not _stage_acquisition():
				return _fail()
			_stage = 2
			_wait = 0
		2:
			if not _settle():
				return false
			if not _save(ACQUISITION_SHOT):
				return _fail()
			if not _compose():
				return _fail()
			_finished = true
			quit(0)
			return true
	return false


## Panel 1: carried weapon at level 2, no acquisition possible.
func _stage_upgrade() -> bool:
	_main.is_paused = true
	if _main._inventory.weapons.is_empty():
		push_error("capture: the run starts without a weapon")
		return false
	_weapon = _main._inventory.weapons[0]
	_saved_pool.assign(_main._weapon_pool)
	_main._weapon_pool.clear()
	_main._inventory.weapon_levels[_weapon.id] = 2
	_main._weapon_system.refresh()
	_main._refresh_hud()

	var choices: Array[Offer] = _main._build_offers(3, FORCED_WEAPON_WEIGHT)
	if not _has_kind(choices, "weapon_upgrade"):
		push_error("capture: the upgrade panel has no upgrade row")
		return false
	_main._offer_choices(choices)
	return true


## Panel 2: the same weapon at max level, so the row can only be an acquisition.
func _stage_acquisition() -> bool:
	_main._inventory.weapon_levels[_weapon.id] = _weapon.max_level
	_main._weapon_pool.assign(_saved_pool)
	_main._weapon_system.refresh()
	_main._refresh_hud()

	var choices: Array[Offer] = _main._build_offers(3, FORCED_WEAPON_WEIGHT)
	if not _has_kind(choices, "weapon"):
		push_error("capture: the acquisition panel has no weapon row")
		return false
	_main._offer_choices(choices)
	return true


## True when the panel holds an offer of [param kind].
func _has_kind(choices: Array[Offer], kind: String) -> bool:
	for offer in choices:
		if offer.kind == kind:
			return true
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


## Lays both panels side by side on a parchment backdrop.
func _compose() -> bool:
	var left := _load(UPGRADE_SHOT)
	var right := _load(ACQUISITION_SHOT)
	if left == null or right == null:
		return false
	left.convert(Image.FORMAT_RGBA8)
	right.convert(Image.FORMAT_RGBA8)
	var height := maxi(left.get_height(), right.get_height())
	var sheet := Image.create_empty(
		left.get_width() + right.get_width() + GAP * 3,
		height + GAP * 2,
		false,
		Image.FORMAT_RGBA8
	)
	sheet.fill(Color(0.91, 0.86, 0.72))
	sheet.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i(GAP, GAP))
	sheet.blit_rect(
		right,
		Rect2i(Vector2i.ZERO, right.get_size()),
		Vector2i(GAP * 2 + left.get_width(), GAP)
	)
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
