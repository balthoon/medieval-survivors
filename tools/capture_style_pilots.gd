## Evidence capture for the three visual-direction mockups.
##
## Loads the real scene, builds one fixed tableau — the knight with three
## weapons, two skeletons, an orc, a wolf, the boss and a few XP gems — then
## captures it once per direction. Only the art style changes between frames;
## the HUD, the weapons and the composition are identical, so the comparison is
## honest.
##
## Must run windowed, not headless: a headless viewport texture comes back empty.
##
##   godot --path . --script res://tools/capture_style_pilots.gd
extends SceneTree

const VisualPilot := preload("res://src/art/visual_pilot.gd")

const OUT_PATHS: Array[String] = [
	"res://production/qa/evidence/style-pilot-a-storybook.png",
	"res://production/qa/evidence/style-pilot-b-woodcut.png",
	"res://production/qa/evidence/style-pilot-c-mist.png",
]
## 1, 2, 3 are storybook, woodcut and mist, in [VisualPilot]'s order.
const STYLE_IDS: Array[int] = [1, 2, 3]
const WEAPONS := [
	"res://data/weapons/faux.tres",
	"res://data/weapons/orbe.tres",
	"res://data/weapons/encensoir.tres",
]
const GEM_SPOTS := [
	Vector2(486.0, 300.0),
	Vector2(786.0, 330.0),
	Vector2(526.0, 480.0),
	Vector2(740.0, 208.0),
]
## Frames to let the scene settle before the first style is applied, and frames
## per style before its frame is read. At 60 fps this is a little over half a
## second per shot.
const SETTLE := 36

var _frames := 0
var _shot := 0
var _settle := 0
var _main: Node = null
var _player: Player = null
var _decor: ArenaDecor = null
var _container: Node2D = null
var _manager: EnemyManager = null
var _overlay: PilotOverlay = null


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
	_frames += 1
	if _frames < 3:
		return false
	if _frames == 3:
		_arm()
		return false
	if _shot >= STYLE_IDS.size():
		return true

	if _settle == 0:
		_apply_style(STYLE_IDS[_shot])
	_settle += 1
	if _settle < SETTLE:
		return false

	if not _save(OUT_PATHS[_shot]):
		quit(1)
		return true

	_shot += 1
	_settle = 0
	if _shot >= STYLE_IDS.size():
		quit(0)
		return true
	return false


## Builds the tableau once, before any style is selected.
func _arm() -> void:
	# The wave director is the only spawner: disconnect its tick so no wave
	# enemy wanders into the comparison after the tableau is built.
	var director: Variant = _main.get("_wave_director")
	if director != null and director.spawn_tick.is_connected(_main._on_spawn_tick):
		director.spawn_tick.disconnect(_main._on_spawn_tick)

	_player = _main.get_node("Player") as Player
	_decor = _main.get_node("Arena/ArenaDecor") as ArenaDecor
	_container = _main.get_node("Enemies") as Node2D
	_manager = _main.get_node("EnemyManager") as EnemyManager

	# The player faces the camera, so all three captures show the same face and
	# the same crest instead of a random profile.
	_player.facing = PI * 0.5
	_player.queue_redraw()

	# Clear whatever the first frames of the wave spawned.
	for child in _container.get_children():
		child.queue_free()

	_main._inventory.weapons.clear()
	for path: String in WEAPONS:
		_main._gain_weapon(load(path))

	_spawn_dummy("res://data/enemies/squelette.tres", Vector2(586.0, 360.0))
	_spawn_dummy("res://data/enemies/squelette.tres", Vector2(612.0, 294.0))
	_spawn_dummy("res://data/enemies/orc.tres", Vector2(748.0, 400.0))
	_spawn_dummy("res://data/enemies/loup_maudit.tres", Vector2(704.0, 456.0))
	_spawn_dummy("res://data/enemies/seigneur_squelette.tres", Vector2(836.0, 254.0))

	var pickups := _main.get_node("Pickups") as Node2D
	for spot: Vector2 in GEM_SPOTS:
		pickups.add_child(XpPickup.create(1, spot))

	# Transient start-of-run furniture is not part of the comparison.
	var banner := _main.get_node_or_null("HUD/WaveBanner") as Control
	if banner != null:
		banner.visible = false

	_overlay = PilotOverlay.new()
	_overlay.player = _player
	_main.add_child(_overlay)


## One stationary, harmless, unkillable dummy holding the archetype's real art.
func _spawn_dummy(path: String, at: Vector2) -> void:
	var data := (load(path) as EnemyData).duplicate() as EnemyData
	data.max_hp = 9999
	data.move_speed = 0.0
	data.contact_damage = 0.0
	data.slam_damage = 0.0
	data.slam_cooldown = 99999.0
	data.knockback_resistance = 1.0
	data.is_elite = false
	_manager.spawn(data, at, _container)


func _apply_style(style: int) -> void:
	VisualPilot.set_style(style)
	_decor.queue_redraw()
	_player.queue_redraw()
	for child in _container.get_children():
		if child is CanvasItem:
			(child as CanvasItem).queue_redraw()
	_overlay.queue_redraw()


func _save(path: String) -> bool:
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		push_error("capture: viewport image is empty")
		return false
	var abs_path := ProjectSettings.globalize_path(path)
	var err := image.save_png(abs_path)
	print("capture: frame=%d style=%d save_err=%d path=%s" % [_frames, STYLE_IDS[_shot], err, abs_path])
	return err == OK
