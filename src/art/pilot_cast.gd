## Detailed cast for the three visual-direction mockups.
##
## One geometry per creature, rendered through [PilotPalette]: the knight, the
## three archetypes and the boss. The palette decides whether a shape gets soft
## watercolour bands (storybook), flat plates and knife cuts (woodcut), or a dark
## body with a cold moon rim (mist). Nothing here runs in the shipped game.
extends RefCounted

const H := preload("res://src/art/pilot_helpers.gd")

## Muted blue-grey rags on the undead. Storybook and mist only; woodcut uses ink.
const RAG := Color(0.3490, 0.3882, 0.4235)
## Beast and orc eyes, dark enough never to read as XP gold.
const AMBER := Color(0.7255, 0.5412, 0.2431)
const LEATHER := Color(0.3529, 0.2353, 0.1529)
const MIST_RAG := Color(0.1686, 0.2078, 0.1961)


# --- entry points -------------------------------------------------------


## Draws the player. [param view] is one of `front`, `back`, `left`, `right`;
## [param bob] is the breathing offset in pixels.
static func draw_knight(
	p: PilotPalette, item: CanvasItem, view: String, radius: float, bob: float
) -> void:
	var r := radius * p.actor_scale
	_shadow(p, item, Vector2(0.0, r * 0.98), r * 0.92, 0.38, Vector2(r * 0.30, r * 0.34))
	match view:
		"left":
			_knight_profile(p, item, r, bob, -1.0)
		"right":
			_knight_profile(p, item, r, bob, 1.0)
		"back":
			_knight_front_or_back(p, item, r, bob, true)
		_:
			_knight_front_or_back(p, item, r, bob, false)


## Draws an enemy. [param art] is an [ActorArt] key, [param tint] the archetype
## colour from data, [param flash] the hit-flash wash (alpha zero when idle).
static func draw_creature(
	p: PilotPalette, item: CanvasItem, art: String, radius: float,
	tint: Color, flash: Color
) -> void:
	var r := radius * p.actor_scale
	match art:
		"orc":
			_orc(p, item, r, tint, flash)
		"wolf":
			_wolf(p, item, r, tint, flash)
		"boss":
			_boss(p, item, r, tint, flash)
		_:
			_skeleton(p, item, r, flash)


# --- the knight ---------------------------------------------------------


static func _knight_front_or_back(
	p: PilotPalette, item: CanvasItem, r: float, bob: float, is_back: bool
) -> void:
	var sway := bob * 1.6
	var steel := _steel(p)
	var steel_light := _steel_light(p)
	var steel_dark := _steel_dark(p)
	var leather := _leather(p)
	var leather_light := _leather_light(p)

	if is_back:
		# From behind the cloak is the whole body read: one shape, a clasp, and
		# a hem that moves with the breath.
		var cloak := PackedVector2Array([
			Vector2(-0.50 * r, -0.54 * r + bob),
			Vector2(0.50 * r, -0.54 * r + bob),
			Vector2(0.62 * r, 0.10 * r + bob),
			Vector2(0.84 * r, 0.72 * r + sway),
			Vector2(0.44 * r, 0.62 * r + sway),
			Vector2(0.22 * r, 0.90 * r + sway),
			Vector2(0.0, 0.72 * r + sway),
			Vector2(-0.22 * r, 0.90 * r + sway),
			Vector2(-0.44 * r, 0.62 * r + sway),
			Vector2(-0.84 * r, 0.72 * r + sway),
			Vector2(-0.62 * r, 0.10 * r + bob),
		])
		_shape(p, item, cloak, p.cloak, p.cloak.lightened(0.16), p.cloak.darkened(0.28))
		_hatch(p, item, cloak, 4.4)
		_cuts(p, item, cloak, 4)
		# The clasp and the fold down the spine.
		var clasp := Rect2(Vector2(-0.18 * r, -0.50 * r + bob), Vector2(0.36 * r, 0.10 * r))
		item.draw_rect(clasp, leather)
		item.draw_circle(Vector2(0.0, clasp.position.y + clasp.size.y * 0.5), 0.055 * r, steel_light)
		item.draw_line(Vector2(0.0, -0.40 * r + bob), Vector2(0.0, 0.62 * r + sway), _a(p.ink, 0.55), 1.0, true)
	else:
		# Two cloak wings behind the tabard; never wider than the shoulders at the
		# top, so the red silhouette stays the read.
		var wing_l := PackedVector2Array([
			Vector2(-0.44 * r, -0.52 * r + bob),
			Vector2(-0.28 * r, -0.50 * r + bob),
			Vector2(-0.40 * r, 0.24 * r + bob),
			Vector2(-0.74 * r, 0.84 * r + sway),
			Vector2(-0.62 * r, 0.32 * r + sway),
		])
		var wing_r := PackedVector2Array([
			Vector2(0.28 * r, -0.50 * r + bob),
			Vector2(0.44 * r, -0.52 * r + bob),
			Vector2(0.62 * r, 0.32 * r + sway),
			Vector2(0.74 * r, 0.84 * r + sway),
			Vector2(0.40 * r, 0.24 * r + bob),
		])
		for wing: PackedVector2Array in [wing_l, wing_r]:
			_shape(p, item, wing, p.cloak, p.cloak.lightened(0.16), p.cloak.darkened(0.28))
			_cuts(p, item, wing, 2)

		var torso := PackedVector2Array([
			Vector2(-0.46 * r, -0.52 * r + bob),
			Vector2(0.46 * r, -0.52 * r + bob),
			Vector2(0.42 * r, 0.18 * r + bob),
			Vector2(0.30 * r, 0.54 * r),
			Vector2(0.14 * r, 0.40 * r),
			Vector2(0.0, 0.58 * r),
			Vector2(-0.14 * r, 0.40 * r),
			Vector2(-0.30 * r, 0.54 * r),
			Vector2(-0.42 * r, 0.18 * r + bob),
		])
		_shape(p, item, torso, p.tabard, p.tabard.lightened(0.18), p.tabard.darkened(0.30))
		_hatch(p, item, torso, 4.2)
		_cuts(p, item, torso, 3)
		# The cream chevron is the player's crest; it survives at 20 px.
		var cream := p.paper if p.style != PilotPalette.STYLE_WOODCUT else p.paper
		item.draw_line(
			Vector2(-0.24 * r, -0.38 * r + bob), Vector2(0.0, -0.12 * r + bob),
			cream, 0.11 * r, true
		)
		item.draw_line(
			Vector2(0.0, -0.12 * r + bob), Vector2(0.24 * r, -0.38 * r + bob),
			cream, 0.11 * r, true
		)
		# Belt, buckle and split hem.
		var belt := Rect2(
			Vector2(-0.40 * r, 0.14 * r + bob), Vector2(0.80 * r, 0.13 * r)
		)
		item.draw_rect(belt.grow(1.0), p.ink)
		item.draw_rect(belt, leather)
		var buckle := Rect2(
			Vector2(-0.075 * r, 0.14 * r + bob), Vector2(0.15 * r, 0.13 * r)
		)
		item.draw_rect(buckle.grow(0.8), p.ink)
		item.draw_rect(buckle, steel_light)
		item.draw_rect(
			Rect2(buckle.position + Vector2(0.045 * r, 0.04 * r), Vector2(0.06 * r, 0.05 * r)),
			steel_dark
		)
		item.draw_line(
			Vector2(0.0, 0.27 * r + bob), Vector2(0.0, 0.54 * r), _a(p.ink, 0.65), 1.0, true
		)
		item.draw_circle(Vector2(-0.34 * r, 0.34 * r), 0.05 * r, steel_dark)
		item.draw_circle(Vector2(0.34 * r, 0.34 * r), 0.05 * r, steel_dark)

	# Legs and boots.
	for side: float in [-1.0, 1.0]:
		var shin := PackedVector2Array([
			Vector2(side * 0.30 * r, 0.32 * r + bob),
			Vector2(side * 0.10 * r, 0.32 * r + bob),
			Vector2(side * 0.13 * r, 0.80 * r),
			Vector2(side * 0.32 * r, 0.80 * r),
		])
		_shape(p, item, shin, steel, steel_light, steel_dark, p.outline * 0.6)
		var boot := PackedVector2Array([
			Vector2(side * 0.36 * r, 0.80 * r),
			Vector2(side * 0.09 * r, 0.80 * r),
			Vector2(side * 0.06 * r, 0.96 * r),
			Vector2(side * 0.38 * r, 0.96 * r),
		])
		_shape(p, item, boot, leather, leather_light, leather.darkened(0.3), p.outline * 0.6)
		item.draw_line(
			Vector2(side * 0.34 * r, 0.89 * r), Vector2(side * 0.12 * r, 0.89 * r),
			_a(steel_light, 0.6), 0.8, true
		)

	# Arms hang close so the WeaponView's scythe owns the space around them.
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector2(side * 0.48 * r, -0.38 * r + bob)
		var elbow := Vector2(side * 0.57 * r, -0.02 * r + bob)
		var hand := Vector2(side * 0.52 * r, 0.32 * r + bob)
		_limb(p, item, shoulder, elbow, 0.17 * r, steel_dark)
		_limb(p, item, elbow, hand, 0.15 * r, steel)
		item.draw_circle(hand, 0.105 * r, p.ink)
		item.draw_circle(hand, 0.075 * r, leather)
		# Pauldron over the top of the arm.
		var pauldron := PackedVector2Array([
			Vector2(side * 0.32 * r, -0.56 * r + bob),
			Vector2(side * 0.56 * r, -0.60 * r + bob),
			Vector2(side * 0.70 * r, -0.44 * r + bob),
			Vector2(side * 0.62 * r, -0.28 * r + bob),
			Vector2(side * 0.40 * r, -0.30 * r + bob),
		])
		_shape(p, item, pauldron, steel, steel_light, steel_dark)
		item.draw_circle(Vector2(side * 0.54 * r, -0.46 * r + bob), 0.045 * r, steel_dark)
		if p.style == PilotPalette.STYLE_WOODCUT:
			_cuts(p, item, pauldron, 2)

	# Neck and helm.
	var head_at := Vector2(0.0, -0.96 * r + bob)
	var neck := Rect2(Vector2(-0.10 * r, -0.76 * r + bob), Vector2(0.20 * r, 0.16 * r))
	item.draw_rect(neck.grow(1.0), p.ink)
	item.draw_rect(neck, leather)

	var plume := PackedVector2Array([
		head_at + Vector2(0.04 * r, -0.30 * r),
		head_at + Vector2(-0.06 * r, -0.60 * r),
		head_at + Vector2(-0.38 * r, -0.74 * r + sway * 0.35),
		head_at + Vector2(-0.54 * r, -0.48 * r + sway * 0.5),
		head_at + Vector2(-0.24 * r, -0.30 * r),
	])
	item.draw_colored_polygon(H.inflate(plume, p.outline * 0.8), p.ink)
	item.draw_colored_polygon(plume, p.tabard.darkened(0.08))
	item.draw_line(
		head_at + Vector2(-0.10 * r, -0.54 * r),
		head_at + Vector2(-0.44 * r, -0.56 * r + sway * 0.45),
		_a(p.tabard.darkened(0.35), 0.8), 1.0, true
	)

	var helm := PackedVector2Array([
		head_at + Vector2(-0.34 * r, 0.02 * r),
		head_at + Vector2(-0.30 * r, -0.20 * r),
		head_at + Vector2(-0.14 * r, -0.34 * r),
		head_at + Vector2(0.14 * r, -0.34 * r),
		head_at + Vector2(0.30 * r, -0.20 * r),
		head_at + Vector2(0.34 * r, 0.02 * r),
		head_at + Vector2(0.24 * r, 0.20 * r),
		head_at + Vector2(0.12 * r, 0.28 * r),
		head_at + Vector2(-0.12 * r, 0.28 * r),
		head_at + Vector2(-0.24 * r, 0.20 * r),
	])
	_shape(p, item, helm, steel, steel_light, steel_dark)
	_hatch(p, item, helm, 3.2)

	if is_back:
		item.draw_line(
			head_at + Vector2(0.0, -0.32 * r), head_at + Vector2(0.0, 0.26 * r),
			_a(p.ink, 0.55), 1.0, true
		)
		for side: float in [-1.0, 1.0]:
			item.draw_circle(head_at + Vector2(side * 0.20 * r, -0.12 * r), 0.035 * r, steel_dark)
	else:
		# Visor slit and the pale eyes inside it. The slit stays horizontal so
		# the face reads at 30 px even in a crowd.
		var slit := Rect2(
			head_at + Vector2(-0.26 * r, 0.02 * r), Vector2(0.52 * r, 0.09 * r)
		)
		item.draw_rect(slit, p.ink)
		var eye := p.eye_colour
		if p.style == PilotPalette.STYLE_MIST:
			eye = Color(0.9490, 0.8863, 0.7059)
		for side: float in [-1.0, 1.0]:
			var at := head_at + Vector2(side * 0.13 * r, 0.065 * r)
			if p.style == PilotPalette.STYLE_MIST:
				H.soft_blob(item, at, 0.13 * r, 0.09 * r, _a(eye, 0.22), 10)
			item.draw_circle(at, 0.032 * r, eye)
		# Nose guard and rivets.
		item.draw_line(
			head_at + Vector2(0.0, -0.31 * r), head_at + Vector2(0.0, 0.19 * r),
			steel_light, 0.07 * r, true
		)
		item.draw_circle(head_at + Vector2(-0.28 * r, -0.10 * r), 0.03 * r, steel_dark)
		item.draw_circle(head_at + Vector2(0.28 * r, -0.10 * r), 0.03 * r, steel_dark)
		if p.style == PilotPalette.STYLE_WOODCUT:
			_cuts(p, item, helm, 3)


