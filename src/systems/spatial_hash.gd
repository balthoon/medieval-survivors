## Uniform grid used to find nearby enemies without physics bodies.
##
## Each cell is a square of [constant CELL] pixels. An id inserted at a position
## lands in exactly one cell, and queries only visit the cells a circle can touch.
class_name SpatialHash
extends RefCounted

## Side length, in pixels, of one hash cell.
const CELL := 64.0

## cell key (Vector2i) -> Array[int] of ids stored in that cell.
var _cells: Dictionary = {}


## Removes every id from the grid.
func clear() -> void:
	_cells.clear()


## Stores id at the cell containing pos. An id may be inserted once per query pass.
func insert(id: int, pos: Vector2) -> void:
	var key := _cell_of(pos)
	var bucket: Array[int]
	if _cells.has(key):
		bucket = _cells[key]
	else:
		bucket = []
		_cells[key] = bucket
	bucket.append(id)


## Returns the ids whose cell overlaps a circle of the given radius.
## Every id appears at most once in the result.
func query_circle(center: Vector2, radius: float) -> Array[int]:
	var result: Array[int] = []
	var safe_radius := maxf(radius, 0.0)
	var min_cell := _cell_of(center - Vector2(safe_radius, safe_radius))
	var max_cell := _cell_of(center + Vector2(safe_radius, safe_radius))
	var seen: Dictionary = {}
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if not _cells.has(key):
				continue
			if not _cell_overlaps_circle(key, center, safe_radius):
				continue
			for id in _cells[key]:
				if seen.has(id):
					continue
				seen[id] = true
				result.append(id)
	return result


## Returns the cell coordinates that contain pos.
func _cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL)), int(floor(pos.y / CELL)))


## True when the square cell is within radius of center.
func _cell_overlaps_circle(cell: Vector2i, center: Vector2, radius: float) -> bool:
	var origin := Vector2(cell) * CELL
	var nearest := Vector2(
		clampf(center.x, origin.x, origin.x + CELL),
		clampf(center.y, origin.y, origin.y + CELL)
	)
	return center.distance_squared_to(nearest) <= radius * radius
