## Arena scenery for the shipped storybook direction and the two comparison
## mockups.
##
## [ArenaDecor]'s hook routes here while a pilot style is selected; storybook is
## the default. Each direction paints the whole floor, so the scene's green Floor
## polygon is covered rather than edited.
extends RefCounted

const H := preload("res://src/art/pilot_helpers.gd")

const ARENA := Rect2(40.0, 72.0, 1200.0, 536.0)
const DECOR_SEED := 20261109

const TREES := [
	Vector3(140.0, 150.0, 44.0),
	Vector3(1150.0, 150.0, 42.0),
	Vector3(108.0, 332.0, 40.0),
	Vector3(1176.0, 380.0, 38.0),
	Vector3(152.0, 544.0, 38.0),
	Vector3(1112.0, 544.0, 40.0),
	Vector3(690.0, 548.0, 34.0),
	Vector3(322.0, 214.0, 27.0),
	Vector3(980.0, 470.0, 24.0),
]
const BUSHES := [
	Vector3(430.0, 556.0, 18.0),
	Vector3(1010.0, 166.0, 20.0),
]
const ROCKS := [
	Vector3(196.0, 190.0, 26.0),
	Vector3(1060.0, 286.0, 25.0),
	Vector3(770.0, 98.0, 27.0),
	Vector3(350.0, 496.0, 24.0),
	Vector3(128.0, 444.0, 18.0),
	Vector3(1180.0, 216.0, 17.0),
	Vector3(556.0, 574.0, 16.0),
	Vector3(874.0, 128.0, 18.0),
	Vector3(250.0, 120.0, 15.0),
	Vector3(952.0, 306.0, 11.0),
	Vector3(398.0, 528.0, 11.0),
	Vector3(744.0, 104.0, 10.0),
]

# --- storybook palette --------------------------------------------------

const A_GROUND := Color(0.6314, 0.7098, 0.4235)
const A_GROUND_LIGHT := Color(0.7882, 0.8392, 0.6078)
const A_GROUND_DARK := Color(0.4784, 0.5608, 0.3294)
const A_GROUND_WARM := Color(0.8235, 0.7647, 0.5373)
const A_EDGE := Color(0.4863, 0.5647, 0.3333)
const A_TUFT_LIGHT := Color(0.4353, 0.5412, 0.2706)
const A_TUFT_DARK := Color(0.3020, 0.3961, 0.1961)
const A_FLOWER := Color(0.9529, 0.9176, 0.8235)
const A_FLOWER_COOL := Color(0.7059, 0.6510, 0.8118)
const A_MUSHROOM := Color(0.9059, 0.8235, 0.6824)
const A_MUSHROOM_SPOT := Color(0.5451, 0.4157, 0.2863)
const A_TRUNK := Color(0.4196, 0.2902, 0.1843)
const A_TRUNK_LIGHT := Color(0.5490, 0.3922, 0.2235)
const A_CANOPY_DARK := Color(0.2039, 0.2745, 0.1216)
const A_CANOPY_MID := Color(0.3059, 0.4039, 0.1765)
const A_CANOPY_LIGHT := Color(0.4275, 0.5412, 0.2392)
const A_CANOPY_RIM := Color(0.5882, 0.6667, 0.3451)
const A_ROCK := Color(0.6353, 0.6039, 0.5373)
const A_ROCK_LIGHT := Color(0.7569, 0.7176, 0.6392)
const A_ROCK_DARK := Color(0.4510, 0.4275, 0.3804)
const A_MOSS := Color(0.4353, 0.5412, 0.2706)

# --- woodcut palette ----------------------------------------------------

const B_PAPER := Color(0.9137, 0.8706, 0.7608)
const B_PAPER_SHADE := Color(0.8431, 0.7804, 0.6431)
const B_PAPER_LIGHT := Color(0.9608, 0.9294, 0.8549)
const B_INK := Color(0.0902, 0.0745, 0.0588)
const B_INK_SOFT := Color(0.2275, 0.1961, 0.1490)
const B_OXBLOOD := Color(0.5569, 0.1686, 0.1373)
const B_OCHRE := Color(0.7176, 0.5255, 0.1843)

# --- mist palette -------------------------------------------------------

const C_GROUND := Color(0.1176, 0.1608, 0.1373)
const C_GROUND_LIGHT := Color(0.1686, 0.2275, 0.1882)
const C_GROUND_DARK := Color(0.0745, 0.1098, 0.0902)
const C_GROUND_TEAL := Color(0.1294, 0.1882, 0.1804)
const C_MOSS := Color(0.2471, 0.3333, 0.2667)
const C_GRASS := Color(0.3216, 0.4196, 0.3216)
const C_GRASS_LIGHT := Color(0.4275, 0.5216, 0.4157)
const C_STONE := Color(0.2824, 0.3373, 0.3216)
const C_STONE_LIGHT := Color(0.4863, 0.5490, 0.5255)
const C_STONE_DARK := Color(0.1647, 0.2078, 0.1961)
const C_PUDDLE := Color(0.0941, 0.1569, 0.1686)
const C_PUDDLE_RIM := Color(0.4353, 0.5608, 0.5529)
const C_TREE_DARK := Color(0.0588, 0.0902, 0.0745)
const C_TREE_RIM := Color(0.3020, 0.3922, 0.3216)
const C_TRUNK := Color(0.1686, 0.1608, 0.1294)
const C_MUSHROOM := Color(0.6235, 0.8471, 0.8118)
const C_FLOWER := Color(0.6627, 0.7882, 0.7608)


static func draw(palette: PilotPalette, item: CanvasItem) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED
	match palette.style:
		PilotPalette.STYLE_WOODCUT:
			_woodcut(item, rng)
		PilotPalette.STYLE_MIST:
			_mist(item, rng)
		_:
			_storybook(item, rng)


# --- prop collision -----------------------------------------------------