static func _knight_profile(
	p: PilotPalette, item: CanvasItem, r: float, bob: float, facing: float
) -> void:
	var f := facing
	var sway := bob * 1.8
	var steel := _steel(p)
	var steel_light := _steel_light(p)
	var steel_dark := _steel_dark(p)
	var leather := _leather(p)
	var leather_light := _leather_light(p)

	# The cloak trails behind the facing direction, and is the far-side shape.
	var cloak := PackedVector2Array([
		Vector2(-0.24 * f * r, -0.52 * r + bob),
		Vector2(0.26 * f * r, -0.48 * r + bob),
		Vector2(0.20 * f * r, 0.26 * r + bob),
		Vector2(-0.04 * f * r, 0.52 * r),
		Vector2(-0.40 * f * r, 0.62 * r + sway),
		Vector2(-0.92 * f * r, 0.94 * r + sway),
		Vector2(-0.70 * f * r, 0.38 * r + sway),
		Vector2(-0.88 * f * r, 0.14 * r + sway),
		Vector2(-0.50 * f * r, 0.20 * r + bob),
		Vector2(-0.36 * f * r, -0.30 * r + bob),
	])
	_shape(p, item, cloak, p.cloak, p.cloak.lightened(0.16), p.cloak.darkened(0.28))
	_hatch(p, item, cloak, 4.4)
	_cuts(p, item, cloak, 4)

	# Back leg first, darker, then the forward leg.
	var back_leg := PackedVector2Array([
		Vector2(-0.16 * f * r, 0.30 * r + bob),
		Vector2(0.02 * f * r, 0.30 * r + bob),
		Vector2(-0.02 * f * r, 0.80 * r),
		Vector2(-0.20 * f * r, 0.80 * r),
	])
	_shape(p, item, back_leg, steel_dark, steel, p.ink, p.outline * 0.6)
	var back_boot := PackedVector2Array([
		Vector2(-0.20 * f * r, 0.80 * r),
		Vector2(0.00 * f * r, 0.80 * r),
		Vector2(0.10 * f * r, 0.94 * r),
		Vector2(-0.22 * f * r, 0.94 * r),
	])
	_shape(p, item, back_boot, leather.darkened(0.15), leather, p.ink, p.outline * 0.6)

	var front_leg := PackedVector2Array([
		Vector2(0.14 * f * r, 0.30 * r + bob),
		Vector2(0.30 * f * r, 0.30 * r + bob),
		Vector2(0.34 * f * r, 0.82 * r),
		Vector2(0.16 * f * r, 0.82 * r),
	])
	_shape(p, item, front_leg, steel, steel_light, steel_dark, p.outline * 0.6)
	var front_boot := PackedVector2Array([
		Vector2(0.12 * f * r, 0.82 * r),
		Vector2(0.34 * f * r, 0.82 * r),
		Vector2(0.46 * f * r, 0.96 * r),
		Vector2(0.10 * f * r, 0.96 * r),
	])
	_shape(p, item, front_boot, leather, leather_light, leather.darkened(0.3), p.outline * 0.6)

	var torso := PackedVector2Array([
		Vector2(-0.30 * f * r, -0.52 * r + bob),
		Vector2(0.36 * f * r, -0.52 * r + bob),
		Vector2(0.34 * f * r, 0.20 * r + bob),
		Vector2(0.22 * f * r, 0.54 * r),
		Vector2(0.02 * f * r, 0.40 * r),
		Vector2(-0.14 * f * r, 0.54 * r),
		Vector2(-0.30 * f * r, 0.20 * r + bob),
	])
	_shape(p, item, torso, p.tabard, p.tabard.lightened(0.18), p.tabard.darkened(0.30))
	_hatch(p, item, torso, 4.2)
	_cuts(p, item, torso, 3)
	var cream := p.paper
	item.draw_line(
		Vector2(-0.14 * f * r, -0.38 * r + bob),
		Vector2(0.18 * f * r, -0.16 * r + bob), cream, 0.10 * r, true
	)
	item.draw_line(
		Vector2(0.18 * f * r, -0.16 * r + bob),
		Vector2(0.22 * f * r, -0.36 * r + bob), cream, 0.10 * r, true
	)
	var belt := Rect2(
		Vector2(-0.28 * f * r, 0.12 * r + bob), Vector2(0.58 * f * r, 0.13 * r)
	)
	var belt_rect := Rect2(
		Vector2(minf(belt.position.x, belt.end.x), belt.position.y),
		Vector2(absf(belt.size.x), belt.size.y)
	)
	item.draw_rect(belt_rect.grow(1.0), p.ink)
	item.draw_rect(belt_rect, leather)
	var buckle := Rect2(
		Vector2(0.10 * f * r - 0.07 * r, 0.12 * r + bob), Vector2(0.14 * r, 0.13 * r)
	)
	item.draw_rect(buckle.grow(0.8), p.ink)
	item.draw_rect(buckle, steel_light)
	item.draw_circle(Vector2(-0.26 * f * r, 0.34 * r), 0.06 * r, leather)

	# One visible arm, bent, with the pauldron on top.
	var shoulder := Vector2(-0.02 * f * r, -0.40 * r + bob)
	var elbow := Vector2(0.16 * f * r, -0.04 * r + bob)
	var hand := Vector2(0.22 * f * r, 0.30 * r + bob)
	_limb(p, item, shoulder, elbow, 0.17 * r, steel_dark)
	_limb(p, item, elbow, hand, 0.15 * r, steel)
	item.draw_circle(hand, 0.105 * r, p.ink)
	item.draw_circle(hand, 0.075 * r, leather)
	var pauldron := PackedVector2Array([
		Vector2(-0.22 * f * r, -0.58 * r + bob),
		Vector2(0.10 * f * r, -0.60 * r + bob),
		Vector2(0.28 * f * r, -0.42 * r + bob),
		Vector2(0.16 * f * r, -0.26 * r + bob),
		Vector2(-0.18 * f * r, -0.30 * r + bob),
	])
	_shape(p, item, pauldron, steel, steel_light, steel_dark)

	var head_at := Vector2(0.05 * f * r, -0.94 * r + bob)
	var neck := Rect2(
		Vector2(0.0 * f * r - 0.10 * r, -0.74 * r + bob), Vector2(0.20 * r, 0.16 * r)
	)
	item.draw_rect(neck.grow(1.0), p.ink)
	item.draw_rect(neck, leather)

	var plume := PackedVector2Array([
		head_at + Vector2(-0.02 * f * r, -0.30 * r),
		head_at + Vector2(-0.14 * f * r, -0.60 * r),
		head_at + Vector2(-0.52 * f * r, -0.68 * r + sway * 0.3),
		head_at + Vector2(-0.64 * f * r, -0.42 * r + sway * 0.55),
		head_at + Vector2(-0.28 * f * r, -0.28 * r),
	])
	item.draw_colored_polygon(H.inflate(plume, p.outline * 0.8), p.ink)
	item.draw_colored_polygon(plume, p.tabard.darkened(0.08))
	item.draw_line(
		head_at + Vector2(-0.18 * f * r, -0.54 * r),
		head_at + Vector2(-0.50 * f * r, -0.52 * r + sway * 0.45),
		_a(p.tabard.darkened(0.35), 0.8), 1.0, true
	)

	var helm := PackedVector2Array([
		head_at + Vector2(-0.30 * f * r, 0.04 * r),
		head_at + Vector2(-0.26 * f * r, -0.22 * r),
		head_at + Vector2(-0.02 * f * r, -0.34 * r),
		head_at + Vector2(0.20 * f * r, -0.26 * r),
		head_at + Vector2(0.34 * f * r, -0.06 * r),
		head_at + Vector2(0.44 * f * r, 0.04 * r),
		head_at + Vector2(0.28 * f * r, 0.16 * r),
		head_at + Vector2(0.30 * f * r, 0.26 * r),
		head_at + Vector2(-0.10 * f * r, 0.30 * r),
		head_at + Vector2(-0.28 * f * r, 0.18 * r),
	])
	_shape(p, item, helm, steel, steel_light, steel_dark)
	_hatch(p, item, helm, 3.2)
	var slit := Rect2(
		head_at + Vector2(0.10 * f * r, 0.02 * r), Vector2(0.28 * f * r, 0.09 * r)
	)
	var slit_rect := Rect2(
		Vector2(minf(slit.position.x, slit.end.x), slit.position.y),
		Vector2(absf(slit.size.x), slit.size.y)
	)
	item.draw_rect(slit_rect, p.ink)
	var eye := p.eye_colour
	if p.style == PilotPalette.STYLE_MIST:
		eye = Color(0.9490, 0.8863, 0.7059)
	item.draw_circle(head_at + Vector2(0.24 * f * r, 0.065 * r), 0.032 * r, eye)
	item.draw_line(
		head_at + Vector2(0.31 * f * r, -0.30 * r),
		head_at + Vector2(0.31 * f * r, 0.19 * r), steel_light, 0.06 * r, true
	)
	item.draw_circle(head_at + Vector2(-0.20 * f * r, -0.10 * r), 0.03 * r, steel_dark)
	if p.style == PilotPalette.STYLE_WOODCUT:
		_cuts(p, item, helm, 3)


