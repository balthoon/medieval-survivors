## The ink frames behind the HUD.
##
## The display is drawn in the same hand as the world: a parchment card with a
## 2 px ink rim and a 1 px inner light line, never a flat grey rectangle. This
## node holds no state and reads nothing — every rect it paints is a constant
## here, and the bars themselves stay plain [ColorRect]s on top of it, so the HUD
## keeps working exactly as before if this node is deleted.
##
## See `design/art/art-bible.md`, HUD section.
class_name HudFrame
extends Control

## Which set of frames this instance paints.
enum Mode {
	## The three cards around the bars and the loadout, plus the boss strip.
	BARS,
	## The single card behind the level-up / boss-loot options.
	PANEL,
}

@export var mode: Mode = Mode.BARS

## Card paper. Warm and one step lighter than the page, so a frame reads as
## paper on the page rather than a hole punched in it.
const PARCHMENT := Color(0.925, 0.898, 0.827)

## The outline. Same ink as every actor in the game.
const INK := InkStyle.INK

## Inner bevel line, drawn just inside the rim.
const BEVEL := Color(1.0, 1.0, 1.0, 0.38)

## Rim weight and bevel inset, in pixels.
const RIM := 2.0
const BEVEL_INSET := 3.0

## Card around the health and experience bars.
const TOP_LEFT := Rect2(14.0, 6.0, 340.0, 54.0)
## Card around the wave number, timer and wave bar.
const TOP_RIGHT := Rect2(868.0, 6.0, 398.0, 50.0)
## Card around the weapon and equipment columns.
const BOTTOM := Rect2(14.0, 604.0, 1252.0, 108.0)
## Strip behind the boss name and health bar. Sits below the two top cards: at
## its old height it clipped the wave bar and swallowed the XP line.
const BOSS := Rect2(360.0, 70.0, 560.0, 62.0)
## Card behind the level-up and boss-loot options.
const CARD := Rect2(316.0, 172.0, 648.0, 418.0)

## x of the rule that separates the weapon column from the equipment column.
const DIVIDER_X := 620.0
## Vertical extent of that rule.
const DIVIDER_TOP := 612.0
const DIVIDER_BOTTOM := 704.0

## True while the boss strip is on screen. Set by [HUD.show_boss] and
## [HUD.hide_boss]; the card is not painted otherwise.
var boss_visible: bool = false


func _ready() -> void:
	# Decoration only: clicks must reach the buttons underneath.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if mode == Mode.PANEL:
		_card(CARD)
		return
	_card(TOP_LEFT)
	_card(TOP_RIGHT)
	_card(BOTTOM)
	if boss_visible:
		_card(BOSS)
	draw_line(
		Vector2(DIVIDER_X, DIVIDER_TOP), Vector2(DIVIDER_X, DIVIDER_BOTTOM),
		Color(INK.r, INK.g, INK.b, 0.35), 1.0, true
	)


## Paints one card: paper, ink rim, inner light line.
func _card(rect: Rect2) -> void:
	draw_rect(rect, PARCHMENT, true)
	draw_rect(rect, INK, false, RIM)
	draw_rect(rect.grow(-BEVEL_INSET), BEVEL, false, 1.0)


## Shows or hides the boss card. Called by the HUD with the boss bar itself, so
## the frame never outlives the thing it frames.
func set_boss_visible(value: bool) -> void:
	if boss_visible == value:
		return
	boss_visible = value
	queue_redraw()
