## A short-lived, visual-only copy of a dead enemy: it squashes flat and fades,
## then frees itself.
##
## Visual only by construction: it is not an [Enemy], never enters the spatial
## hash and has no hit points, so no weapon or query can ever target it.
## [EnemyManager] adds it to the same container as the enemies, so it draws above
## the arena floor at the depth the body died at.
class_name DeathFade extends Node2D

## Seconds the squash-and-fade takes before the node frees itself.
const DURATION := 0.22

## Scale of the body at the end of the fade: wider and much flatter than tall.
const END_SCALE: Vector2 = Vector2(1.35, 0.25)

## Art key copied from the dead enemy's data.
var art: String = ""
## Collision radius copied from the dead enemy, used only to size the drawing.
var radius: float = 13.0
## Body tint copied from the dead enemy's data.
var tint: Color = Color.WHITE

## Seconds elapsed since the fade started.
var _elapsed: float = 0.0


## Builds the fade from the same fields [Enemy] uses to draw. Returns it
## unattached; the caller sets its position and adds it to the enemy container.
static func create(art_key: String, body_radius: float, body_tint: Color) -> DeathFade:
	var fade := DeathFade.new()
	fade.art = art_key
	fade.radius = body_radius
	fade.tint = body_tint
	return fade


## Draws one body at full opacity. The disappearance is done through the node's
## modulate and scale, so this drawing is identical to the living creature's: the
## baked texture when one exists, the vector art otherwise.
func _draw() -> void:
	var texture := ArtCache.texture(art, radius, tint, ArtCache.FLASH_NONE)
	if texture != null:
		draw_texture(texture, -Vector2(texture.get_size()) * 0.5)
		return
	ActorArt.draw_creature(self, art, radius, tint, Color(0.0, 0.0, 0.0, 0.0))


## Squashes and fades over [constant DURATION], then frees the node.
func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	scale = Vector2.ONE.lerp(END_SCALE, progress)
	modulate.a = 1.0 - progress
	if progress >= 1.0:
		queue_free()
