## Every creature in the game, drawn in ink.
##
## One file so the whole cast is written in a single hand: the knight, the three
## enemy archetypes and the boss, plus the XP crystal. The rules it follows are
## in `design/art/art-bible.md` — silhouette first, three tones, one accent.
##
## Each entry point takes the [CanvasItem] to paint on, so an actor calls it from
## its own [method CanvasItem._draw]. Sizes are fractions of the creature's
## radius, so a data change scales the whole drawing coherently.
class_name ActorArt
extends RefCounted

## Art keys accepted by [method draw_creature].
const ART_SKELETON := "skeleton"
const ART_ORC := "orc"
const ART_WOLF := "wolf"
const ART_BOSS := "boss"

## Bone, used by every skeleton and by the orc's tusks.
const BONE := Color(0.851, 0.812, 0.702)
const BONE_DARK := Color(0.663, 0.627, 0.529)
## XP only, in the whole game. Never decorative.
const GOLD := Color(0.851, 0.651, 0.149)
## Staffs and clubs.
const WOOD := Color(0.402, 0.290, 0.192)
## The knight's plate.
const STEEL := Color(0.400, 0.455, 0.541)
## The knight's accent, and the only red the player owns.
const TABARD := Color(0.706, 0.208, 0.196)
## Cloth behind the knight.
const CLOAK := Color(0.290, 0.212, 0.153)
## Threat accent: the boss's eyes, never a costume colour.
const DANGER := Color(0.75, 0.20, 0.14)

## Routes drawing to the shipped storybook renderer. STYLE_CURRENT remains as an
## escape hatch for comparison captures.
const VisualPilot := preload("res://src/art/visual_pilot.gd")


# --- the knight ---------------------------------------------------------


## Draws the player. [param view] is one of `front`, `back`, `left`, `right`;
## [param bob] is the breathing offset, already in pixels.
## Weapons are not drawn here: [WeaponView] owns them and rotates them itself.
static func draw_knight(item: CanvasItem, view: String, radius: float, bob: float) -> void:
	if VisualPilot.is_active():
		VisualPilot.draw_knight(item, view, radius, bob)
		return
	var s := radius
	InkStyle.shadow(item, Vector2(0.0, s * 0.98), s * 1.02)

	if view == "left" or view == "right":
		_knight_profile(item, s, bob, -1.0 if view == "left" else 1.0)
		return
	_knight_front_or_back(item, s, bob, view == "back")