## Builds the static prop collision for the arena from the same constants the
## storybook scenery is drawn with.
##
## This factory is the single source feeding both the player and every enemy:
## the run builds one [ObstacleField] here and hands the same instance to both,
## so a prop can never be drawn in one place and block in another. The original
## [ArenaDecor] props use these same spots, so the layout is identical whichever
## renderer draws it.
##
## Tree circles sit mid-trunk, under the crown: a canopy hangs overhead and must
## never block movement. Bushes stay decorative and add no collision.
static func obstacle_field() -> ObstacleField:
	var field := ObstacleField.new()
	for spot: Vector3 in TREES:
		field.add_circle(Vector2(spot.x, spot.y + spot.z * 0.88), maxf(spot.z * 0.24, 5.0))
	for spot: Vector3 in ROCKS:
		field.add_circle(Vector2(spot.x, spot.y), maxf(spot.z * 0.85, 3.0))
	# The fallen log at the bottom left, exactly the blob drawn by
	# [method _storybook_props] at (278, 574) with radii (46, 10).
	field.add_rect(Rect2(278.0 - 46.0, 574.0 - 10.0, 92.0, 20.0))
	# The broken shrine stone at the right edge, drawn at (1168, 500).
	field.add_circle(Vector2(1168.0, 500.0), 16.0)
	return field


# --- storybook ----------------------------------------------------------


static func _storybook(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	item.draw_rect(ARENA, A_GROUND)
	# The broad light: sun poured from the top left over the whole clearing.
	H.soft_blob(item, Vector2(300.0, 130.0), 700.0, 400.0, Color(1.0, 0.92, 0.66, 0.15))
	H.soft_blob(item, Vector2(1090.0, 530.0), 540.0, 320.0, Color(0.16, 0.26, 0.10, 0.10))
	# A warmer pool over the fight, so the actors stand on lit ground.
	H.soft_blob(item, Vector2(640.0, 350.0), 430.0, 230.0, Color(0.98, 0.88, 0.58, 0.10))

	for _index in 26:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(45.0, 105.0), rng.randf_range(22.0, 52.0))
		var shade := rng.randf_range(0.20, 0.34)
		var colour := _a(A_GROUND_LIGHT, shade) if rng.randf() < 0.62 else _a(A_GROUND_WARM, shade * 0.7)
		item.draw_colored_polygon(H.blob(at, radii, 11, rng, 0.26), colour)

	for _index in 16:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(48.0, 100.0), rng.randf_range(24.0, 48.0))
		var polygon := H.blob(at, radii, 11, rng, 0.26)
		item.draw_colored_polygon(polygon, _a(A_GROUND_DARK, rng.randf_range(0.15, 0.24)))
		if rng.randf() < 0.55:
			H.hatch_polygon(item, polygon, 4.2, PI * 0.25, Color(0.15, 0.20, 0.08, 0.085), 0.7)

	# Sun through leaves: a dozen soft pools of warm light across the lawn.
	for _index in 12:
		var at := _random_in_arena(rng)
		H.soft_blob(
			item, at, rng.randf_range(42.0, 92.0), rng.randf_range(20.0, 44.0),
			Color(1.0, 0.94, 0.70, rng.randf_range(0.05, 0.09)), 16
		)

	var specks: Array[Color] = [
		_a(A_GROUND_LIGHT, 0.34), _a(A_GROUND_DARK, 0.24), _a(A_GROUND_WARM, 0.28),
	]
	H.speckle(item, ARENA.grow(-8.0), rng, 420, specks, 1.0, 2.4)

	# Pebbles and clover: the small litter that stops a lawn reading as paint.
	for _index in 70:
		var at := _random_in_arena(rng)
		var side := rng.randf_range(1.2, 3.0)
		item.draw_colored_polygon(
			H.ellipse_points(at + Vector2(side * 0.35, side * 0.45), side * 1.15, side * 0.7, 7),
			_a(A_GROUND_DARK, 0.30)
		)
		item.draw_colored_polygon(
			H.ellipse_points(at, side, side * 0.6, 7), _a(A_ROCK_LIGHT, 0.55)
		)
	for _index in 60:
		var at := _tuft_position(rng)
		var ink := _a(A_TUFT_DARK, 0.45)
		for leaf in 3:
			var angle := TAU * float(leaf) / 3.0 + rng.randf_range(-0.2, 0.2)
			item.draw_circle(at + Vector2.RIGHT.rotated(angle) * 1.4, 0.9, ink)

	_storybook_tufts(item, rng)
	_storybook_flowers(item, rng)
	_storybook_mushrooms(item, rng)
	_storybook_props(item, rng)
	_storybook_rocks(item, rng)
	_storybook_trees(item, rng)

	# A darker lip just inside the ink frame, with clumps spilling inward.
	for spot: Vector3 in TREES:
		if spot.x < 220.0 or spot.x > 1040.0 or spot.y < 200.0 or spot.y > 520.0:
			continue
		H.soft_blob(
			item, Vector2(spot.x, spot.y + spot.z * 0.8),
			spot.z * 1.7, spot.z * 0.65, Color(0.12, 0.16, 0.06, 0.10)
		)
	item.draw_rect(Rect2(ARENA.position, Vector2(ARENA.size.x, 14.0)), _a(A_EDGE, 0.22))
	item.draw_rect(Rect2(ARENA.position.x, ARENA.end.y - 14.0, ARENA.size.x, 14.0), _a(A_EDGE, 0.22))
	item.draw_rect(Rect2(ARENA.position.x, ARENA.position.y + 14.0, 14.0, ARENA.size.y - 28.0), _a(A_EDGE, 0.22))
	item.draw_rect(Rect2(ARENA.end.x - 14.0, ARENA.position.y + 14.0, 14.0, ARENA.size.y - 28.0), _a(A_EDGE, 0.22))

	for _index in 22:
		var at := _edge_point(rng)
		H.grass_blade(item, at, rng.randf_range(5.0, 10.0), rng.randf_range(-0.7, 0.7), 1.3, _a(A_TUFT_DARK, 0.7))


