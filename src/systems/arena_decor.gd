## Static procedural decoration for the arena: grass, tufts, flowers, trees, rocks.
##
## Everything is drawn once inside a single [method _draw]: the camera is fixed and
## the props never animate, so the renderer replays one retained command list and
## GDScript does no per-frame work. The node must stay below z 0, under the actors:
## a canopy never hides the player, an enemy, a gem or a damage number.
##
## All randomness comes from a seeded [RandomNumberGenerator] re-seeded at the top of
## [method _draw], so the arena looks the same at every launch and never consumes the
## gameplay RNG.
class_name ArenaDecor
extends Node2D

## Seed the whole layout is generated from.
const DECOR_SEED := 20261109

## Play area the decoration is laid out in. Matches the player's movement bounds.
const ARENA := Player.PLAY_RECT

## Inset kept between a grass detail and the ink frame, in pixels.
const EDGE_MARGIN := 10.0

## Radius of the ink outline around every enemy-like solid prop, in pixels.
const INK_WIDTH := 2.0

## Number of large light-and-dark grass patches.
const LIGHT_PATCHES := 14
const DARK_PATCHES := 10

## Number of small value specks that break the large patches.
const SPECK_COUNT := 190

## Number of grass tufts. Dense on the outer half, sparse inside the fight area.
const TUFT_COUNT := 160

## Number of flowers. Deliberately few and never gold: gold means XP.
const FLOWER_COUNT := 12

## Width of the deeper grass band drawn just inside the frame.
const EDGE_BAND := 11.0

## Grass base colour, applied to the opaque floor polygon under this node.
const GRASS := Color(0.765, 0.820, 0.608)
const PATCH_LIGHT := Color(0.824, 0.863, 0.682)
const PATCH_DARK := Color(0.682, 0.749, 0.525)
const TUFT_LIGHT := Color(0.576, 0.675, 0.431)
const TUFT_DARK := Color(0.478, 0.584, 0.349)
const EDGE_GRASS := Color(0.663, 0.737, 0.502)
const FLOWER := Color(0.914, 0.874, 0.753)

const INK := Color(0.16, 0.14, 0.12)
const CANOPY_DARK := Color(0.298, 0.388, 0.212)
const CANOPY_MID := Color(0.380, 0.498, 0.275)
const CANOPY_LIGHT := Color(0.463, 0.580, 0.333)
const TRUNK_CORE := Color(0.290, 0.212, 0.153)
const ROCK_BODY := Color(0.557, 0.541, 0.502)
const ROCK_LIGHT := Color(0.651, 0.635, 0.588)
const ROCK_DARK := Color(0.431, 0.416, 0.380)

## Trees in the outer crown: x, y, canopy radius. Never inside the fight plateau.
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

## Small foliage clumps: same drawing, no trunk core, smaller.
const BUSHES := [
	Vector3(430.0, 556.0, 18.0),
	Vector3(1010.0, 166.0, 20.0),
]

## Rocks: x, y, half width. Height is derived from the width.
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


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED

	_draw_edge_band(rng)
	_draw_patches(rng)
	_draw_specks(rng)
	_draw_tufts(rng)
	_draw_flowers(rng)
	_draw_rocks(rng)
	_draw_trees(rng)


## Draws the deeper grass band that sits just inside the ink frame, so the lawn
## never meets the border as a flat edge.
func _draw_edge_band(rng: RandomNumberGenerator) -> void:
	var colour := Color(EDGE_GRASS.r, EDGE_GRASS.g, EDGE_GRASS.b, 0.55)
	var origin := ARENA.position
	var size := ARENA.size
	draw_rect(Rect2(origin, Vector2(size.x, EDGE_BAND)), colour)
	draw_rect(Rect2(Vector2(origin.x, origin.y + size.y - EDGE_BAND), Vector2(size.x, EDGE_BAND)), colour)
	draw_rect(Rect2(Vector2(origin.x, origin.y + EDGE_BAND), Vector2(EDGE_BAND, size.y - EDGE_BAND * 2.0)), colour)
	draw_rect(
		Rect2(
			Vector2(origin.x + size.x - EDGE_BAND, origin.y + EDGE_BAND),
			Vector2(EDGE_BAND, size.y - EDGE_BAND * 2.0)
		),
		colour
	)

	# Three softer clumps spilling inward break the straight band.
	var spill := Color(EDGE_GRASS.r, EDGE_GRASS.g, EDGE_GRASS.b, 0.40)
	for index in 3:
		var at := _random_in_arena(rng)
		at.x = origin.x + size.x * (0.2 + 0.3 * float(index))
		at.y = origin.y + size.y - rng.randf_range(4.0, 12.0)
		draw_colored_polygon(_blob(at, Vector2(rng.randf_range(40.0, 70.0), rng.randf_range(10.0, 18.0)), 9, rng, 0.25), spill)