static func _knight_front_or_back(
	item: CanvasItem, s: float, bob: float, is_back: bool
) -> void:
	# From behind, the cape is the read. From the front it must not be: anything
	# wider than the tapering torso bottom shows as a flat brown base and the
	# knight reads as standing in front of a stool. So the front has no cape at
	# all — the tabard, the pauldrons and the helm carry it.
	if is_back:
		var cape := PackedVector2Array([
			Vector2(-0.52 * s, -0.22 * s + bob),
			Vector2(0.52 * s, -0.22 * s + bob),
			Vector2(0.88 * s, 1.02 * s + bob),
			Vector2(0.0, 1.24 * s + bob),
			Vector2(-0.88 * s, 1.02 * s + bob),
		])
		InkStyle.shaded(item, cape, CLOAK)

	var torso := PackedVector2Array([
		Vector2(-0.60 * s, -0.28 * s + bob),
		Vector2(0.60 * s, -0.28 * s + bob),
		Vector2(0.58 * s, 0.54 * s + bob),
		Vector2(0.32 * s, 0.92 * s + bob),
		Vector2(0.0, 1.02 * s + bob),
		Vector2(-0.32 * s, 0.92 * s + bob),
		Vector2(-0.58 * s, 0.54 * s + bob),
	])
	InkStyle.shaded(item, torso, STEEL)

	# The surcoat is the player's accent: the one saturated red on the field, so
	# finding yourself among sixty enemies is a glance, not a search. It covers
	# most of the torso rather than a stripe down it — at 28 px a stripe is three
	# pixels of red and the knight reads as another pale biped beside a skeleton.
	var tabard := PackedVector2Array([
		Vector2(-0.40 * s, -0.24 * s + bob),
		Vector2(0.40 * s, -0.24 * s + bob),
		Vector2(0.34 * s, 0.56 * s + bob),
		Vector2(0.26 * s, 0.88 * s + bob),
		Vector2(0.0 * s, 1.02 * s + bob),
		Vector2(-0.26 * s, 0.88 * s + bob),
		Vector2(-0.34 * s, 0.56 * s + bob),
	])
	InkStyle.outlined(item, tabard, TABARD, 1.5)

	# Pauldrons darker than the helm, never lighter: same value as the helm and
	# the head merges into the shoulders, which is the one thing the knight's
	# silhouette cannot afford at 28 px.
	var shoulder := InkStyle.dark_of(STEEL, 0.14)
	InkStyle.ellipse(item, Vector2(-0.72 * s, -0.16 * s + bob), 0.34 * s, 0.30 * s, shoulder)
	InkStyle.ellipse(item, Vector2(0.72 * s, -0.16 * s + bob), 0.34 * s, 0.30 * s, shoulder)

	InkStyle.circle(item, Vector2(0.0, -0.74 * s + bob), 0.44 * s, InkStyle.light_of(STEEL, 0.20))

	if is_back:
		# No visor from behind: a single ridge line and the cloak's fold instead,
		# so front and back are never confused for one another.
		InkStyle.detail(item, Vector2(-0.30 * s, -0.74 * s + bob), Vector2(0.30 * s, -0.74 * s + bob), 1.5)
		InkStyle.detail(item, Vector2(0.0, 0.30 * s + bob), Vector2(0.0, 1.10 * s + bob), 1.5)
		return

	var visor := PackedVector2Array([
		Vector2(-0.28 * s, -0.84 * s + bob),
		Vector2(0.28 * s, -0.84 * s + bob),
		Vector2(0.28 * s, -0.68 * s + bob),
		Vector2(-0.28 * s, -0.68 * s + bob),
	])
	item.draw_colored_polygon(visor, InkStyle.INK)
	InkStyle.detail(
		item,
		Vector2(-0.26 * s, -0.87 * s + bob),
		Vector2(0.26 * s, -0.87 * s + bob),
		1.5,
		Color(1.0, 1.0, 1.0, 0.35)
	)


## Profile view. [param dir] is -1 facing left, +1 facing right; every x is
## mirrored through it so one drawing serves both sides.
static func _knight_profile(item: CanvasItem, s: float, bob: float, dir: float) -> void:
	var cloak := PackedVector2Array([
		Vector2(0.42 * s * dir, 0.00 * s + bob),
		Vector2(-0.30 * s * dir, 0.06 * s + bob),
		Vector2(-0.52 * s * dir, 1.14 * s + bob),
		Vector2(-0.10 * s * dir, 1.24 * s + bob),
		Vector2(0.34 * s * dir, 1.06 * s + bob),
	])
	InkStyle.shaded(item, cloak, InkStyle.dark_of(CLOAK, 0.25))

	var torso := PackedVector2Array([
		Vector2(-0.34 * s * dir, -0.26 * s + bob),
		Vector2(0.38 * s * dir, -0.26 * s + bob),
		Vector2(0.34 * s * dir, 0.56 * s + bob),
		Vector2(0.10 * s * dir, 0.96 * s + bob),
		Vector2(-0.30 * s * dir, 0.90 * s + bob),
	])
	InkStyle.shaded(item, torso, STEEL)

	var tabard := PackedVector2Array([
		Vector2(-0.16 * s * dir, -0.20 * s + bob),
		Vector2(0.14 * s * dir, -0.20 * s + bob),
		Vector2(0.12 * s * dir, 0.70 * s + bob),
		Vector2(-0.02 * s * dir, 0.88 * s + bob),
		Vector2(-0.18 * s * dir, 0.62 * s + bob),
	])
	InkStyle.outlined(item, tabard, TABARD, 1.5)

	# One pauldron only: in profile the near shoulder hides the far one.
	InkStyle.ellipse(
		item, Vector2(-0.10 * s * dir, -0.22 * s + bob), 0.30 * s, 0.28 * s,
		InkStyle.dark_of(STEEL, 0.14)
	)

	InkStyle.circle(item, Vector2(0.08 * s * dir, -0.74 * s + bob), 0.42 * s, InkStyle.light_of(STEEL, 0.20))

	# Visor wedge, pointing the way the knight faces: the clearest direction
	# read on the whole player sprite.
	var visor := PackedVector2Array([
		Vector2(0.20 * s * dir, -0.86 * s + bob),
		Vector2(0.50 * s * dir, -0.72 * s + bob),
		Vector2(0.20 * s * dir, -0.64 * s + bob),
	])
	item.draw_colored_polygon(visor, InkStyle.INK)