# --- skeleton -----------------------------------------------------------


static func _skeleton(
	p: PilotPalette, item: CanvasItem, r: float, flash: Color
) -> void:
	var bone := _flash(p.bone, flash, 0.55)
	var bone_dark := _flash(p.bone_dark, flash, 0.45)
	var rag := RAG
	if p.style == PilotPalette.STYLE_WOODCUT:
		rag = p.ink
	elif p.style == PilotPalette.STYLE_MIST:
		rag = MIST_RAG
	var eye := p.eye_colour
	if p.style == PilotPalette.STYLE_MIST:
		eye = Color(0.6235, 0.8784, 0.8392)

	_shadow(p, item, Vector2(0.0, r * 0.96), r * 0.82, 0.36, Vector2(r * 0.28, r * 0.36))

	# Far arm and far leg first, in the darker bone.
	_limb(p, item, Vector2(-0.28 * r, -0.34 * r), Vector2(-0.44 * r, 0.02 * r), 0.075 * r, bone_dark)
	_limb(p, item, Vector2(-0.44 * r, 0.02 * r), Vector2(-0.36 * r, 0.24 * r), 0.065 * r, bone_dark)
	_limb(p, item, Vector2(-0.16 * r, 0.30 * r), Vector2(-0.22 * r, 0.66 * r), 0.085 * r, bone_dark)
	_limb(p, item, Vector2(-0.22 * r, 0.66 * r), Vector2(-0.30 * r, 0.94 * r), 0.075 * r, bone_dark)
	_foot(p, item, Vector2(-0.30 * r, 0.94 * r), -1.0, r, bone_dark)

	# Near leg.
	_limb(p, item, Vector2(0.16 * r, 0.30 * r), Vector2(0.22 * r, 0.64 * r), 0.085 * r, bone)
	_limb(p, item, Vector2(0.22 * r, 0.64 * r), Vector2(0.28 * r, 0.94 * r), 0.075 * r, bone)
	_foot(p, item, Vector2(0.28 * r, 0.94 * r), 1.0, r, bone)

	# Pelvis and spine.
	var pelvis := PackedVector2Array([
		Vector2(-0.22 * r, 0.24 * r), Vector2(0.22 * r, 0.24 * r),
		Vector2(0.16 * r, 0.34 * r), Vector2(-0.16 * r, 0.34 * r),
	])
	_shape(p, item, pelvis, bone, bone.lightened(0.10), bone_dark, p.outline * 0.6)
	item.draw_line(Vector2(0.0, 0.26 * r), Vector2(0.0, 0.34 * r), _a(p.ink, 0.5), 0.8, true)
	for index in 3:
		var y := 0.16 * r - float(index) * 0.10 * r
		item.draw_circle(Vector2(0.0, y), 0.055 * r, p.ink)
		item.draw_circle(Vector2(0.0, y), 0.038 * r, bone_dark)

	# Ribcage: a bone oval with dark rib slots, plus a sternum.
	var cage := H.ellipse_points(Vector2(0.0, -0.10 * r), 0.27 * r, 0.24 * r, 14)
	_shape(p, item, cage, bone, bone.lightened(0.10), bone_dark, p.outline * 0.8)
	for index in 4:
		var y := -0.22 * r + float(index) * 0.075 * r
		var rib := PackedVector2Array([
			Vector2(-0.20 * r, y), Vector2(0.0, y + 0.02 * r), Vector2(0.20 * r, y),
		])
		item.draw_polyline(rib, _a(p.ink, 0.75), 1.0, true)
	item.draw_line(Vector2(0.0, -0.30 * r), Vector2(0.0, 0.04 * r), _a(p.ink, 0.55), 1.0, true)
	item.draw_circle(Vector2(0.0, -0.32 * r), 0.05 * r, bone)
	_hatch(p, item, cage, 3.0)
	_cuts(p, item, cage, 2)

	# Rag skirt over the pelvis, with a torn hem: the costume that stops the
	# skeleton reading as a bare bag of bones.
	var skirt := PackedVector2Array([
		Vector2(-0.26 * r, 0.26 * r), Vector2(0.26 * r, 0.26 * r),
		Vector2(0.30 * r, 0.54 * r), Vector2(0.14 * r, 0.46 * r),
		Vector2(0.02 * r, 0.58 * r), Vector2(-0.12 * r, 0.46 * r),
		Vector2(-0.28 * r, 0.56 * r),
	])
	_shape(p, item, skirt, rag, rag.lightened(0.12), rag.darkened(0.25), p.outline * 0.7)
	_hatch(p, item, skirt, 3.4)
	_cuts(p, item, skirt, 2)

	# Near arm and hand.
	_limb(p, item, Vector2(0.30 * r, -0.34 * r), Vector2(0.44 * r, 0.02 * r), 0.075 * r, bone)
	_limb(p, item, Vector2(0.44 * r, 0.02 * r), Vector2(0.38 * r, 0.26 * r), 0.065 * r, bone)
	item.draw_circle(Vector2(0.38 * r, 0.28 * r), 0.07 * r, p.ink)
	item.draw_circle(Vector2(0.38 * r, 0.28 * r), 0.05 * r, bone)
	for index in 3:
		var angle := -0.5 + float(index) * 0.35
		item.draw_line(
			Vector2(0.38 * r, 0.30 * r),
			Vector2(0.38 * r, 0.30 * r) + Vector2.RIGHT.rotated(angle) * 0.10 * r,
			p.ink, 0.8, true
		)
	# Rusted bracer on the near forearm.
	var bracer := Rect2(
		Vector2(0.34 * r, 0.08 * r), Vector2(0.16 * r, 0.09 * r)
	)
	item.draw_rect(bracer.grow(0.8), p.ink)
	item.draw_rect(bracer, _leather(p))
	item.draw_circle(bracer.get_center() + Vector2(0.03 * r, 0.0), 0.025 * r, _steel_light(p))

	# Cowl behind the skull.
	var cowl := PackedVector2Array([
		Vector2(-0.32 * r, -0.38 * r), Vector2(-0.36 * r, -0.72 * r),
		Vector2(-0.22 * r, -0.92 * r), Vector2(-0.06 * r, -0.86 * r),
		Vector2(0.08 * r, -0.96 * r), Vector2(0.26 * r, -0.82 * r),
		Vector2(0.34 * r, -0.42 * r), Vector2(0.18 * r, -0.50 * r),
		Vector2(0.0, -0.44 * r), Vector2(-0.18 * r, -0.52 * r),
	])
	_shape(p, item, cowl, rag, rag.lightened(0.12), rag.darkened(0.25), p.outline * 0.7)
	_hatch(p, item, cowl, 3.2)
	_cuts(p, item, cowl, 3)

	# Collar, skull and jaw.
	var collar := Rect2(
		Vector2(-0.15 * r, -0.46 * r), Vector2(0.30 * r, 0.08 * r)
	)
	item.draw_rect(collar.grow(0.8), p.ink)
	item.draw_rect(collar, _steel_dark(p))
	item.draw_circle(collar.get_center() + Vector2(0.08 * r, 0.0), 0.025 * r, _steel_light(p))

	var skull_at := Vector2(0.0, -0.66 * r)
	var cranium := H.ellipse_points(skull_at, 0.21 * r, 0.23 * r, 14)
	_shape(p, item, cranium, bone, bone.lightened(0.10), bone_dark, p.outline * 0.8)
	var jaw := PackedVector2Array([
		skull_at + Vector2(-0.15 * r, 0.14 * r),
		skull_at + Vector2(0.15 * r, 0.14 * r),
		skull_at + Vector2(0.10 * r, 0.27 * r),
		skull_at + Vector2(-0.10 * r, 0.27 * r),
	])
	_shape(p, item, jaw, bone_dark, bone, bone_dark.darkened(0.15), p.outline * 0.5)
	for side: float in [-1.0, 1.0]:
		var socket := skull_at + Vector2(side * 0.085 * r, 0.01 * r)
		item.draw_circle(socket, 0.065 * r, p.ink)
		if p.style == PilotPalette.STYLE_MIST:
			H.soft_blob(item, socket, 0.18 * r, 0.14 * r, _a(eye, 0.18), 10)
			item.draw_circle(socket, 0.030 * r, eye)
		elif p.style == PilotPalette.STYLE_WOODCUT:
			item.draw_circle(socket + Vector2(-0.02 * r, -0.02 * r), 0.020 * r, _a(p.paper, 0.65))
		else:
			item.draw_circle(socket, 0.022 * r, _a(eye, 0.55))
	var nose := PackedVector2Array([
		skull_at + Vector2(0.0, 0.08 * r), skull_at + Vector2(-0.035 * r, 0.15 * r),
		skull_at + Vector2(0.035 * r, 0.15 * r),
	])
	item.draw_colored_polygon(nose, p.ink)
	for index in 3:
		var x := -0.07 * r + float(index) * 0.07 * r
		item.draw_line(
			skull_at + Vector2(x, 0.19 * r), skull_at + Vector2(x, 0.25 * r),
			_a(p.ink, 0.75), 0.8, true
		)
	item.draw_line(
		skull_at + Vector2(-0.10 * r, -0.18 * r), skull_at + Vector2(-0.04 * r, -0.12 * r),
		_a(p.ink, 0.55), 0.8, true
	)
	item.draw_line(
		skull_at + Vector2(-0.04 * r, -0.12 * r), skull_at + Vector2(-0.09 * r, -0.06 * r),
		_a(p.ink, 0.55), 0.8, true
	)
	_hatch(p, item, cranium, 2.6)
	_cuts(p, item, cranium, 2)