## Draws the large light and dark patches that break the flat floor into zones.
func _draw_patches(rng: RandomNumberGenerator) -> void:
	for _index in LIGHT_PATCHES:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(45.0, 80.0), rng.randf_range(25.0, 45.0))
		var colour := Color(PATCH_LIGHT.r, PATCH_LIGHT.g, PATCH_LIGHT.b, rng.randf_range(0.18, 0.30))
		draw_colored_polygon(_blob(at, radii, 10, rng, 0.22), colour)

	for _index in DARK_PATCHES:
		var at := _random_in_arena(rng)
		var radii := Vector2(rng.randf_range(45.0, 80.0), rng.randf_range(25.0, 45.0))
		var colour := Color(PATCH_DARK.r, PATCH_DARK.g, PATCH_DARK.b, rng.randf_range(0.15, 0.25))
		draw_colored_polygon(_blob(at, radii, 10, rng, 0.22), colour)


## Draws the 1 to 2 pixel specks that stop the large patches reading as paint.
func _draw_specks(rng: RandomNumberGenerator) -> void:
	for _index in SPECK_COUNT:
		var at := _random_in_arena(rng)
		var side := rng.randf_range(1.0, 2.0)
		var source := PATCH_LIGHT if rng.randf() < 0.5 else TUFT_DARK
		var colour := Color(source.r, source.g, source.b, rng.randf_range(0.10, 0.18))
		draw_rect(Rect2(at, Vector2(side, side)), colour)


## Draws the grass tufts: two or three thin blades from a common base. Each blade
## is a triangle, never a line — CanvasItem lines lost their antialiasing feather
## in 4.7 and come out thinner and harder than they should.
func _draw_tufts(rng: RandomNumberGenerator) -> void:
	for _index in TUFT_COUNT:
		var base := _tuft_position(rng)
		var light := rng.randf() < 0.6
		var source := TUFT_LIGHT if light else TUFT_DARK
		var colour := Color(source.r, source.g, source.b, rng.randf_range(0.50, 0.72))
		var blades := rng.randi_range(2, 3)
		for _blade in blades:
			var lean := rng.randf_range(-0.55, 0.55)
			var height := rng.randf_range(4.0, 7.0)
			var half_width := rng.randf_range(0.75, 1.0)
			var direction := Vector2(sin(lean), -cos(lean))
			var side := Vector2(-direction.y, direction.x) * half_width
			draw_colored_polygon(
				PackedVector2Array([base - side, base + side, base + direction * height]), colour
			)


## Draws the few cream flowers. Cream, never gold: gold belongs to XP gems.
func _draw_flowers(rng: RandomNumberGenerator) -> void:
	for _index in FLOWER_COUNT:
		var at := _tuft_position(rng)
		var stem := Color(TUFT_DARK.r, TUFT_DARK.g, TUFT_DARK.b, 0.6)
		draw_line(at, at + Vector2(0.0, -4.0), stem, 1.0)
		draw_circle(at + Vector2(0.0, -5.0), 1.8, Color(FLOWER.r, FLOWER.g, FLOWER.b, 0.82))


## Draws every rock: shadow, ink outline, body, top-left light facet and
## bottom-right dark facet. Flat and angular on purpose — the inverse of the
## organic tree canopy.
func _draw_rocks(rng: RandomNumberGenerator) -> void:
	for spot: Vector3 in ROCKS:
		var at := Vector2(spot.x, spot.y)
		var half_width: float = spot.z
		var half_height := half_width * 0.74
		var shadow := Color(INK.r, INK.g, INK.b, 0.12)
		var body := _rock_polygon(at, half_width, half_height, rng, 1.0)
		var outline := _rock_polygon(at + Vector2(3.0, 4.0), half_width, half_height, rng, 1.12)
		draw_colored_polygon(outline, shadow)
		draw_colored_polygon(_rock_polygon(at, half_width, half_height, rng, 1.0), shadow)

		var ink_polygon := _rock_polygon(
			at, half_width + INK_WIDTH, half_height + INK_WIDTH * 0.74, rng, 1.0
		)
		draw_colored_polygon(ink_polygon, INK)
		draw_colored_polygon(body, ROCK_BODY)

		# One flat lit facet on the upper left, one flat dark facet on the lower
		# right: three values and an ink edge are all a rock needs.
		var light_facet := PackedVector2Array([
			at + Vector2(-half_width * 0.15, -half_height * 0.15),
			at + Vector2(-half_width * 0.92, -half_height * 0.55),
			at + Vector2(-half_width * 0.35, -half_height * 0.95),
			at + Vector2(0.0, -half_height * 0.80),
		])
		draw_colored_polygon(light_facet, ROCK_LIGHT)
		var dark_facet := PackedVector2Array([
			at + Vector2(half_width * 0.15, half_height * 0.15),
			at + Vector2(half_width * 0.92, half_height * 0.55),
			at + Vector2(half_width * 0.30, half_height * 0.95),
		])
		draw_colored_polygon(dark_facet, ROCK_DARK)