# --- enemies ------------------------------------------------------------


## Draws an enemy body. [param art] selects the archetype, [param radius] is the
## creature's collision radius, [param tint] is its data colour — which the art
## treats as the body hue, so recolouring a `.tres` recolours the creature — and
## [param flash] is the hit-flash overlay, transparent when not flashing.
static func draw_creature(
	item: CanvasItem, art: String, radius: float, tint: Color, flash: Color
) -> void:
	if VisualPilot.is_active():
		VisualPilot.draw_creature(item, art, radius, tint, flash)
		return
	var r := radius
	match art:
		ART_ORC:
			_orc(item, r, tint)
		ART_WOLF:
			_wolf(item, r, tint)
		ART_BOSS:
			_boss(item, r, tint)
		_:
			_skeleton(item, r, tint)

	if flash.a > 0.0:
		# A single silhouette-wide wash rather than per-part recolouring: at
		# 0.08 s the player reads "it was hit", not "each rib changed colour".
		item.draw_colored_polygon(
			InkStyle.ellipse_points(Vector2(0.0, -0.10 * r), r * 0.82, r * 1.05),
			flash
		)


## Narrow, vertical, round skull. Deliberately the thinnest silhouette: a wolf
## is horizontal and an orc is wide, so the three read apart at a glance.
static func _skeleton(item: CanvasItem, r: float, tint: Color) -> void:
	InkStyle.shadow(item, Vector2(0.0, 0.96 * r), 0.86 * r)

	var leg := InkStyle.dark_of(tint, 0.32)
	# Legs are drawn before the ribcage but reach well below it: a skeleton with
	# no visible legs reads as a bib with a skull on top.
	InkStyle.detail(item, Vector2(-0.18 * r, 0.30 * r), Vector2(-0.24 * r, 0.96 * r), 3.2, leg)
	InkStyle.detail(item, Vector2(0.18 * r, 0.30 * r), Vector2(0.24 * r, 0.96 * r), 3.2, leg)

	var ribs := PackedVector2Array([
		Vector2(-0.32 * r, -0.34 * r),
		Vector2(0.32 * r, -0.34 * r),
		Vector2(0.24 * r, 0.26 * r),
		Vector2(0.0, 0.40 * r),
		Vector2(-0.24 * r, 0.26 * r),
	])
	InkStyle.outlined(item, ribs, tint)
	# Spine, then ribs branching off it: what makes the volume read as a cage
	# rather than a shield.
	InkStyle.detail(item, Vector2(0.0, -0.30 * r), Vector2(0.0, 0.36 * r), 1.8)
	for row in 3:
		var y := (-0.20 + float(row) * 0.17) * r
		var half := (0.24 - float(row) * 0.03) * r
		InkStyle.detail(item, Vector2(-half, y), Vector2(half, y - 0.03 * r), 1.6)

	# Arms after the cage, not before: drawn underneath they vanish and the
	# skeleton becomes a white robe with a skull floating on it.
	InkStyle.detail(item, Vector2(-0.28 * r, -0.20 * r), Vector2(-0.50 * r, 0.28 * r), 3.0, leg)
	InkStyle.detail(item, Vector2(0.28 * r, -0.20 * r), Vector2(0.50 * r, 0.28 * r), 3.0, leg)

	var skull := Vector2(0.0, -0.72 * r)
	InkStyle.circle(item, skull, 0.48 * r, InkStyle.light_of(tint, 0.10))
	item.draw_circle(skull + Vector2(-0.17 * r, -0.02 * r), 0.12 * r, InkStyle.INK)
	item.draw_circle(skull + Vector2(0.17 * r, -0.02 * r), 0.12 * r, InkStyle.INK)
	InkStyle.detail(
		item, skull + Vector2(-0.13 * r, 0.24 * r), skull + Vector2(0.13 * r, 0.24 * r), 1.6
	)