static func _storybook_tufts(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for _index in 300:
		var base := _tuft_position(rng)
		var light := rng.randf() < 0.62
		var source := A_TUFT_LIGHT if light else A_TUFT_DARK
		var colour := _a(source, rng.randf_range(0.55, 0.82))
		var shadow := _a(A_TUFT_DARK, 0.16)
		item.draw_colored_polygon(
			PackedVector2Array([
				base + Vector2(-1.4, 1.0), base + Vector2(1.4, 1.0),
				base + Vector2(1.0, -2.0),
			]), shadow
		)
		var blades := rng.randi_range(2, 4)
		for _blade in blades:
			var lean := rng.randf_range(-0.7, 0.7)
			H.grass_blade(
				item, base, rng.randf_range(4.0, 8.5), lean,
				rng.randf_range(0.65, 1.0), colour
			)
		if rng.randf() < 0.10:
			var top := base + Vector2(sin(0.2) * 9.0, -9.0)
			item.draw_circle(top, 1.3, _a(A_GROUND_WARM, 0.8))


static func _storybook_flowers(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for index in 40:
		var at := _tuft_position(rng)
		var stem := _a(A_TUFT_DARK, 0.65)
		item.draw_line(at, at + Vector2(0.0, -5.0), stem, 1.0, true)
		var colour := A_FLOWER if index % 5 != 0 else A_FLOWER_COOL
		var head := at + Vector2(0.0, -6.0)
		for petal in 4:
			var angle := TAU * float(petal) / 4.0 + 0.4
			item.draw_circle(head + Vector2.RIGHT.rotated(angle) * 1.5, 1.45, _a(colour, 0.92))
		item.draw_circle(head, 1.0, _a(A_GROUND_WARM, 0.95))


static func _storybook_mushrooms(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2] = [
		Vector2(180.0, 230.0), Vector2(1080.0, 330.0), Vector2(300.0, 500.0),
		Vector2(980.0, 430.0), Vector2(540.0, 140.0), Vector2(720.0, 560.0),
	]
	for spot: Vector2 in spots:
		var count := rng.randi_range(2, 4)
		for index in count:
			var at := spot + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-7.0, 7.0))
			item.draw_line(at, at + Vector2(0.0, -4.0), _a(A_MUSHROOM_SPOT, 0.8), 1.2, true)
			item.draw_circle(at + Vector2(0.0, -5.0), 2.4, _a(A_MUSHROOM, 0.95))
			item.draw_circle(at + Vector2(-0.7, -5.4), 0.8, _a(A_MUSHROOM_SPOT, 0.8))