static func _foot(
	p: PilotPalette, item: CanvasItem, at: Vector2, side: float, r: float, colour: Color
) -> void:
	var foot := PackedVector2Array([
		at + Vector2(-0.06 * r, 0.0), at + Vector2(0.06 * r, 0.0),
		at + Vector2((0.06 + side * 0.05) * r, 0.06 * r),
		at + Vector2((-0.06 + side * 0.05) * r, 0.06 * r),
	])
	item.draw_colored_polygon(H.inflate(foot, p.outline * 0.5), p.ink)
	item.draw_colored_polygon(foot, colour)


# --- orc ----------------------------------------------------------------


static func _orc(
	p: PilotPalette, item: CanvasItem, r: float, tint: Color, flash: Color
) -> void:
	var skin := _flash(p.body_tint(tint), flash, 0.70)
	var skin_dark := skin.darkened(0.28)
	var skin_light := skin.lightened(0.16)
	var leather := _leather(p)
	var leather_light := _leather_light(p)
	var hair := p.ink if p.style != PilotPalette.STYLE_MIST else Color(0.0431, 0.0706, 0.0627)
	var eye := AMBER

	_shadow(p, item, Vector2(0.0, r * 0.96), r * 0.92, 0.38, Vector2(r * 0.32, r * 0.36))

	# Far arm and far leg.
	_limb(p, item, Vector2(-0.55 * r, -0.36 * r), Vector2(-0.78 * r, 0.06 * r), 0.22 * r, skin_dark)
	_limb(p, item, Vector2(-0.78 * r, 0.06 * r), Vector2(-0.66 * r, 0.40 * r), 0.20 * r, skin_dark)
	item.draw_circle(Vector2(-0.66 * r, 0.42 * r), 0.16 * r, p.ink)
	item.draw_circle(Vector2(-0.66 * r, 0.42 * r), 0.13 * r, skin_dark)
	_limb(p, item, Vector2(-0.28 * r, 0.34 * r), Vector2(-0.32 * r, 0.72 * r), 0.13 * r, skin_dark)
	var far_boot := PackedVector2Array([
		Vector2(-0.48 * r, 0.72 * r), Vector2(-0.18 * r, 0.72 * r),
		Vector2(-0.14 * r, 0.94 * r), Vector2(-0.50 * r, 0.94 * r),
	])
	_shape(p, item, far_boot, leather.darkened(0.2), leather, p.ink, p.outline * 0.6)

	# Near leg and boot.
	_limb(p, item, Vector2(0.28 * r, 0.34 * r), Vector2(0.34 * r, 0.70 * r), 0.14 * r, skin)
	var boot := PackedVector2Array([
		Vector2(0.18 * r, 0.70 * r), Vector2(0.48 * r, 0.70 * r),
		Vector2(0.54 * r, 0.94 * r), Vector2(0.14 * r, 0.94 * r),
	])
	_shape(p, item, boot, leather, leather_light, leather.darkened(0.3), p.outline * 0.7)
	item.draw_line(Vector2(0.18 * r, 0.84 * r), Vector2(0.52 * r, 0.84 * r), _a(p.ink, 0.7), 1.0, true)

	# Kilt.
	var kilt := PackedVector2Array([
		Vector2(-0.44 * r, 0.22 * r), Vector2(0.44 * r, 0.22 * r),
		Vector2(0.48 * r, 0.58 * r), Vector2(0.24 * r, 0.50 * r),
		Vector2(0.06 * r, 0.64 * r), Vector2(-0.14 * r, 0.50 * r),
		Vector2(-0.34 * r, 0.62 * r), Vector2(-0.48 * r, 0.52 * r),
	])
	_shape(p, item, kilt, leather, leather_light, leather.darkened(0.32), p.outline * 0.7)
	for index in 4:
		item.draw_circle(
			Vector2(-0.28 * r + float(index) * 0.19 * r, 0.36 * r), 0.035 * r,
			_steel_light(p)
		)

	# Torso: a hunch with a broad back and a heavy belly.
	var torso := PackedVector2Array([
		Vector2(-0.56 * r, -0.42 * r), Vector2(-0.30 * r, -0.58 * r),
		Vector2(0.30 * r, -0.58 * r), Vector2(0.56 * r, -0.42 * r),
		Vector2(0.50 * r, 0.08 * r), Vector2(0.34 * r, 0.38 * r),
		Vector2(-0.34 * r, 0.38 * r), Vector2(-0.50 * r, 0.08 * r),
	])
	_shape(p, item, torso, skin, skin_light, skin_dark)
	_hatch(p, item, torso, 4.0)
	_cuts(p, item, torso, 3)
	H.soft_blob(item, Vector2(-0.10 * r, 0.06 * r), 0.34 * r, 0.24 * r, _a(skin.lightened(0.12), 0.20))

	# Harness and belt.
	var strap := PackedVector2Array([
		Vector2(-0.40 * r, -0.48 * r), Vector2(-0.26 * r, -0.52 * r),
		Vector2(0.34 * r, 0.12 * r), Vector2(0.20 * r, 0.20 * r),
	])
	_shape(p, item, strap, leather, leather_light, leather.darkened(0.3), p.outline * 0.6)
	for index in 3:
		item.draw_circle(Vector2(-0.30 * r + float(index) * 0.10 * r, -0.44 * r + float(index) * 0.14 * r), 0.03 * r, _steel_light(p))
	var belt := Rect2(Vector2(-0.48 * r, 0.10 * r), Vector2(0.96 * r, 0.12 * r))
	item.draw_rect(belt.grow(1.0), p.ink)
	item.draw_rect(belt, leather)
	item.draw_rect(Rect2(Vector2(-0.06 * r, 0.10 * r), Vector2(0.12 * r, 0.12 * r)), _steel_light(p))
	item.draw_circle(Vector2(-0.36 * r, 0.32 * r), 0.07 * r, leather)
	item.draw_circle(Vector2(-0.36 * r, 0.32 * r), 0.03 * r, _steel_dark(p))

	# Rusted pauldron on the near shoulder.
	var pauldron := PackedVector2Array([
		Vector2(0.30 * r, -0.62 * r), Vector2(0.62 * r, -0.58 * r),
		Vector2(0.76 * r, -0.38 * r), Vector2(0.60 * r, -0.22 * r),
		Vector2(0.34 * r, -0.30 * r),
	])
	_shape(p, item, pauldron, _steel_dark(p), _steel(p), p.ink, p.outline * 0.8)
	item.draw_circle(Vector2(0.58 * r, -0.46 * r), 0.045 * r, _steel_light(p))
	item.draw_circle(Vector2(0.44 * r, -0.36 * r), 0.04 * r, _steel_light(p))

	# Near arm, bracer and fist.
	_limb(p, item, Vector2(0.55 * r, -0.36 * r), Vector2(0.82 * r, 0.02 * r), 0.24 * r, skin)
	_limb(p, item, Vector2(0.82 * r, 0.02 * r), Vector2(0.68 * r, 0.38 * r), 0.21 * r, skin)
	var bracer := PackedVector2Array([
		Vector2(0.62 * r, 0.04 * r), Vector2(0.86 * r, 0.00 * r),
		Vector2(0.78 * r, 0.26 * r), Vector2(0.60 * r, 0.24 * r),
	])
	_shape(p, item, bracer, leather, leather_light, leather.darkened(0.3), p.outline * 0.7)
	for index in 2:
		item.draw_circle(Vector2(0.70 * r + float(index) * 0.09 * r, 0.10 * r), 0.03 * r, _steel_light(p))
	item.draw_circle(Vector2(0.66 * r, 0.42 * r), 0.17 * r, p.ink)
	item.draw_circle(Vector2(0.66 * r, 0.42 * r), 0.14 * r, skin)
	for index in 3:
		item.draw_line(
			Vector2(0.58 * r + float(index) * 0.07 * r, 0.44 * r),
			Vector2(0.58 * r + float(index) * 0.07 * r, 0.50 * r),
			_a(p.ink, 0.7), 0.8, true
		)

	# Head, low and forward on the hunch.
	var head_at := Vector2(0.04 * r, -0.76 * r)
	var jaw := PackedVector2Array([
		head_at + Vector2(-0.30 * r, -0.18 * r),
		head_at + Vector2(0.30 * r, -0.18 * r),
		head_at + Vector2(0.36 * r, 0.04 * r),
		head_at + Vector2(0.22 * r, 0.22 * r),
		head_at + Vector2(0.08 * r, 0.28 * r),
		head_at + Vector2(-0.08 * r, 0.28 * r),
		head_at + Vector2(-0.22 * r, 0.22 * r),
		head_at + Vector2(-0.36 * r, 0.04 * r),
	])
	_shape(p, item, jaw, skin, skin_light, skin_dark)
	_hatch(p, item, jaw, 3.0)
	# Ears.
	for side: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([
			head_at + Vector2(side * 0.32 * r, -0.08 * r),
			head_at + Vector2(side * 0.50 * r, -0.22 * r),
			head_at + Vector2(side * 0.42 * r, 0.02 * r),
		])
		item.draw_colored_polygon(H.inflate(ear, p.outline * 0.5), p.ink)
		item.draw_colored_polygon(ear, skin)
		item.draw_line(
			head_at + Vector2(side * 0.36 * r, -0.08 * r),
			head_at + Vector2(side * 0.44 * r, -0.16 * r), _a(p.ink, 0.5), 0.8, true
		)
	# Brow, eyes, nose.
	item.draw_line(
		head_at + Vector2(-0.28 * r, -0.10 * r), head_at + Vector2(0.28 * r, -0.10 * r),
		_a(p.ink, 0.8), 0.10 * r, true
	)
	for side: float in [-1.0, 1.0]:
		var at := head_at + Vector2(side * 0.15 * r, -0.02 * r)
		item.draw_circle(at, 0.045 * r, p.ink)
		if p.style == PilotPalette.STYLE_MIST:
			H.soft_blob(item, at, 0.12 * r, 0.09 * r, _a(eye, 0.16), 10)
		item.draw_circle(at, 0.022 * r, eye)
	var nose := PackedVector2Array([
		head_at + Vector2(-0.06 * r, 0.04 * r), head_at + Vector2(0.06 * r, 0.04 * r),
		head_at + Vector2(0.0, 0.12 * r),
	])
	item.draw_colored_polygon(nose, _a(p.ink, 0.65))
	# Mouth and tusks.
	item.draw_line(
		head_at + Vector2(-0.18 * r, 0.15 * r), head_at + Vector2(0.18 * r, 0.15 * r),
		p.ink, 0.05 * r, true
	)
	for side: float in [-1.0, 1.0]:
		var tusk := PackedVector2Array([
			head_at + Vector2(side * 0.18 * r, 0.16 * r),
			head_at + Vector2(side * 0.14 * r, 0.16 * r),
			head_at + Vector2(side * 0.16 * r, 0.01 * r),
		])
		item.draw_colored_polygon(H.inflate(tusk, p.outline * 0.35), p.ink)
		item.draw_colored_polygon(tusk, p.bone)
	# Topknot: a dark mass with three spikes, readable at a distance.
	var hair_mass := PackedVector2Array([
		head_at + Vector2(-0.26 * r, -0.20 * r),
		head_at + Vector2(-0.30 * r, -0.34 * r),
		head_at + Vector2(-0.08 * r, -0.28 * r),
		head_at + Vector2(0.02 * r, -0.44 * r),
		head_at + Vector2(0.14 * r, -0.30 * r),
		head_at + Vector2(0.30 * r, -0.36 * r),
		head_at + Vector2(0.26 * r, -0.18 * r),
	])
	item.draw_colored_polygon(H.inflate(hair_mass, p.outline * 0.7), p.ink)
	item.draw_colored_polygon(hair_mass, hair)
	item.draw_circle(head_at + Vector2(-0.34 * r, -0.30 * r), 0.08 * r, hair)
	# Necklace of bone beads and a tooth.
	for index in 5:
		var angle := PI * 0.15 + PI * 0.7 * float(index) / 4.0
		var at := Vector2(0.0, -0.44 * r) + Vector2(cos(angle), sin(angle)) * 0.30 * r
		item.draw_circle(at, 0.035 * r, p.ink)
		item.draw_circle(at, 0.026 * r, p.bone)
	var tooth := PackedVector2Array([
		Vector2(-0.03 * r, -0.18 * r), Vector2(0.04 * r, -0.18 * r),
		Vector2(0.005 * r, -0.08 * r),
	])
	item.draw_colored_polygon(tooth, p.bone)
	# War paint and a scar.
	item.draw_line(
		head_at + Vector2(-0.24 * r, -0.06 * r), head_at + Vector2(-0.20 * r, 0.06 * r),
		_a(p.paper, 0.75), 0.045 * r, true
	)
	item.draw_line(
		head_at + Vector2(-0.20 * r, 0.06 * r), head_at + Vector2(-0.24 * r, 0.12 * r),
		_a(p.paper, 0.75), 0.045 * r, true
	)
	item.draw_line(
		head_at + Vector2(0.18 * r, 0.04 * r), head_at + Vector2(0.26 * r, 0.10 * r),
		_a(p.danger, 0.65), 0.8, true
	)
	if p.style == PilotPalette.STYLE_WOODCUT:
		_cuts(p, item, jaw, 3)