## Draws every tree and bush: shadow, ink silhouette with cloud-like bumps, three
## flat greens and a suggested dark core on one tree in three.
func _draw_trees(rng: RandomNumberGenerator) -> void:
	for index in TREES.size():
		var spot: Vector3 = TREES[index]
		_draw_tree(Vector2(spot.x, spot.y), spot.z, rng, true, index % 3 == 0)
	for spot: Vector3 in BUSHES:
		_draw_tree(Vector2(spot.x, spot.y), spot.z, rng, false, false)


## Draws one tree or bush with [param radius] canopy. A bush skips the dark core.
func _draw_tree(
	at: Vector2, radius: float, rng: RandomNumberGenerator, is_tree: bool, show_core: bool
) -> void:
	var shadow := Color(INK.r, INK.g, INK.b, 0.12)
	draw_colored_polygon(_blob(at + Vector2(5.0, 7.0), Vector2(radius, radius * 0.96), 11, rng, 0.10), shadow)

	var bumps: Array[Vector2] = []
	var bump_radius := radius * 0.34
	var bump_count := rng.randi_range(3, 5)
	for _index in bump_count:
		var angle := rng.randf_range(0.0, TAU)
		bumps.append(at + Vector2.RIGHT.rotated(angle) * radius * 0.78)

	# Ink silhouette first, ink bump rings second: the green canopy drawn after
	# covers the inner half of every ring, leaving a clean outer ink edge.
	draw_colored_polygon(_blob(at, Vector2(radius + INK_WIDTH, radius + INK_WIDTH), 12, rng, 0.09), INK)
	for bump in bumps:
		draw_circle(bump, bump_radius + INK_WIDTH, INK)

	draw_colored_polygon(_blob(at, Vector2(radius, radius), 12, rng, 0.09), CANOPY_DARK)
	for bump in bumps:
		draw_circle(bump, bump_radius, CANOPY_DARK)

	draw_colored_polygon(
		_blob(at + Vector2(-3.0, -3.0), Vector2(radius - 5.0, radius - 5.0), 10, rng, 0.10), CANOPY_MID
	)

	if is_tree and show_core:
		draw_colored_polygon(
			_blob(at, Vector2(radius * 0.22, radius * 0.22), 8, rng, 0.20), TRUNK_CORE
		)

	# Light comes from the top left everywhere: three flat clumps, no gradient.
	for _index in 3:
		var offset := Vector2(rng.randf_range(-0.42, -0.10), rng.randf_range(-0.42, -0.10)) * radius
		var light_radius := Vector2(radius * rng.randf_range(0.20, 0.32), radius * rng.randf_range(0.18, 0.28))
		draw_colored_polygon(_blob(at + offset, light_radius, 8, rng, 0.18), CANOPY_LIGHT)


## Builds an irregular ellipse: [param count] points around [param center], each
## radius jittered by plus or minus [param jitter].
func _blob(
	center: Vector2,
	radii: Vector2,
	count: int,
	rng: RandomNumberGenerator,
	jitter: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var start := rng.randf_range(0.0, TAU)
	for index in count:
		var angle := start + TAU * float(index) / float(count)
		var scale := 1.0 + rng.randf_range(-jitter, jitter)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * scale)
	return points


## Angular six-sided outline for a rock, with every radius jittered. Reused for
## the shadow and the ink outline so the silhouette stays identical.
func _rock_polygon(
	center: Vector2,
	half_width: float,
	half_height: float,
	rng: RandomNumberGenerator,
	scale: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var angles := [-2.75, -2.05, -1.30, -0.45, 0.35, 1.30, 2.20]
	for angle in angles:
		var wobble := rng.randf_range(0.88, 1.08)
		points.append(
			center + Vector2(cos(angle) * half_width, sin(angle) * half_height) * wobble * scale
		)
	return points


## Returns a random point inside the play area, keeping EDGE_MARGIN from the frame.
func _random_in_arena(rng: RandomNumberGenerator) -> Vector2:
	var inner := ARENA.grow(-EDGE_MARGIN)
	return Vector2(
		rng.randf_range(inner.position.x, inner.end.x),
		rng.randf_range(inner.position.y, inner.end.y)
	)


## Picks a tuft position: full density on the outer half, about 15 percent inside
## the central fight plateau, and never within 40 px of the spawn point.
func _tuft_position(rng: RandomNumberGenerator) -> Vector2:
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