static func _storybook_props(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	# A fallen log at the bottom-left and a broken shrine stone at the right
	# edge: two anchors that make the lawn feel inhabited without entering the
	# central fight plateau.
	var log_at := Vector2(278.0, 574.0)
	H.soft_blob(item, log_at + Vector2(8.0, 5.0), 52.0, 13.0, _a(A_GROUND_DARK, 0.25))
	item.draw_colored_polygon(H.blob(log_at, Vector2(46.0, 10.0), 9, rng, 0.10), A_TRUNK)
	item.draw_colored_polygon(
		H.blob(log_at + Vector2(-3.0, -3.0), Vector2(39.0, 6.0), 9, rng, 0.10),
		_a(A_TRUNK_LIGHT, 0.8)
	)
	for index in 4:
		var at := log_at + Vector2(-26.0 + float(index) * 16.0, -4.0)
		item.draw_line(at, at + Vector2(2.0, 3.0), _a(A_TRUNK, 0.7), 1.0, true)
	for index in 3:
		var at := log_at + Vector2(-8.0 + float(index) * 12.0, -9.0)
		item.draw_circle(at, 2.2, _a(A_MUSHROOM, 0.95))

	var shrine := Vector2(1168.0, 500.0)
	H.soft_blob(item, shrine + Vector2(5.0, 6.0), 24.0, 9.0, _a(A_GROUND_DARK, 0.22))
	var stone := PackedVector2Array([
		shrine + Vector2(-14.0, 10.0), shrine + Vector2(-12.0, -16.0),
		shrine + Vector2(-3.0, -24.0), shrine + Vector2(8.0, -18.0),
		shrine + Vector2(14.0, 6.0),
	])
	item.draw_colored_polygon(H.inflate(stone, 2.0), _a(A_GROUND_DARK, 0.75))
	item.draw_colored_polygon(stone, A_ROCK)
	item.draw_colored_polygon(
		PackedVector2Array([stone[0], stone[1], stone[2], shrine + Vector2(-2.0, 6.0)]),
		A_ROCK_LIGHT
	)
	item.draw_line(shrine + Vector2(0.0, -16.0), shrine + Vector2(0.0, 4.0), _a(A_TUFT_DARK, 0.55), 1.0, true)
	item.draw_line(shrine + Vector2(-5.0, -11.0), shrine + Vector2(5.0, -11.0), _a(A_TUFT_DARK, 0.55), 1.0, true)


static func _storybook_rocks(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for spot: Vector3 in ROCKS:
		var at := Vector2(spot.x, spot.y)
		var half_width: float = spot.z
		var half_height := half_width * 0.74
		var body := _rock_polygon(at, half_width, half_height, rng)
		H.soft_blob(
			item, at + Vector2(6.0, 9.0), half_width * 1.2, half_height * 0.5,
			_a(A_GROUND_DARK, 0.24)
		)
		item.draw_colored_polygon(H.inflate(body, 2.0), _a(A_GROUND_DARK, 0.85))
		item.draw_colored_polygon(body, A_ROCK)

		var light := PackedVector2Array([
			at + Vector2(-half_width * 0.18, -half_height * 0.15),
			at + Vector2(-half_width * 0.90, -half_height * 0.54),
			at + Vector2(-half_width * 0.34, -half_height * 0.94),
			at + Vector2(0.0, -half_height * 0.78),
		])
		item.draw_colored_polygon(light, A_ROCK_LIGHT)
		var dark := PackedVector2Array([
			at + Vector2(half_width * 0.14, half_height * 0.14),
			at + Vector2(half_width * 0.90, half_height * 0.54),
			at + Vector2(half_width * 0.28, half_height * 0.94),
		])
		item.draw_colored_polygon(dark, A_ROCK_DARK)
		H.hatch_polygon(item, dark, 3.4, PI * 0.25, Color(0.15, 0.13, 0.10, 0.18), 0.7)
		if half_width > 15.0:
			H.soft_blob(
				item, at + Vector2(-half_width * 0.25, -half_height * 0.55),
				half_width * 0.45, half_height * 0.22, _a(A_MOSS, 0.38)
			)


static func _storybook_trees(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for index in TREES.size():
		var spot: Vector3 = TREES[index]
		_storybook_tree(item, Vector2(spot.x, spot.y), spot.z, rng, true, index % 3 == 0)
	for spot: Vector3 in BUSHES:
		_storybook_tree(item, Vector2(spot.x, spot.y), spot.z, rng, false, false)


static func _storybook_tree(
	item: CanvasItem, at: Vector2, radius: float, rng: RandomNumberGenerator,
	is_tree: bool, show_core: bool
) -> void:
	H.soft_blob(
		item, at + Vector2(13.0, 18.0), radius * 1.18, radius * 0.50,
		Color(0.14, 0.18, 0.06, 0.22)
	)

	if is_tree:
		var trunk := PackedVector2Array([
			at + Vector2(-radius * 0.14, radius * 0.45),
			at + Vector2(radius * 0.14, radius * 0.45),
			at + Vector2(radius * 0.20, radius * 1.30),
			at + Vector2(-radius * 0.24, radius * 1.30),
		])
		item.draw_colored_polygon(H.inflate(trunk, 2.0), A_GROUND_DARK)
		item.draw_colored_polygon(trunk, A_TRUNK)
		item.draw_line(
			at + Vector2(-radius * 0.04, radius * 0.50),
			at + Vector2(-radius * 0.06, radius * 1.04),
			_a(A_TRUNK_LIGHT, 0.75), 1.4, true
		)
		# Two forks climbing into the crown, so the canopy sits on something.
		item.draw_line(
			at + Vector2(-radius * 0.06, radius * 0.72),
			at + Vector2(-radius * 0.44, radius * 0.20), A_TRUNK, 2.6, true
		)
		item.draw_line(
			at + Vector2(radius * 0.06, radius * 0.74),
			at + Vector2(radius * 0.40, radius * 0.26), A_TRUNK, 2.4, true
		)
		item.draw_line(
			at + Vector2(-radius * 0.20, radius * 1.06),
			at + Vector2(-radius * 0.40, radius * 1.14), A_TRUNK, 2.4, true
		)
		item.draw_line(
			at + Vector2(radius * 0.18, radius * 1.04),
			at + Vector2(radius * 0.38, radius * 1.12), A_TRUNK, 2.4, true
		)

	var lobes := _canopy_lobes(at, radius, rng)

	# One dark mass first: every lobe, inflated, so the clumps fuse into a single
	# silhouette with a hand-drawn dark edge.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z + 2.0, lobe.z * 0.92 + 2.0), 9, rng, 0.15),
			A_CANOPY_DARK
		)
	# Mid tone over the same mass.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z, lobe.z * 0.92), 9, rng, 0.15),
			A_CANOPY_MID
		)
	# Sun-facing clump in every lobe: light from the top left.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y) + Vector2(-lobe.z * 0.24, -lobe.z * 0.30)
		H.soft_blob(item, centre, lobe.z * 0.64, lobe.z * 0.50, _a(A_CANOPY_LIGHT, 0.95), 10)
	# A warm rim arc on the lit edge of each lobe.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y) + Vector2(-lobe.z * 0.14, -lobe.z * 0.18)
		item.draw_arc(
			centre, lobe.z * 0.80, PI * 1.04, PI * 1.70, 9, _a(A_CANOPY_RIM, 0.55), 1.2, true
		)

	if is_tree and show_core:
		H.soft_blob(
			item, at + Vector2(radius * 0.18, radius * 0.22),
			radius * 0.34, radius * 0.28, _a(A_CANOPY_DARK, 0.55), 12
		)

	# Leaf scallops on the outer edge break the clump silhouette.
	for _index in 9:
		var angle := rng.randf_range(PI * 1.02, PI * 1.88)
		var offset := Vector2(cos(angle), sin(angle)) * radius * rng.randf_range(0.88, 1.06)
		var leaf := at + offset
		var leaf_r := rng.randf_range(3.0, 5.2)
		item.draw_circle(leaf, leaf_r, A_CANOPY_MID)
		item.draw_arc(
			leaf, leaf_r - 0.4, PI * 1.04, PI * 1.76, 8, _a(A_CANOPY_RIM, 0.65), 1.0, true
		)


# --- woodcut ------------------------------------------------------------


static func _woodcut(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	item.draw_rect(ARENA, B_PAPER)
	for _index in 6:
		var at := _random_in_arena(rng)
		H.soft_blob(
			item, at, rng.randf_range(180.0, 360.0), rng.randf_range(90.0, 180.0),
			_a(B_PAPER_SHADE, 0.16), 18
		)
	var grain: Array[Color] = [
		_a(B_PAPER_SHADE, 0.42), _a(B_PAPER_LIGHT, 0.38),
	]
	H.speckle(item, ARENA.grow(-8.0), rng, 1500, grain, 1.0, 2.0)
	for _index in 40:
		var at := _random_in_arena(rng)
		var length := rng.randf_range(8.0, 32.0)
		var angle := rng.randf_range(-0.22, 0.22)
		item.draw_line(at, at + Vector2.RIGHT.rotated(angle) * length, _a(B_PAPER_SHADE, 0.30), 0.8, true)

	# Printed ground: hatching dense at the crown, sparse in the fight plateau.
	for _index in 20:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(50.0, 110.0), rng.randf_range(22.0, 52.0))
		var polygon := H.blob(at, radii, 10, rng, 0.26)
		var distance := at.distance_to(ARENA.get_center()) / (ARENA.size.x * 0.5)
		var alpha := lerpf(0.10, 0.24, clampf(distance, 0.0, 1.0))
		H.hatch_polygon(item, polygon, rng.randf_range(4.5, 7.0), PI * 0.25, _a(B_INK, alpha), 0.7)

	for _index in 8:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(26.0, 54.0), rng.randf_range(16.0, 30.0))
		var polygon := H.blob(at, radii, 9, rng, 0.22)
		_woodcut_stipple(item, polygon, 4.0, _a(B_INK, 0.22))

	_woodcut_tufts(item, rng)
	_woodcut_rocks(item, rng)
	_woodcut_trees(item, rng)
	_woodcut_frame(item)