# --- wolf ---------------------------------------------------------------


static func _wolf(
	p: PilotPalette, item: CanvasItem, r: float, tint: Color, flash: Color
) -> void:
	var fur := _flash(p.body_tint(tint), flash, 0.70)
	var fur_dark := fur.darkened(0.30)
	var fur_light := fur.lightened(0.16)
	var eye := AMBER

	_shadow(p, item, Vector2(-0.10 * r, r * 0.92), r * 1.35, 0.30, Vector2(r * 0.50, r * 0.30))

	# Tail, curled up behind.
	var tail := PackedVector2Array([
		Vector2(-0.78 * r, 0.14 * r), Vector2(-1.00 * r, 0.02 * r),
		Vector2(-1.24 * r, -0.16 * r), Vector2(-1.44 * r, -0.40 * r),
		Vector2(-1.50 * r, -0.62 * r), Vector2(-1.36 * r, -0.48 * r),
		Vector2(-1.14 * r, -0.26 * r), Vector2(-0.94 * r, -0.06 * r),
		Vector2(-0.72 * r, -0.16 * r),
	])
	_shape(p, item, tail, fur_dark, fur, fur_dark.darkened(0.15), p.outline * 0.7)
	item.draw_line(Vector2(-1.36 * r, -0.48 * r), Vector2(-1.50 * r, -0.62 * r), _a(p.ink, 0.55), 1.0, true)

	# Far legs.
	_limb(p, item, Vector2(0.26 * r, 0.22 * r), Vector2(0.18 * r, 0.86 * r), 0.075 * r, fur_dark)
	_limb(p, item, Vector2(-0.72 * r, 0.20 * r), Vector2(-0.82 * r, 0.84 * r), 0.075 * r, fur_dark)
	item.draw_circle(Vector2(0.18 * r, 0.88 * r), 0.06 * r, fur_dark)
	item.draw_circle(Vector2(-0.82 * r, 0.86 * r), 0.06 * r, fur_dark)

	# Body, shoulder hump and neck.
	var body := PackedVector2Array([
		Vector2(-0.98 * r, 0.20 * r), Vector2(-0.86 * r, -0.12 * r),
		Vector2(-0.42 * r, -0.24 * r), Vector2(0.02 * r, -0.26 * r),
		Vector2(0.30 * r, -0.44 * r), Vector2(0.58 * r, -0.34 * r),
		Vector2(0.66 * r, -0.06 * r), Vector2(0.52 * r, 0.24 * r),
		Vector2(0.20 * r, 0.30 * r), Vector2(-0.18 * r, 0.28 * r),
		Vector2(-0.62 * r, 0.32 * r), Vector2(-0.92 * r, 0.28 * r),
	])
	_shape(p, item, body, fur, fur_light, fur_dark)
	_hatch(p, item, body, 3.6)
	_cuts(p, item, body, 3)
	# Ribs and haunch.
	for index in 3:
		var y := 0.02 * r + float(index) * 0.055 * r
		item.draw_line(
			Vector2(-0.50 * r, y), Vector2(-0.08 * r, y + 0.02 * r),
			_a(p.ink, 0.30), 0.7, true
		)
	item.draw_circle(Vector2(-0.66 * r, 0.04 * r), 0.14 * r, _a(fur_light, 0.35))

	# Mane: jagged spikes along the neck and shoulders.
	var mane := PackedVector2Array([
		Vector2(0.50 * r, -0.30 * r), Vector2(0.42 * r, -0.56 * r),
		Vector2(0.30 * r, -0.40 * r), Vector2(0.20 * r, -0.60 * r),
		Vector2(0.08 * r, -0.38 * r), Vector2(-0.04 * r, -0.56 * r),
		Vector2(-0.16 * r, -0.32 * r), Vector2(-0.30 * r, -0.44 * r),
		Vector2(-0.36 * r, -0.22 * r),
	])
	item.draw_colored_polygon(H.inflate(mane, p.outline * 0.6), p.ink)
	item.draw_colored_polygon(mane, fur_dark)
	item.draw_line(Vector2(0.42 * r, -0.52 * r), Vector2(0.50 * r, -0.32 * r), _a(p.ink, 0.5), 0.8, true)

	# Near legs.
	_limb(p, item, Vector2(0.48 * r, 0.22 * r), Vector2(0.54 * r, 0.88 * r), 0.085 * r, fur)
	_limb(p, item, Vector2(-0.52 * r, 0.24 * r), Vector2(-0.56 * r, 0.90 * r), 0.090 * r, fur)
	item.draw_circle(Vector2(0.56 * r, 0.90 * r), 0.065 * r, fur_dark)
	item.draw_circle(Vector2(-0.54 * r, 0.92 * r), 0.065 * r, fur_dark)

	# Head: wedge snout, ears, jaw.
	var head_at := Vector2(0.94 * r, -0.36 * r)
	var head := PackedVector2Array([
		head_at + Vector2(-0.28 * r, -0.18 * r),
		head_at + Vector2(-0.08 * r, -0.30 * r),
		head_at + Vector2(0.16 * r, -0.20 * r),
		head_at + Vector2(0.44 * r, -0.08 * r),
		head_at + Vector2(0.56 * r, 0.02 * r),
		head_at + Vector2(0.40 * r, 0.14 * r),
		head_at + Vector2(0.12 * r, 0.16 * r),
		head_at + Vector2(-0.10 * r, 0.10 * r),
		head_at + Vector2(-0.26 * r, 0.02 * r),
	])
	_shape(p, item, head, fur, fur_light, fur_dark)
	_hatch(p, item, head, 3.0)
	# Ears.
	for index in 2:
		var ear := PackedVector2Array([
			head_at + Vector2(-0.16 * r + float(index) * 0.22 * r, -0.20 * r),
			head_at + Vector2(-0.20 * r + float(index) * 0.28 * r, -0.52 * r),
			head_at + Vector2(0.02 * r + float(index) * 0.20 * r, -0.24 * r),
		])
		item.draw_colored_polygon(H.inflate(ear, p.outline * 0.5), p.ink)
		item.draw_colored_polygon(ear, fur_dark)
		item.draw_line(
			head_at + Vector2(-0.14 * r + float(index) * 0.23 * r, -0.24 * r),
			head_at + Vector2(-0.16 * r + float(index) * 0.24 * r, -0.43 * r),
			_a(p.ink, 0.55), 0.7, true
		)
	# Eye, nose, fangs.
	var eye_at := head_at + Vector2(0.06 * r, -0.08 * r)
	item.draw_circle(eye_at, 0.055 * r, p.ink)
	if p.style == PilotPalette.STYLE_MIST:
		H.soft_blob(item, eye_at, 0.15 * r, 0.10 * r, _a(eye, 0.20), 10)
	item.draw_circle(eye_at, 0.024 * r, eye)
	item.draw_circle(head_at + Vector2(0.54 * r, 0.02 * r), 0.055 * r, p.ink)
	item.draw_line(
		head_at + Vector2(0.10 * r, 0.12 * r), head_at + Vector2(0.46 * r, 0.08 * r),
		_a(p.ink, 0.7), 0.8, true
	)
	for index in 2:
		var fang := PackedVector2Array([
			head_at + Vector2(0.28 * r + float(index) * 0.08 * r, 0.10 * r),
			head_at + Vector2(0.32 * r + float(index) * 0.08 * r, 0.10 * r),
			head_at + Vector2(0.30 * r + float(index) * 0.08 * r, 0.19 * r),
		])
		item.draw_colored_polygon(fang, p.paper if p.style == PilotPalette.STYLE_WOODCUT else p.bone)
	if p.style == PilotPalette.STYLE_WOODCUT:
		_cuts(p, item, head, 3)


