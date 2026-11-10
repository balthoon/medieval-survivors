## Foreground atmosphere for the visual-direction mockups.
##
## This is drawn by [PilotOverlay] above the actors and below the HUD: vignettes,
## fog banks, the player's warm light and drifting motes. It is the layer that
## makes the three directions differ at the edges of the frame, where the current
## flat build looks most empty.
extends RefCounted

const H := preload("res://src/art/pilot_helpers.gd")

const ARENA := Rect2(40.0, 72.0, 1200.0, 536.0)


static func draw(
	palette: PilotPalette, item: CanvasItem, time: float, player_at: Vector2
) -> void:
	match palette.style:
		PilotPalette.STYLE_WOODCUT:
			_woodcut(item)
		PilotPalette.STYLE_MIST:
			_mist(item, time, player_at)
		_:
			_storybook(item, time)


## Warm, gentle, never suffocating: a light wash from the top-left, a soft
## vignette and a little pollen catching the sun.
static func _storybook(item: CanvasItem, time: float) -> void:
	H.soft_blob(
		item, Vector2(320.0, 150.0), 760.0, 390.0,
		Color(1.0, 0.90, 0.62, 0.055)
	)
	H.vignette(item, ARENA, 130.0, Color(0.16, 0.12, 0.06, 0.20))

	# Pollen: a deterministic drift, no RNG, so a capture is reproducible.
	for index in 34:
		var seed_x := fposmod(float(index) * 137.5, ARENA.size.x)
		var seed_y := fposmod(float(index) * 83.1, ARENA.size.y)
		var at := Vector2(
			ARENA.position.x + fposmod(
				seed_x + sin(time * 0.22 + float(index)) * 26.0, ARENA.size.x
			),
			ARENA.position.y + fposmod(
				seed_y - time * (3.0 + float(index % 5)), ARENA.size.y
			)
		)
		var warmth := 0.20 + 0.10 * sin(time * 0.7 + float(index))
		item.draw_circle(at, 1.4, Color(1.0, 0.92, 0.66, warmth))


## A print has no fog. Keep the atmosphere almost empty: a pair of plate-tone
## hatch bands at the frame edge, so the paper reads as inked, not digital.
static func _woodcut(item: CanvasItem) -> void:
	var tone := Color(0.09, 0.07, 0.05, 0.10)
	var top := PackedVector2Array([
		ARENA.position,
		Vector2(ARENA.end.x, ARENA.position.y),
		Vector2(ARENA.end.x, ARENA.position.y + 46.0),
		Vector2(ARENA.position.x, ARENA.position.y + 46.0),
	])
	H.hatch_polygon(item, top, 5.0, PI * 0.25, tone, 1.0)
	var bottom := PackedVector2Array([
		Vector2(ARENA.position.x, ARENA.end.y - 34.0),
		Vector2(ARENA.end.x, ARENA.end.y - 34.0),
		Vector2(ARENA.end.x, ARENA.end.y),
		Vector2(ARENA.position.x, ARENA.end.y),
	])
	H.hatch_polygon(item, bottom, 5.0, PI * 0.25, tone, 1.0)


## Cold air, a warm pocket around the player, fog crossing in front of the cast.
static func _mist(item: CanvasItem, time: float, player_at: Vector2) -> void:
	# A weak global cool grade, enough to unify the palette without turning the
	# HUD-adjacent field into soup.
	item.draw_rect(ARENA, Color(0.10, 0.16, 0.17, 0.05))
	# Moonlight falling from the top left: the cold counterpart to the lantern.
	H.soft_blob(item, Vector2(300.0, 120.0), 620.0, 330.0, Color(0.62, 0.82, 0.80, 0.06))

	# The player's lantern: three nested fades. Size is fixed so walking near an
	# edge does not make the light pop.
	H.soft_blob(item, player_at, 210.0, 156.0, Color(1.0, 0.76, 0.44, 0.085))
	H.soft_blob(item, player_at, 122.0, 92.0, Color(1.0, 0.78, 0.46, 0.115))
	H.soft_blob(item, player_at, 60.0, 46.0, Color(1.0, 0.82, 0.52, 0.150))
	# A practical core right under the knight, where a lamp would pool on grass.
	H.soft_blob(item, player_at + Vector2(0.0, 14.0), 34.0, 16.0, Color(1.0, 0.84, 0.52, 0.130))

	# Slow fog banks. They wrap rather than disappear, so the field is never
	# static and no bank pops at the frame.
	for index in 5:
		var speed := 7.0 + float(index) * 2.2
		var base_x := float(index) * 271.0 + 120.0
		var x := ARENA.position.x + fposmod(base_x + time * speed, ARENA.size.x)
		var y := ARENA.position.y + 90.0 + float(index) * 88.0
		var width := 190.0 + float(index % 3) * 70.0
		H.soft_blob(
			item, Vector2(x, y), width, 34.0 + float(index % 2) * 14.0,
			Color(0.72, 0.82, 0.79, 0.075), 20
		)

	# Two banks sit low in front of the fight, where the frame would otherwise
	# end on a hard line.
	H.soft_blob(item, Vector2(340.0, 572.0), 420.0, 64.0, Color(0.70, 0.80, 0.77, 0.10))
	H.soft_blob(item, Vector2(930.0, 566.0), 470.0, 70.0, Color(0.70, 0.80, 0.77, 0.09))

	# Motes: a few warm near the player, the rest cold in the air.
	for index in 30:
		var seed_x := fposmod(float(index) * 173.3, ARENA.size.x)
		var seed_y := fposmod(float(index) * 97.7, ARENA.size.y)
		var at := Vector2(
			ARENA.position.x + fposmod(seed_x + sin(time * 0.16 + float(index)) * 18.0, ARENA.size.x),
			ARENA.position.y + fposmod(seed_y - time * (4.0 + float(index % 4)), ARENA.size.y)
		)
		var warm := at.distance_to(player_at) < 190.0
		var colour := (
			Color(1.0, 0.82, 0.52, 0.34) if warm else Color(0.72, 0.92, 0.88, 0.22)
		)
		item.draw_circle(at, 1.25, colour)

	H.vignette(item, ARENA, 180.0, Color(0.02, 0.05, 0.05, 0.46))
