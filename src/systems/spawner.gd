## Chooses which enemy to spawn and where it enters the arena.
##
## The spawner holds no run state: the wave number and the random source are
## supplied by the caller, so spawns stay deterministic from a seeded rng.
class_name Spawner
extends Node

## The playable rectangle, taken from Player so the spawn border and the player
## clamp can never drift apart. Spawns occur on its border, never inside.
const ARENA := Player.PLAY_RECT

## Enemy archetype display name -> first wave it may appear in.
const _UNLOCK_WAVES := {
	"squelette": 0,
	"loup maudit": 2,
	"orc": 4,
}


## Picks an enemy archetype for the wave, weighted by spawn_weight, respecting
## unlock waves: squelette from wave 0, loup maudit from wave 2, orc from wave 4.
func pick_enemy(wave_index: int, pool: Array[EnemyData], rng: RandomNumberGenerator) -> EnemyData:
	var available: Array[EnemyData] = []
	var total_weight := 0.0
	for enemy_data in pool:
		if enemy_data == null or enemy_data.is_elite:
			continue
		if wave_index < _unlock_wave_of(enemy_data):
			continue
		available.append(enemy_data)
		total_weight += maxf(enemy_data.spawn_weight, 0.0)
	if available.is_empty():
		return null
	if total_weight <= 0.0:
		# Nothing can be weight-sampled, but the archetype is unlocked.
		return available[0]
	var roll := rng.randf() * total_weight
	var running := 0.0
	for enemy_data in available:
		running += maxf(enemy_data.spawn_weight, 0.0)
		if roll <= running:
			return enemy_data
	return available[available.size() - 1]


## A point on the arena border, placed there deterministically from rng.
func spawn_position(rng: RandomNumberGenerator) -> Vector2:
	var width := ARENA.size.x
	var height := ARENA.size.y
	var distance := rng.randf() * 2.0 * (width + height)
	if distance < width:
		return Vector2(ARENA.position.x + distance, ARENA.position.y)
	distance -= width
	if distance < height:
		return Vector2(ARENA.position.x + width, ARENA.position.y + distance)
	distance -= height
	if distance < width:
		return Vector2(ARENA.position.x + width - distance, ARENA.position.y + height)
	distance -= width
	return Vector2(ARENA.position.x, ARENA.position.y + height - distance)


## Returns the first wave an enemy archetype may spawn in, defaulting to 0.
func _unlock_wave_of(enemy_data: EnemyData) -> int:
	var key := enemy_data.display_name.to_lower().strip_edges()
	return int(_UNLOCK_WAVES.get(key, 0))