# --- boss ---------------------------------------------------------------


static func _boss(
	p: PilotPalette, item: CanvasItem, r: float, tint: Color, flash: Color
) -> void:
	var robe := _flash(p.body_tint(tint), flash, 0.65)
	var robe_dark := robe.darkened(0.32)
	var robe_light := robe.lightened(0.18)
	var bone := _flash(p.bone, flash, 0.45)
	var bone_dark := _flash(p.bone_dark, flash, 0.40)
	var eye := p.danger

	_shadow(p, item, Vector2(0.10 * r, r * 1.00), r * 1.25, 0.30, Vector2(r * 0.60, r * 0.45))
	if p.style == PilotPalette.STYLE_MIST:
		H.soft_blob(item, Vector2(0.0, -0.20 * r), r * 1.40, r * 1.10, _a(p.rim_colour, 0.045), 20)

	# Far arm and hand, behind the robe.
	_limb(p, item, Vector2(-0.62 * r, -0.44 * r), Vector2(-0.90 * r, 0.08 * r), 0.11 * r, bone_dark)
	_limb(p, item, Vector2(-0.90 * r, 0.08 * r), Vector2(-0.80 * r, 0.46 * r), 0.09 * r, bone_dark)
	_claw(p, item, Vector2(-0.80 * r, 0.50 * r), -1.0, r, bone_dark)

	# Robe: a wide, torn silhouette with a split front.
	var robe_shape := PackedVector2Array([
		Vector2(-0.52 * r, -0.58 * r), Vector2(0.52 * r, -0.58 * r),
		Vector2(0.70 * r, -0.20 * r), Vector2(0.96 * r, 0.34 * r),
		Vector2(1.04 * r, 0.82 * r), Vector2(0.78 * r, 0.68 * r),
		Vector2(0.64 * r, 0.94 * r), Vector2(0.42 * r, 0.68 * r),
		Vector2(0.20 * r, 0.96 * r), Vector2(0.0, 0.72 * r),
		Vector2(-0.20 * r, 0.96 * r), Vector2(-0.42 * r, 0.68 * r),
		Vector2(-0.64 * r, 0.94 * r), Vector2(-0.78 * r, 0.68 * r),
		Vector2(-1.04 * r, 0.82 * r), Vector2(-0.96 * r, 0.34 * r),
		Vector2(-0.70 * r, -0.20 * r),
	])
	_shape(p, item, robe_shape, robe, robe_light, robe_dark)
	_hatch(p, item, robe_shape, 5.0)
	_cuts(p, item, robe_shape, 6)
	# Pale trim down the front opening and a torn inner edge.
	item.draw_line(
		Vector2(-0.24 * r, -0.48 * r), Vector2(-0.20 * r, 0.70 * r),
		_a(p.bone, 0.65), 1.2, true
	)
	item.draw_line(
		Vector2(0.24 * r, -0.48 * r), Vector2(0.20 * r, 0.70 * r),
		_a(p.bone, 0.65), 1.2, true
	)
	item.draw_line(
		Vector2(-0.20 * r, 0.30 * r), Vector2(-0.34 * r, 0.52 * r),
		_a(robe_dark, 0.7), 1.0, true
	)
	item.draw_line(
		Vector2(0.20 * r, 0.30 * r), Vector2(0.34 * r, 0.52 * r),
		_a(robe_dark, 0.7), 1.0, true
	)

	# Exposed ribcage between the robe edges.
	var cavity := H.ellipse_points(Vector2(0.0, -0.10 * r), 0.30 * r, 0.34 * r, 14)
	item.draw_colored_polygon(H.inflate(cavity, p.outline * 0.8), p.ink)
	item.draw_colored_polygon(cavity, _a(p.ink, 0.80))
	for index in 5:
		var y := -0.34 * r + float(index) * 0.085 * r
		var rib := PackedVector2Array([
			Vector2(-0.24 * r, y), Vector2(0.0, y + 0.03 * r), Vector2(0.24 * r, y),
		])
		item.draw_polyline(rib, _a(bone, 0.85), 1.4, true)
	item.draw_line(Vector2(0.0, -0.40 * r), Vector2(0.0, 0.12 * r), _a(bone, 0.75), 1.3, true)
	item.draw_colored_polygon(
		PackedVector2Array([
			Vector2(-0.10 * r, 0.16 * r), Vector2(0.10 * r, 0.16 * r),
			Vector2(0.06 * r, 0.26 * r), Vector2(-0.06 * r, 0.26 * r),
		]), _a(bone, 0.8)
	)

	# Spiked collar and pauldrons.
	var collar := PackedVector2Array([
		Vector2(-0.30 * r, -0.60 * r), Vector2(0.30 * r, -0.60 * r),
		Vector2(0.24 * r, -0.48 * r), Vector2(-0.24 * r, -0.48 * r),
	])
	_shape(p, item, collar, robe_dark, robe, p.ink, p.outline * 0.7)
	for side: float in [-1.0, 1.0]:
		var pauldron := PackedVector2Array([
			Vector2(side * 0.34 * r, -0.62 * r), Vector2(side * 0.66 * r, -0.66 * r),
			Vector2(side * 0.82 * r, -0.46 * r), Vector2(side * 0.66 * r, -0.28 * r),
			Vector2(side * 0.38 * r, -0.34 * r),
		])
		_shape(p, item, pauldron, bone, bone.lightened(0.08), bone_dark)
		for spike in 2:
			var tip := pauldron[1] + Vector2(side * (0.04 + 0.03 * float(spike)) * r, -0.20 * r)
			item.draw_line(pauldron[1], tip, p.ink, 0.06 * r, true)
			item.draw_line(pauldron[1], tip, bone, 0.035 * r, true)
		item.draw_circle(Vector2(side * 0.58 * r, -0.46 * r), 0.045 * r, bone_dark)

	# Near arm and claw.
	_limb(p, item, Vector2(0.62 * r, -0.42 * r), Vector2(0.88 * r, 0.10 * r), 0.11 * r, bone)
	_limb(p, item, Vector2(0.88 * r, 0.10 * r), Vector2(0.78 * r, 0.48 * r), 0.09 * r, bone)
	_claw(p, item, Vector2(0.78 * r, 0.52 * r), 1.0, r, bone)

	# Skull, crown, jaw.
	var head_at := Vector2(0.0, -0.90 * r)
	var skull := H.ellipse_points(head_at, 0.30 * r, 0.31 * r, 16)
	_shape(p, item, skull, bone, bone.lightened(0.10), bone_dark)
	_hatch(p, item, skull, 3.6)
	_cuts(p, item, skull, 3)
	var jaw := PackedVector2Array([
		head_at + Vector2(-0.23 * r, 0.20 * r),
		head_at + Vector2(0.23 * r, 0.20 * r),
		head_at + Vector2(0.17 * r, 0.38 * r),
		head_at + Vector2(-0.17 * r, 0.38 * r),
	])
	_shape(p, item, jaw, bone_dark, bone, bone_dark.darkened(0.20), p.outline * 0.6)
	for index in 4:
		var x := -0.12 * r + float(index) * 0.08 * r
		item.draw_line(
			head_at + Vector2(x, 0.21 * r), head_at + Vector2(x, 0.33 * r),
			_a(p.ink, 0.8), 0.9, true
		)
	item.draw_line(
		head_at + Vector2(-0.20 * r, 0.34 * r), head_at + Vector2(0.20 * r, 0.34 * r),
		p.ink, 1.2, true
	)
	# Sockets: the one place the boss's red is allowed.
	for side: float in [-1.0, 1.0]:
		var socket := head_at + Vector2(side * 0.12 * r, 0.01 * r)
		item.draw_circle(socket, 0.085 * r, p.ink)
		if p.style == PilotPalette.STYLE_MIST:
			H.soft_blob(item, socket, 0.25 * r, 0.17 * r, _a(eye, 0.22), 12)
		item.draw_circle(socket, 0.040 * r, eye)
		if p.style != PilotPalette.STYLE_MIST:
			item.draw_circle(socket + Vector2(-0.02 * r, -0.02 * r), 0.012 * r, _a(p.paper, 0.8))
	var nose := PackedVector2Array([
		head_at + Vector2(0.0, 0.10 * r), head_at + Vector2(-0.045 * r, 0.18 * r),
		head_at + Vector2(0.045 * r, 0.18 * r),
	])
	item.draw_colored_polygon(nose, p.ink)
	item.draw_line(
		head_at + Vector2(-0.14 * r, -0.22 * r), head_at + Vector2(-0.06 * r, -0.14 * r),
		_a(p.ink, 0.6), 1.0, true
	)

	var crown := PackedVector2Array([
		head_at + Vector2(-0.34 * r, -0.24 * r),
		head_at + Vector2(-0.30 * r, -0.44 * r),
		head_at + Vector2(-0.20 * r, -0.34 * r),
		head_at + Vector2(-0.12 * r, -0.54 * r),
		head_at + Vector2(0.0, -0.38 * r),
		head_at + Vector2(0.12 * r, -0.56 * r),
		head_at + Vector2(0.22 * r, -0.34 * r),
		head_at + Vector2(0.32 * r, -0.46 * r),
		head_at + Vector2(0.34 * r, -0.24 * r),
	])
	item.draw_colored_polygon(H.inflate(crown, p.outline * 0.8), p.ink)
	item.draw_colored_polygon(crown, bone)
	item.draw_line(
		head_at + Vector2(-0.30 * r, -0.25 * r), head_at + Vector2(0.30 * r, -0.25 * r),
		_a(p.ink, 0.7), 1.2, true
	)
	for index in 3:
		item.draw_circle(head_at + Vector2(-0.18 * r + float(index) * 0.18 * r, -0.30 * r), 0.022 * r, p.danger)
	_rim(p, item, crown, 1.0)
	if p.style == PilotPalette.STYLE_WOODCUT:
		_cuts(p, item, crown, 3)


