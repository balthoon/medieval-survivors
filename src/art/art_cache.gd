## Bakes the storybook creature art into textures, one per archetype.
##
## The storybook renderer builds a creature from dozens of polygons, hatch lines
## and edge bands. A [CanvasItem] caches its draw commands, but every cached
## primitive is still submitted each frame: a wave-5 crowd plus its boss cost
## ~7,600 draw calls per frame and held the boss wave near 47 FPS with 130 ms
## spikes. Baking the same art into a texture once turns a creature into one
## textured quad — the same picture, one draw call — and the full wave holds 60.
##
## Baking needs the renderer, so it is skipped under the headless display
## server: tests and CI keep the vector fallback in [ActorArt].
class_name ArtCache extends RefCounted

## Preloaded rather than referenced by class name, so this file parses on a
## clone whose global class cache predates the visual pilot.
const VisualPilot := preload("res://src/art/visual_pilot.gd")

## Flash variants baked for every creature.
const FLASH_NONE := 0
const FLASH_HIT := 1
const FLASH_CRIT := 2
const FLASH_VARIANTS := 3

## Colour a creature flashes on a normal hit.
const HIT_FLASH := Color(1.0, 1.0, 1.0)

## Colour a creature flashes on a critical hit.
const CRIT_FLASH := Color(0.95, 0.78, 0.25)

## Alpha of the flash wash baked into the hit and crit textures. High enough to
## read at 0.08 s, low enough that the creature's silhouette survives the flash
## instead of becoming a blob.
const FLASH_ALPHA := 0.62

## Baked canvas, as a multiple of the collision radius. The widest art (the
## boss's crown) reaches 1.68 radii before the palette's actor scale, so this
## leaves a comfortable margin and no edge is ever clipped.
const EXTENT_SCALE := 2.2

## Extra transparent pixels around the art, so linear filtering never samples
## across the texture border while the waddle translates the body.
const EXTENT_MARGIN := 8.0

## Baked textures keyed by style, art, radius, tint and flash variant.
static var _textures: Dictionary = {}
## Keys currently being baked, so a second request never duplicates the work.
static var _pending: Dictionary = {}


## Draws one creature into its SubViewport. A plain callback keeps this file
## free of one class per archetype: the cache supplies the drawing call.
class Painter extends Node2D:
	## Draws the creature into this item.
	var draw_call: Callable = Callable()

	func _draw() -> void:
		if draw_call.is_valid():
			draw_call.call(self)


## The baked texture for this creature and flash state, or null while it bakes
## (and always null under the headless display server).
static func texture(art: String, radius: float, tint: Color, kind: int) -> Texture2D:
	return _textures.get(_key(art, radius, tint, kind)) as Texture2D


## Starts baking every flash variant of one creature in the background. Safe to
## call repeatedly: a cached or in-flight variant is skipped.
static func request(host: Node, art: String, radius: float, tint: Color) -> void:
	if host == null or not host.is_inside_tree():
		return
	if DisplayServer.get_name() == "headless":
		return
	for kind in FLASH_VARIANTS:
		var key := _key(art, radius, tint, kind)
		if _textures.has(key) or _pending.has(key):
			continue
		_pending[key] = true
		_bake(host, key, art, radius, tint, kind)


## Waits until every bake started so far has finished. The host leaving the tree
## ends the wait, so a tool that quits mid-bake cannot hang the call.
static func await_idle(host: Node) -> void:
	while not _pending.is_empty() and host != null and host.is_inside_tree():
		await host.get_tree().process_frame


## Renders one creature variant into an off-screen viewport and stores the
## resulting texture. Runs as a coroutine: the viewport needs one real frame.
static func _bake(
	host: Node, key: String, art: String, radius: float, tint: Color, kind: int
) -> void:
	var side := int(ceil(radius * EXTENT_SCALE * 2.0 + EXTENT_MARGIN * 2.0))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(side, side)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	var painter := Painter.new()
	painter.position = Vector2(side, side) * 0.5
	var flash := _flash_colour(kind)
	painter.draw_call = func(item: CanvasItem) -> void:
		ActorArt.draw_creature(item, art, radius, tint, flash)
	viewport.add_child(painter)
	host.add_child(viewport)

	var image: Image = null
	for _attempt in 3:
		await RenderingServer.frame_post_draw
		image = viewport.get_texture().get_image()
		if image != null and not image.is_empty():
			break

	viewport.queue_free()
	_pending.erase(key)
	if image == null or image.is_empty():
		return
	_textures[key] = ImageTexture.create_from_image(image)


## The wash colour baked into a variant. Normal is fully transparent, so the
## same code path draws the unflashed body.
static func _flash_colour(kind: int) -> Color:
	match kind:
		FLASH_HIT:
			return Color(HIT_FLASH.r, HIT_FLASH.g, HIT_FLASH.b, FLASH_ALPHA)
		FLASH_CRIT:
			return Color(CRIT_FLASH.r, CRIT_FLASH.g, CRIT_FLASH.b, FLASH_ALPHA)
		_:
			return Color(0.0, 0.0, 0.0, 0.0)


## Cache key. The visual style is part of it: switching direction must bake its
## own textures instead of reusing the storybook ones.
static func _key(art: String, radius: float, tint: Color, kind: int) -> String:
	return "%d|%s|%.2f|%s|%d" % [VisualPilot.style, art, radius, tint.to_html(), kind]