## Wide and low: shoulders pushed outside the torso and a club leaning off one
## side, so the outline is unmistakably broader than tall.
static func _orc(item: CanvasItem, r: float, tint: Color) -> void:
	InkStyle.shadow(item, Vector2(0.0, 0.98 * r), 1.05 * r, 0.36)

	var dark := InkStyle.dark_of(tint, 0.42)
	# Feet, reaching below the belly: an orc with no feet is a shrub.
	InkStyle.ellipse(item, Vector2(-0.28 * r, 0.92 * r), 0.20 * r, 0.11 * r, dark, 1.4)
	InkStyle.ellipse(item, Vector2(0.28 * r, 0.92 * r), 0.20 * r, 0.11 * r, dark, 1.4)
	InkStyle.detail(item, Vector2(-0.26 * r, 0.40 * r), Vector2(-0.28 * r, 0.86 * r), 5.0, dark)
	InkStyle.detail(item, Vector2(0.26 * r, 0.40 * r), Vector2(0.28 * r, 0.86 * r), 5.0, dark)

	# Club, held out to the side and clear of the body. Tucked behind the torso it
	# read as a second head growing out of the orc's ear.
	var club_grip := Vector2(0.66 * r, 0.34 * r)
	var club_head := Vector2(1.02 * r, -0.54 * r)
	InkStyle.detail(item, club_grip, club_head, 6.0, InkStyle.INK)
	InkStyle.detail(item, club_grip, club_head, 3.5, WOOD)
	InkStyle.circle(item, club_head, 0.24 * r, WOOD)

	InkStyle.ellipse(item, Vector2(0.0, 0.10 * r), 0.58 * r, 0.54 * r, tint)
	InkStyle.ellipse(
		item, Vector2(-0.18 * r, -0.08 * r), 0.32 * r, 0.26 * r,
		InkStyle.light_of(tint, 0.16), 0.0
	)
	# A leather band splits the green mass in two and separates the orc from the
	# grass it stands on, which is nearly the same value.
	var belt := PackedVector2Array([
		Vector2(-0.52 * r, 0.22 * r),
		Vector2(0.52 * r, 0.22 * r),
		Vector2(0.50 * r, 0.36 * r),
		Vector2(-0.50 * r, 0.36 * r),
	])
	InkStyle.outlined(item, belt, WOOD, 1.2)

	var shoulder := InkStyle.dark_of(tint, 0.20)
	InkStyle.ellipse(item, Vector2(-0.64 * r, -0.28 * r), 0.30 * r, 0.27 * r, shoulder)
	InkStyle.ellipse(item, Vector2(0.64 * r, -0.28 * r), 0.30 * r, 0.27 * r, shoulder)

	var head := Vector2(0.0, -0.76 * r)
	InkStyle.circle(item, head, 0.38 * r, InkStyle.light_of(tint, 0.10))
	InkStyle.detail(
		item, head + Vector2(-0.24 * r, -0.10 * r), head + Vector2(0.24 * r, -0.10 * r), 1.6
	)
	item.draw_circle(head + Vector2(-0.13 * r, -0.16 * r), 0.085 * r, InkStyle.INK)
	item.draw_circle(head + Vector2(0.13 * r, -0.16 * r), 0.085 * r, InkStyle.INK)

	# Tusks: the one bone accent and the second half of the read.
	for side in [-1.0, 1.0]:
		var tusk := PackedVector2Array([
			head + Vector2(0.09 * r * side, 0.24 * r),
			head + Vector2(0.25 * r * side, 0.22 * r),
			head + Vector2(0.27 * r * side, -0.02 * r),
		])
		InkStyle.outlined(item, tusk, BONE, 1.3)