static func _claw(
	p: PilotPalette, item: CanvasItem, at: Vector2, side: float, r: float, colour: Color
) -> void:
	item.draw_circle(at, 0.10 * r, p.ink)
	item.draw_circle(at, 0.075 * r, colour)
	for index in 3:
		var angle := PI * 0.5 + side * (0.35 + float(index) * 0.35)
		item.draw_line(
			at, at + Vector2.RIGHT.rotated(angle) * 0.16 * r, p.ink, 1.1, true
		)


# --- drawing primitives -------------------------------------------------


## An ink underlay, a fill, two shading bands, optional hatching and a rim.
## Woodcut replaces the bands with knife hatching, which is the whole point of
## the direction.
static func _shape(
	p: PilotPalette, item: CanvasItem, points: PackedVector2Array,
	base: Color, light: Color, shade: Color, outline: float = -1.0
) -> void:
	var ink_width := p.outline if outline < 0.0 else outline
	if ink_width > 0.0:
		item.draw_colored_polygon(H.inflate(points, ink_width * 0.75), p.ink)
	item.draw_colored_polygon(points, base)
	if p.style != PilotPalette.STYLE_WOODCUT:
		H.edge_band(item, points, shade, false, 0.58)
		H.edge_band(item, points, light, true, 0.42)
	_rim(p, item, points)


