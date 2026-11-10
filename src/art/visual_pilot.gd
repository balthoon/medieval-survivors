## Runtime switch for the shipped art direction.
##
## [constant STYLE_STORYBOOK] ("Édition enluminée") is the shipped direction:
## the hooks in [ActorArt] and [ArenaDecor] route their drawing here by default.
## [constant STYLE_CURRENT] is kept only as an escape hatch and comparison mode,
## restoring the pre-pilot art exactly. The capture tool selects the woodcut and
## mist directions explicitly.
extends RefCounted

const Cast := preload("res://src/art/pilot_cast.gd")
const Arenas := preload("res://src/art/pilot_arenas.gd")
const Atmosphere := preload("res://src/art/pilot_atmosphere.gd")

const STYLE_CURRENT := 0
const STYLE_STORYBOOK := 1
const STYLE_WOODCUT := 2
const STYLE_MIST := 3

## Active direction. [constant STYLE_STORYBOOK] ships; [constant STYLE_CURRENT]
## (zero) restores the original art for comparison.
static var style: int = STYLE_STORYBOOK

static var _cached_palette: PilotPalette = null


## Switches direction. Callers are responsible for redrawing existing nodes.
static func set_style(value: int) -> void:
	style = value
	_cached_palette = null


static func is_active() -> bool:
	return style != STYLE_CURRENT


static func palette() -> PilotPalette:
	if _cached_palette == null:
		_cached_palette = PilotPalette.new(style)
	return _cached_palette


static func draw_knight(
	item: CanvasItem, view: String, radius: float, bob: float
) -> void:
	Cast.draw_knight(palette(), item, view, radius, bob)


static func draw_creature(
	item: CanvasItem, art: String, radius: float, tint: Color, flash: Color
) -> void:
	Cast.draw_creature(palette(), item, art, radius, tint, flash)


static func draw_arena(decor: CanvasItem) -> void:
	Arenas.draw(palette(), decor)


## Static prop collision derived from the same data the storybook arena draws.
static func obstacle_field() -> ObstacleField:
	return Arenas.obstacle_field()


static func draw_atmosphere(item: CanvasItem, time: float, player_at: Vector2) -> void:
	Atmosphere.draw(palette(), item, time, player_at)
