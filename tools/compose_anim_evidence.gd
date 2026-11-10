## Builds the zoomed comparison sheet from the three animation captures.
##
## The full-screen shots prove the poses exist in the shipped scene, but the
## walk bounce and the 4 px lunge are too small to read at 1×. This tool crops
## the actor area of each shot and lays the crops side by side at 3×.
##
##   godot --path . --headless --script res://tools/compose_anim_evidence.gd
extends SceneTree

const SRC_DIR := "res://production/qa/evidence/"
const OUT_PATH := SRC_DIR + "w2-anim-detail.png"

## Crop half-size, zoom factor and gap between panels.
const HALF := 90
const ZOOM := 3
const GAP := 12

## Source shot and the actor centre to crop around. The player is at (594, 380)
## after five manual walk frames; the fading enemy is at (720, 430).
const PANELS: Array[Dictionary] = [
	{"file": "w2-anim-walk.png", "centre": Vector2i(594, 380)},
	{"file": "w2-anim-lunge.png", "centre": Vector2i(594, 380)},
	{"file": "w2-anim-death.png", "centre": Vector2i(720, 430)},
]


func _initialize() -> void:
	var pieces: Array[Image] = []
	for panel in PANELS:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path(SRC_DIR + str(panel["file"]))
		)
		if image == null or image.is_empty():
			push_error("compose: could not load " + str(panel["file"]))
			quit(1)
			return
		var centre: Vector2i = panel["centre"]
		var piece := image.get_region(
			Rect2i(centre - Vector2i(HALF, HALF), Vector2i(HALF * 2, HALF * 2))
		)
		piece.resize(HALF * 2 * ZOOM, HALF * 2 * ZOOM, Image.INTERPOLATE_NEAREST)
		# blit_rect requires identical formats; the loaded PNG is not RGBA8.
		piece.convert(Image.FORMAT_RGBA8)
		pieces.append(piece)

	var panel_side := HALF * 2 * ZOOM
	var sheet := Image.create_empty(
		pieces.size() * panel_side + GAP * (pieces.size() + 1),
		panel_side + GAP * 2,
		false,
		Image.FORMAT_RGBA8
	)
	# Parchment backdrop, close to the storybook border.
	sheet.fill(Color(0.91, 0.86, 0.72))
	var x := GAP
	for piece in pieces:
		sheet.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(x, GAP))
		x += piece.get_width() + GAP

	var abs_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := sheet.save_png(abs_path)
	print("compose: save_err=%d path=%s" % [err, abs_path])
	quit(0 if err == OK else 1)