## A bone or arm segment. Round joints hide the gaps between angle changes.
static func _limb(
	p: PilotPalette, item: CanvasItem, from: Vector2, to: Vector2,
	thickness: float, colour: Color
) -> void:
	var ink_width := thickness + p.outline * (0.55 if p.style == PilotPalette.STYLE_WOODCUT else 0.9)
	item.draw_line(from, to, p.ink, ink_width, true)
	item.draw_circle(from, ink_width * 0.5, p.ink)
	item.draw_circle(to, ink_width * 0.5, p.ink)
	item.draw_line(from, to, colour, thickness, true)
	item.draw_circle(from, thickness * 0.5, colour)
	item.draw_circle(to, thickness * 0.5, colour)


static func _rim(
	p: PilotPalette, item: CanvasItem, points: PackedVector2Array, width: float = 1.0
) -> void:
	if p.style == PilotPalette.STYLE_WOODCUT:
		return
	var alpha := 0.50 if p.style == PilotPalette.STYLE_MIST else 0.26
	H.rim(item, points, _a(p.rim_colour, alpha), width)


static func _hatch(
	p: PilotPalette, item: CanvasItem, points: PackedVector2Array, spacing: float
) -> void:
	if not p.hatch or p.style == PilotPalette.STYLE_MIST:
		return
	H.hatch_polygon(item, points, spacing, PI * 0.25, p.hatch_colour, 0.7)


## Paper lines cut out of a woodcut mass. Only the woodcut uses them.
static func _cuts(
	p: PilotPalette, item: CanvasItem, points: PackedVector2Array, count: int
) -> void:
	if p.style != PilotPalette.STYLE_WOODCUT or count <= 0:
		return
	var centre := H.centroid(points)
	var radius := 0.0
	for point in points:
		radius = maxf(radius, point.distance_to(centre))
	for index in count:
		var angle := TAU * float(index) / float(count) + 0.7
		var start := centre + Vector2.RIGHT.rotated(angle) * radius * 0.20
		var stop := centre + Vector2.RIGHT.rotated(angle) * radius * 0.72
		item.draw_line(start, stop, _a(p.paper, 0.68), 0.9, true)


static func _shadow(
	p: PilotPalette, item: CanvasItem, at: Vector2, radius: float,
	squash: float, offset: Vector2
) -> void:
	match p.style:
		PilotPalette.STYLE_WOODCUT:
			var shape := H.ellipse_points(
				at + offset * 0.5, radius * 1.15, radius * squash * 1.15, 16
			)
			item.draw_colored_polygon(shape, _a(p.ink, 0.14))
			H.hatch_polygon(item, shape, 3.2, PI * 0.25, _a(p.ink, 0.28), 0.7)
		PilotPalette.STYLE_MIST:
			H.soft_blob(
				item, at + offset * 1.9, radius * 1.65, radius * squash * 1.5,
				_a(p.ink, 0.30), 20
			)
			H.soft_blob(
				item, at + offset * 0.5, radius * 0.85, radius * squash * 0.85,
				_a(p.ink, 0.32), 16
			)
		_:
			H.ground_shadow(item, at, radius, p.shadow, offset, squash)


static func _flash(colour: Color, flash: Color, strength: float) -> Color:
	if flash.a <= 0.0:
		return colour
	return colour.lerp(flash, flash.a * strength)


static func _steel(p: PilotPalette) -> Color:
	return p.paper if p.style == PilotPalette.STYLE_WOODCUT else p.steel


static func _steel_light(p: PilotPalette) -> Color:
	if p.style == PilotPalette.STYLE_WOODCUT:
		return p.paper.lightened(0.06)
	return p.steel.lightened(0.22)


static func _steel_dark(p: PilotPalette) -> Color:
	if p.style == PilotPalette.STYLE_WOODCUT:
		return p.bone_dark
	return p.steel_dark


static func _leather(p: PilotPalette) -> Color:
	if p.style == PilotPalette.STYLE_WOODCUT:
		return p.ink
	if p.style == PilotPalette.STYLE_MIST:
		return Color(0.1647, 0.1569, 0.1373)
	return LEATHER


static func _leather_light(p: PilotPalette) -> Color:
	if p.style == PilotPalette.STYLE_WOODCUT:
		return p.ink
	if p.style == PilotPalette.STYLE_MIST:
		return Color(0.2314, 0.2196, 0.1882)
	return LEATHER.lightened(0.15)


static func _a(colour: Color, opacity: float) -> Color:
	return Color(colour.r, colour.g, colour.b, opacity)