## Horizontal. The only creature wider than it is tall, and the only cool grey
## on the field, so a pack reads as a pack without any of them being distinct.
static func _wolf(item: CanvasItem, r: float, tint: Color) -> void:
	InkStyle.shadow(item, Vector2(0.0, 0.92 * r), 0.92 * r, 0.34)

	var leg := InkStyle.dark_of(tint, 0.42)

	# Tail, sweeping out to the side behind the body: the one horizontal cue that
	# keeps the wolf apart from every upright archetype at a glance.
	InkStyle.detail(item, Vector2(0.52 * r, 0.30 * r), Vector2(1.16 * r, -0.10 * r), 5.0, InkStyle.INK)
	InkStyle.detail(item, Vector2(0.52 * r, 0.30 * r), Vector2(1.12 * r, -0.08 * r), 2.8, InkStyle.dark_of(tint, 0.30))

	InkStyle.detail(item, Vector2(-0.34 * r, 0.46 * r), Vector2(-0.40 * r, 0.94 * r), 3.6, leg)
	InkStyle.detail(item, Vector2(-0.12 * r, 0.50 * r), Vector2(-0.14 * r, 0.96 * r), 3.6, leg)
	InkStyle.detail(item, Vector2(0.12 * r, 0.50 * r), Vector2(0.14 * r, 0.96 * r), 3.6, leg)
	InkStyle.detail(item, Vector2(0.34 * r, 0.46 * r), Vector2(0.40 * r, 0.94 * r), 3.6, leg)

	# Body: wider than tall, chest lighter than the back.
	InkStyle.ellipse(item, Vector2(0.0, 0.24 * r), 0.60 * r, 0.52 * r, tint)
	InkStyle.ellipse(
		item, Vector2(0.0, 0.30 * r), 0.34 * r, 0.34 * r, InkStyle.light_of(tint, 0.16), 0.0
	)

	# Head low over the chest, long muzzle pointing at the player. The muzzle is
	# what reads "beast": without it the round head is just another skull.
	var head := Vector2(0.0, -0.48 * r)
	InkStyle.circle(item, head, 0.40 * r, InkStyle.light_of(tint, 0.06))
	var muzzle := PackedVector2Array([
		head + Vector2(-0.20 * r, 0.08 * r),
		head + Vector2(-0.13 * r, 0.50 * r),
		head + Vector2(0.0, 0.60 * r),
		head + Vector2(0.13 * r, 0.50 * r),
		head + Vector2(0.20 * r, 0.08 * r),
	])
	InkStyle.outlined(item, muzzle, InkStyle.dark_of(tint, 0.10), 1.8)
	item.draw_circle(head + Vector2(0.0, 0.46 * r), 0.09 * r, InkStyle.INK)

	item.draw_circle(head + Vector2(-0.16 * r, -0.06 * r), 0.075 * r, InkStyle.INK)
	item.draw_circle(head + Vector2(0.16 * r, -0.06 * r), 0.075 * r, InkStyle.INK)

	# Short, wide-set ears. Tall ears turned the whole animal into a bat.
	for side in [-1.0, 1.0]:
		var ear := PackedVector2Array([
			head + Vector2(0.16 * r * side, -0.30 * r),
			head + Vector2(0.38 * r * side, -0.56 * r),
			head + Vector2(0.42 * r * side, -0.18 * r),
		])
		InkStyle.outlined(item, ear, InkStyle.dark_of(tint, 0.18), 1.5)