static func _woodcut_stipple(
	item: CanvasItem, polygon: PackedVector2Array, spacing: float, colour: Color
) -> void:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var y := bounds.position.y
	while y <= bounds.end.y:
		var x := bounds.position.x
		while x <= bounds.end.x:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				item.draw_circle(Vector2(x, y), 0.9, colour)
			x += spacing
		y += spacing


static func _woodcut_tufts(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for _index in 150:
		var base := _tuft_position(rng)
		var blades := rng.randi_range(2, 3)
		for _blade in blades:
			var lean := rng.randf_range(-0.65, 0.65)
			var height := rng.randf_range(4.0, 9.0)
			var direction := Vector2(sin(lean), -cos(lean))
			var side := Vector2(-direction.y, direction.x)
			var colour := _a(B_INK, rng.randf_range(0.55, 0.88))
			item.draw_colored_polygon(
				PackedVector2Array([
					base - side * 1.0, base + side * 1.0, base + direction * height,
				]), colour
			)
			H.cut_line(
				item, base + direction * height * 0.25 + side * 0.7,
				base + direction * height * 0.85 + side * 0.2,
				_a(B_PAPER, 0.65), 0.7
			)
		if rng.randf() < 0.18:
			item.draw_circle(base + Vector2(0.0, -7.0), 1.2, _a(B_INK, 0.75))


static func _woodcut_rocks(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for spot: Vector3 in ROCKS:
		var at := Vector2(spot.x, spot.y)
		var half_width: float = spot.z
		var half_height := half_width * 0.74
		var body := _rock_polygon(at, half_width, half_height, rng)
		H.hatch_polygon(
			item, H.ellipse_points(at + Vector2(5.0, 7.0), half_width * 1.1, half_height * 0.8, 14),
			3.6, PI * 0.25, _a(B_INK, 0.35), 0.7
		)
		item.draw_colored_polygon(H.inflate(body, 2.4), B_INK)
		item.draw_colored_polygon(body, B_PAPER)
		var dark := PackedVector2Array([
			at + Vector2(half_width * 0.10, half_height * 0.10),
			at + Vector2(half_width * 0.88, half_height * 0.52),
			at + Vector2(half_width * 0.26, half_height * 0.90),
		])
		H.hatch_polygon(item, dark, 2.8, PI * 0.25, _a(B_INK, 0.55), 0.8)
		H.cut_line(
			item, at + Vector2(-half_width * 0.80, -half_height * 0.45),
			at + Vector2(-half_width * 0.24, -half_height * 0.84), _a(B_PAPER_LIGHT, 0.9), 1.2
		)


static func _woodcut_trees(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for index in TREES.size():
		var spot: Vector3 = TREES[index]
		_woodcut_tree(item, Vector2(spot.x, spot.y), spot.z, rng, true, index % 3 == 0)
	for spot: Vector3 in BUSHES:
		_woodcut_tree(item, Vector2(spot.x, spot.y), spot.z, rng, false, false)


static func _woodcut_tree(
	item: CanvasItem, at: Vector2, radius: float, rng: RandomNumberGenerator,
	is_tree: bool, show_core: bool
) -> void:
	H.hatch_polygon(
		item, H.ellipse_points(at + Vector2(14.0, 20.0), radius * 1.15, radius * 0.45, 16),
		4.0, PI * 0.25, _a(B_INK, 0.30), 0.7
	)

	if is_tree:
		var trunk := PackedVector2Array([
			at + Vector2(-radius * 0.15, radius * 0.40),
			at + Vector2(radius * 0.15, radius * 0.40),
			at + Vector2(radius * 0.22, radius * 1.32),
			at + Vector2(-radius * 0.26, radius * 1.32),
		])
		item.draw_colored_polygon(H.inflate(trunk, 2.4), B_INK)
		item.draw_colored_polygon(trunk, B_INK)
		for index in 3:
			var x := -radius * 0.08 + float(index) * radius * 0.07
			H.cut_line(
				item, at + Vector2(x, radius * 0.52), at + Vector2(x - 1.5, radius * 1.04),
				_a(B_PAPER, 0.55), 0.8
			)
		item.draw_line(
			at + Vector2(-radius * 0.20, radius * 1.04),
			at + Vector2(-radius * 0.42, radius * 1.14), B_INK, 2.6, true
		)
		item.draw_line(
			at + Vector2(radius * 0.18, radius * 1.02),
			at + Vector2(radius * 0.40, radius * 1.12), B_INK, 2.6, true
		)

	var lobes := _canopy_lobes(at, radius, rng)

	# One solid ink block: inflated lobes fuse, true-size lobes fill.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z + 2.2, lobe.z * 0.92 + 2.2), 9, rng, 0.15), B_INK
		)
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z, lobe.z * 0.92), 9, rng, 0.15), B_INK
		)

	# Knife cuts: paper arcs tracing each clump, the signature woodcut gesture.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_arc(
			centre + Vector2(-lobe.z * 0.10, -lobe.z * 0.12), lobe.z * 0.68,
			PI * 1.08, PI * 1.72, 9, _a(B_PAPER, 0.72), 0.9, true
		)
		item.draw_arc(
			centre, lobe.z * 0.40, PI * 1.24, PI * 1.60, 7, _a(B_PAPER, 0.55), 0.8, true
		)
	# A few chisel strokes between the clumps so the crown is not one flat plate.
	for _index in 6:
		var angle := rng.randf_range(0.0, TAU)
		var offset := Vector2.RIGHT.rotated(angle) * radius * rng.randf_range(0.15, 0.78)
		var length := rng.randf_range(5.0, 13.0)
		var direction := Vector2.RIGHT.rotated(angle + rng.randf_range(-0.6, 0.6))
		H.cut_line(
			item, at + offset, at + offset + direction * length,
			_a(B_PAPER, rng.randf_range(0.55, 0.85)), 1.0
		)
	if show_core:
		item.draw_circle(at + Vector2(radius * 0.08, radius * 0.08), radius * 0.18, _a(B_PAPER, 0.30))