## Tall, caped, crowned. The boss is not a bigger skeleton: it is a different
## silhouette — a broad cape under an angular skull — so the wave's threat is
## never mistaken for two skeletons standing close together.
static func _boss(item: CanvasItem, r: float, tint: Color) -> void:
	InkStyle.shadow(item, Vector2(0.0, 1.12 * r), 1.24 * r, 0.34)

	var cape := PackedVector2Array([
		Vector2(-0.86 * r, -0.52 * r),
		Vector2(0.86 * r, -0.52 * r),
		Vector2(1.24 * r, 1.16 * r),
		Vector2(0.72 * r, 1.02 * r),
		Vector2(0.24 * r, 1.20 * r),
		Vector2(-0.24 * r, 1.02 * r),
		Vector2(-0.72 * r, 1.20 * r),
		Vector2(-1.24 * r, 1.06 * r),
	])
	InkStyle.shaded(item, cape, InkStyle.dark_of(tint, 0.10))

	# Staff, behind the body, opposite the cape's light side.
	var staff_foot := Vector2(0.92 * r, 0.92 * r)
	var staff_top := Vector2(1.02 * r, -1.02 * r)
	InkStyle.detail(item, staff_foot, staff_top, 5.0, InkStyle.INK)
	InkStyle.detail(item, staff_foot, staff_top, 3.0, WOOD)
	InkStyle.glow(item, staff_top + Vector2(0.0, -0.16 * r), 0.26 * r, DANGER)

	var ribs := PackedVector2Array([
		Vector2(-0.38 * r, -0.46 * r),
		Vector2(0.38 * r, -0.46 * r),
		Vector2(0.30 * r, 0.48 * r),
		Vector2(0.0, 0.68 * r),
		Vector2(-0.30 * r, 0.48 * r),
	])
	InkStyle.outlined(item, ribs, BONE)
	InkStyle.detail(item, Vector2(0.0, -0.40 * r), Vector2(0.0, 0.62 * r), 2.0)
	for row in 4:
		var y := (-0.28 + float(row) * 0.18) * r
		var half := (0.28 - float(row) * 0.03) * r
		InkStyle.detail(item, Vector2(-half, y), Vector2(half, y - 0.03 * r), 1.6)

	var leg := InkStyle.dark_of(BONE, 0.14)
	InkStyle.detail(item, Vector2(-0.22 * r, 0.60 * r), Vector2(-0.28 * r, 1.10 * r), 3.5, leg)
	InkStyle.detail(item, Vector2(0.22 * r, 0.60 * r), Vector2(0.28 * r, 1.10 * r), 3.5, leg)

	var skull := Vector2(0.0, -0.94 * r)
	InkStyle.circle(item, skull, 0.48 * r, InkStyle.light_of(BONE, 0.08))
	# Angular jaw: a wedge under the skull, the detail that separates this skull
	# from the plain skeleton's round one.
	var jaw := PackedVector2Array([
		skull + Vector2(-0.20 * r, 0.20 * r),
		skull + Vector2(0.20 * r, 0.20 * r),
		skull + Vector2(0.0, 0.44 * r),
	])
	InkStyle.outlined(item, jaw, BONE, 1.4)

	InkStyle.glow(item, skull + Vector2(-0.17 * r, -0.04 * r), 0.11 * r, DANGER)
	InkStyle.glow(item, skull + Vector2(0.17 * r, -0.04 * r), 0.11 * r, DANGER)

	var crown := PackedVector2Array([
		skull + Vector2(-0.40 * r, -0.32 * r),
		skull + Vector2(-0.46 * r, -0.62 * r),
		skull + Vector2(-0.20 * r, -0.44 * r),
		skull + Vector2(0.0, -0.68 * r),
		skull + Vector2(0.20 * r, -0.44 * r),
		skull + Vector2(0.46 * r, -0.62 * r),
		skull + Vector2(0.40 * r, -0.32 * r),
	])
	InkStyle.outlined(item, crown, BONE_DARK, 1.6)


# --- pickups ------------------------------------------------------------


## The XP crystal: a faceted gem, gold, with one specular fleck that turns.
## [param t] is elapsed seconds, used only for the fleck.
static func draw_gem(item: CanvasItem, radius: float, t: float) -> void:
	var r := radius
	var outer := PackedVector2Array([
		Vector2(0.0, -1.0 * r),
		Vector2(0.74 * r, 0.0),
		Vector2(0.0, 1.0 * r),
		Vector2(-0.74 * r, 0.0),
	])
	InkStyle.outlined(item, outer, GOLD, 1.4)

	# Two facets give the crystal a body without letting it read as a flat icon.
	item.draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, -1.0 * r),
			Vector2(-0.74 * r, 0.0),
			Vector2(0.0, 0.10 * r),
		]),
		InkStyle.light_of(GOLD, 0.45)
	)
	item.draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, 1.0 * r),
			Vector2(0.74 * r, 0.0),
			Vector2(0.0, 0.10 * r),
		]),
		InkStyle.dark_of(GOLD, 0.22)
	)

	var fleck_angle := t * 1.4
	item.draw_circle(
		Vector2(cos(fleck_angle) * 0.26 * r, sin(fleck_angle) * 0.26 * r) + Vector2(0.0, -0.34 * r),
		0.13 * r,
		Color(1.0, 1.0, 1.0, 0.85)
	)