static func _woodcut_frame(item: CanvasItem) -> void:
	var rule := ARENA.grow(-9.0)
	var ink := _a(B_INK, 0.75)
	item.draw_rect(rule, ink, false, 1.0)
	for index in 24:
		var x := rule.position.x + float(index) * rule.size.x / 23.0
		item.draw_line(Vector2(x, rule.position.y), Vector2(x, rule.position.y + 4.0), ink, 1.0, true)
		item.draw_line(Vector2(x, rule.end.y), Vector2(x, rule.end.y - 4.0), ink, 1.0, true)
	for index in 10:
		var y := rule.position.y + float(index) * rule.size.y / 9.0
		item.draw_line(Vector2(rule.position.x, y), Vector2(rule.position.x + 4.0, y), ink, 1.0, true)
		item.draw_line(Vector2(rule.end.x, y), Vector2(rule.end.x - 4.0, y), ink, 1.0, true)
	for corner: Vector2 in [rule.position, Vector2(rule.end.x, rule.position.y), rule.end, Vector2(rule.position.x, rule.end.y)]:
		var diamond := PackedVector2Array([
			corner + Vector2(0.0, -5.0), corner + Vector2(5.0, 0.0),
			corner + Vector2(0.0, 5.0), corner + Vector2(-5.0, 0.0),
		])
		item.draw_colored_polygon(diamond, B_INK)


# --- mist ---------------------------------------------------------------


static func _mist(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	item.draw_rect(ARENA, C_GROUND)
	H.soft_blob(item, Vector2(300.0, 140.0), 720.0, 400.0, Color(0.42, 0.58, 0.56, 0.07))
	H.soft_blob(item, Vector2(1000.0, 500.0), 560.0, 320.0, Color(0.02, 0.04, 0.04, 0.20))

	for _index in 16:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(55.0, 115.0), rng.randf_range(26.0, 55.0))
		H.soft_blob(
			item, at, radii.x, radii.y,
			_a(C_GROUND_LIGHT, rng.randf_range(0.12, 0.22)), 20
		)
	for _index in 13:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(60.0, 120.0), rng.randf_range(28.0, 58.0))
		H.soft_blob(
			item, at, radii.x, radii.y,
			_a(C_GROUND_DARK, rng.randf_range(0.14, 0.24)), 20
		)
	for _index in 4:
		var at := _random_in_arena(rng)
		H.soft_blob(
			item, at, rng.randf_range(70.0, 140.0), rng.randf_range(40.0, 70.0),
			_a(C_GROUND_TEAL, 0.12), 18
		)

	# Moonlit clumps and a few static ground-mist streaks so the floor has
	# readable structure under the moving fog.
	for _index in 10:
		var at := _random_in_arena(rng)
		H.soft_blob(
			item, at, rng.randf_range(50.0, 110.0), rng.randf_range(14.0, 30.0),
			_a(C_GRASS_LIGHT, 0.08), 16
		)
	for _index in 6:
		var at := _random_in_arena(rng)
		H.soft_blob(
			item, at + Vector2(0.0, 26.0), rng.randf_range(120.0, 220.0),
			rng.randf_range(16.0, 28.0), Color(0.62, 0.74, 0.72, 0.055), 18
		)

	_mist_grass(item, rng)
	_mist_puddles(item, rng)
	_mist_flowers(item, rng)
	_mist_rocks(item, rng)
	_mist_trees(item, rng)
	_mist_ruin(item, rng)


static func _mist_grass(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for _index in 300:
		var base := _tuft_position(rng)
		var light := rng.randf() < 0.55
		var source := C_GRASS_LIGHT if light else C_GRASS
		var colour := _a(source, rng.randf_range(0.38, 0.72))
		for _blade in rng.randi_range(2, 4):
			H.grass_blade(
				item, base, rng.randf_range(4.0, 10.0),
				rng.randf_range(-0.7, 0.7), rng.randf_range(1.0, 1.6), colour
			)
	# Moss mounds: soft dark cushions with a hint of pale light on top.
	for _index in 18:
		var at := _random_in_arena(rng)
		var radius := rng.randf_range(14.0, 34.0)
		H.soft_blob(item, at, radius * 1.35, radius * 0.55, _a(C_MOSS, 0.24))
		H.soft_blob(item, at + Vector2(-2.0, -3.0), radius * 0.75, radius * 0.28, _a(C_GRASS_LIGHT, 0.15))


static func _mist_puddles(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	var spots := [
		Vector3(490.0, 210.0, 34.0), Vector3(910.0, 390.0, 42.0),
		Vector3(240.0, 420.0, 26.0), Vector3(760.0, 530.0, 30.0),
		Vector3(1080.0, 150.0, 22.0),
	]
	for spot: Vector3 in spots:
		var at := Vector2(spot.x, spot.y)
		var radius: float = spot.z
		var shape := H.blob(at, Vector2(radius, radius * 0.42), 12, rng, 0.16)
		item.draw_colored_polygon(shape, _a(C_PUDDLE, 0.85))
		item.draw_polyline(shape, _a(C_PUDDLE_RIM, 0.45), 1.0, true)
		item.draw_line(
			at + Vector2(-radius * 0.55, -radius * 0.06),
			at + Vector2(radius * 0.35, -radius * 0.06),
			_a(C_PUDDLE_RIM, 0.28), 0.8, true
		)
		item.draw_line(
			at + Vector2(-radius * 0.20, radius * 0.10),
			at + Vector2(radius * 0.20, radius * 0.10),
			_a(C_PUDDLE_RIM, 0.18), 0.7, true
		)


static func _mist_flowers(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2] = [
		Vector2(180.0, 250.0), Vector2(1080.0, 330.0), Vector2(300.0, 500.0),
		Vector2(980.0, 430.0), Vector2(540.0, 140.0), Vector2(720.0, 560.0),
	]
	for spot: Vector2 in spots:
		for _index in rng.randi_range(2, 5):
			var at := spot + Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-9.0, 9.0))
			H.soft_blob(item, at, 5.0, 3.4, _a(C_MUSHROOM, 0.10), 10)
			item.draw_line(at, at + Vector2(0.0, -4.0), _a(C_MOSS, 0.8), 1.0, true)
			item.draw_circle(at + Vector2(0.0, -5.0), 1.6, _a(C_MUSHROOM, 0.85))
	for index in 18:
		var at := _tuft_position(rng)
		item.draw_line(at, at + Vector2(0.0, -5.0), _a(C_GRASS, 0.7), 0.9, true)
		item.draw_circle(at + Vector2(0.0, -6.0), 1.1, _a(C_FLOWER, 0.55 + 0.05 * float(index % 4)))


static func _mist_rocks(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for spot: Vector3 in ROCKS:
		var at := Vector2(spot.x, spot.y)
		var half_width: float = spot.z
		var half_height := half_width * 0.74
		var body := _rock_polygon(at, half_width, half_height, rng)
		H.soft_blob(
			item, at + Vector2(8.0, 11.0), half_width * 1.3, half_height * 0.55,
			_a(C_GROUND_DARK, 0.30)
		)
		item.draw_colored_polygon(H.inflate(body, 2.0), C_STONE_DARK)
		item.draw_colored_polygon(body, C_STONE)
		var light := PackedVector2Array([
			at + Vector2(-half_width * 0.18, -half_height * 0.15),
			at + Vector2(-half_width * 0.90, -half_height * 0.54),
			at + Vector2(-half_width * 0.34, -half_height * 0.94),
			at + Vector2(0.0, -half_height * 0.78),
		])
		item.draw_colored_polygon(light, _a(C_STONE_LIGHT, 0.55))
		H.rim(item, body, _a(C_STONE_LIGHT, 0.45), 1.0)
		if half_width > 14.0:
			H.soft_blob(
				item, at + Vector2(-half_width * 0.22, -half_height * 0.52),
				half_width * 0.48, half_height * 0.20, _a(C_MOSS, 0.45)
			)


static func _mist_trees(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	for index in TREES.size():
		var spot: Vector3 = TREES[index]
		_mist_tree(item, Vector2(spot.x, spot.y), spot.z, rng, true, index % 3 == 0)
	for spot: Vector3 in BUSHES:
		_mist_tree(item, Vector2(spot.x, spot.y), spot.z, rng, false, false)


static func _mist_tree(
	item: CanvasItem, at: Vector2, radius: float, rng: RandomNumberGenerator,
	is_tree: bool, show_core: bool
) -> void:
	H.soft_blob(
		item, at + Vector2(20.0, 26.0), radius * 1.35, radius * 0.50,
		Color(0.01, 0.03, 0.02, 0.34), 20
	)
	if is_tree:
		var trunk := PackedVector2Array([
			at + Vector2(-radius * 0.16, radius * 0.38),
			at + Vector2(radius * 0.16, radius * 0.38),
			at + Vector2(radius * 0.22, radius * 1.32),
			at + Vector2(-radius * 0.28, radius * 1.32),
		])
		item.draw_colored_polygon(H.inflate(trunk, 2.0), Color(0.02, 0.03, 0.02, 0.95))
		item.draw_colored_polygon(trunk, C_TRUNK)
		H.rim(item, trunk, _a(C_TREE_RIM, 0.35), 0.9)
		item.draw_line(
			at + Vector2(-radius * 0.18, radius * 1.02),
			at + Vector2(-radius * 0.44, radius * 1.16), Color(0.02, 0.03, 0.02), 3.0, true
		)
		item.draw_line(
			at + Vector2(radius * 0.18, radius * 1.02),
			at + Vector2(radius * 0.42, radius * 1.14), Color(0.02, 0.03, 0.02), 3.0, true
		)

	var lobes := _canopy_lobes(at, radius, rng)

	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z + 1.8, lobe.z * 0.92 + 1.8), 9, rng, 0.15),
			Color(0.01, 0.02, 0.02, 0.96)
		)
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_colored_polygon(
			H.blob(centre, Vector2(lobe.z, lobe.z * 0.92), 9, rng, 0.15), C_TREE_DARK
		)

	# Cold moon on the upper-left of every clump: the single cue that turns a
	# black mass back into foliage.
	for lobe: Vector3 in lobes:
		var centre := Vector2(lobe.x, lobe.y)
		item.draw_arc(
			centre + Vector2(-lobe.z * 0.12, -lobe.z * 0.16), lobe.z * 0.76,
			PI * 1.06, PI * 1.70, 9, _a(C_TREE_RIM, 0.50), 1.1, true
		)
		H.soft_blob(
			item, centre + Vector2(-lobe.z * 0.22, -lobe.z * 0.26),
			lobe.z * 0.34, lobe.z * 0.24, _a(C_MOSS, 0.14), 8
		)

	# Sky holes where the crown thins against the moon.
	for _index in 3:
		var angle := rng.randf_range(PI * 1.02, PI * 1.62)
		var offset := Vector2(cos(angle), sin(angle)) * radius * rng.randf_range(0.30, 0.72)
		item.draw_circle(at + offset, rng.randf_range(1.8, 3.6), _a(C_GROUND_LIGHT, 0.45))
	if show_core:
		item.draw_circle(at + Vector2(radius * 0.10, radius * 0.10), radius * 0.16, _a(C_GROUND_DARK, 0.75))

	# Fireflies: a few cold pinpricks around the canopy edge.
	for _index in 3:
		var angle := rng.randf_range(0.0, TAU)
		var firefly := at + Vector2(cos(angle), sin(angle) * 0.55) * radius * rng.randf_range(0.9, 1.25)
		H.soft_blob(item, firefly, 9.0, 7.0, _a(C_MUSHROOM, 0.10), 10)
		item.draw_circle(firefly, 1.1, _a(C_MUSHROOM, 0.55))


static func _mist_ruin(item: CanvasItem, rng: RandomNumberGenerator) -> void:
	# Three broken standing stones at the right edge, lit on the upper-left.
	for index in 3:
		var at := Vector2(1150.0 + float(index) * 13.0, 470.0 - float(index) * 9.0)
		var height := 22.0 + float(index) * 5.0
		var stone := PackedVector2Array([
			at + Vector2(-6.0, 6.0), at + Vector2(-5.0, -height),
			at + Vector2(2.0, -height - 4.0), at + Vector2(7.0, 3.0),
		])
		H.soft_blob(item, at + Vector2(7.0, 8.0), 15.0, 6.0, _a(C_GROUND_DARK, 0.30))
		item.draw_colored_polygon(H.inflate(stone, 2.0), C_STONE_DARK)
		item.draw_colored_polygon(stone, C_STONE)
		H.rim(item, stone, _a(C_STONE_LIGHT, 0.55), 1.0)
		item.draw_line(
			at + Vector2(-4.0, -height * 0.5), at + Vector2(2.0, -height * 0.4),
			_a(C_MOSS, 0.55), 1.2, true
		)


# --- shared layout helpers ----------------------------------------------


## Builds a crown as overlapping clumps: a heavy central mass ringed by six or
## seven smaller lobes. One blob reads as a cabbage; overlapping irregular lobes
## read as foliage. Returns (x, y, radius) per clump, in world coordinates.
static func _canopy_lobes(
	at: Vector2, radius: float, rng: RandomNumberGenerator
) -> Array[Vector3]:
	# The crown rides above the base point, so the trunk stays visible below it.
	var crown := at + Vector2(0.0, -radius * 0.30)
	var lobes: Array[Vector3] = []
	lobes.append(Vector3(crown.x - radius * 0.10, crown.y - radius * 0.12, radius * 0.72))
	var count := 7
	for index in count:
		var angle := TAU * float(index) / float(count) + rng.randf_range(-0.24, 0.24)
		var distance := radius * rng.randf_range(0.50, 0.76)
		lobes.append(
			Vector3(
				crown.x + cos(angle) * distance,
				crown.y + sin(angle) * distance * 0.90,
				radius * rng.randf_range(0.36, 0.52)
			)
		)
	return lobes


static func _random_in_arena(rng: RandomNumberGenerator) -> Vector2:
	var inner := ARENA.grow(-10.0)
	return Vector2(
		rng.randf_range(inner.position.x, inner.end.x),
		rng.randf_range(inner.position.y, inner.end.y)
	)


static func _tuft_position(rng: RandomNumberGenerator) -> Vector2:
	var center := ARENA.get_center()
	var best := _random_in_arena(rng)
	for _attempt in 10:
		var candidate := _random_in_arena(rng)
		best = candidate
		if candidate.distance_to(center) < 40.0:
			continue
		var t := clampf(candidate.distance_to(center) / (ARENA.size.x * 0.5), 0.0, 1.0)
		if rng.randf() < lerpf(0.15, 1.0, t):
			return candidate
	return best


static func _edge_point(rng: RandomNumberGenerator) -> Vector2:
	var side := rng.randi_range(0, 3)
	match side:
		0:
			return Vector2(rng.randf_range(ARENA.position.x + 8.0, ARENA.end.x - 8.0), ARENA.position.y + rng.randf_range(5.0, 18.0))
		1:
			return Vector2(rng.randf_range(ARENA.position.x + 8.0, ARENA.end.x - 8.0), ARENA.end.y - rng.randf_range(5.0, 18.0))
		2:
			return Vector2(ARENA.position.x + rng.randf_range(5.0, 18.0), rng.randf_range(ARENA.position.y + 8.0, ARENA.end.y - 8.0))
		_:
			return Vector2(ARENA.end.x - rng.randf_range(5.0, 18.0), rng.randf_range(ARENA.position.y + 8.0, ARENA.end.y - 8.0))
	return ARENA.get_center()


static func _rock_polygon(
	centre: Vector2, half_width: float, half_height: float, rng: RandomNumberGenerator
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var angles: Array[float] = [-2.75, -2.05, -1.30, -0.45, 0.35, 1.30, 2.20]
	for angle: float in angles:
		var wobble := rng.randf_range(0.88, 1.08)
		points.append(
			centre + Vector2(cos(angle) * half_width, sin(angle) * half_height) * wobble
		)
	return points


static func _a(colour: Color, opacity: float) -> Color:
	return Color(colour.r, colour.g, colour.b, opacity)
