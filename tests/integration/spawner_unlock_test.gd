## Integration check for W0-E3 story 3: enemy unlocks key on the stable
## [member EnemyData.id], never on the UI-facing [member EnemyData.display_name].
##
## Every test loads the catalogue itself, and any resource whose field it changes
## is duplicated first, so the suite is order-independent and never mutates the
## shared data/*.tres resources.
extends GdUnitTestSuite

const CATALOGUE_PATH := "res://data/catalogue.tres"

## Shipped unlock pacing, by stable id: squelette from wave 0, loup maudit from
## wave 2, orc from wave 4.
const EXPECTED_UNLOCK_WAVES := {
	"squelette": 0,
	"loup_maudit": 2,
	"orc": 4,
}

const DRAW_COUNT := 200
const SEED := 20261109


func _load_catalogue() -> Catalogue:
	return load(CATALOGUE_PATH) as Catalogue


## Draws [param count] picks at [param wave_index] and returns the set of
## archetype ids returned, keyed by id.
func _draw_ids(
	spawner: Spawner,
	wave_index: int,
	pool: Array[EnemyData],
	rng: RandomNumberGenerator,
	count: int
) -> Dictionary:
	var seen := {}
	for _roll in count:
		var picked := spawner.pick_enemy(wave_index, pool, rng)
		assert_object(picked).override_failure_message(
			"wave %d must always have an unlocked archetype to pick" % wave_index
		).is_not_null()
		if picked != null:
			seen[picked.id] = true
	return seen


func test_enemy_ids_are_non_empty_and_unique() -> void:
	# Arrange — every normal archetype plus the boss.
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var all_enemies: Array[EnemyData] = []
	all_enemies.append_array(catalogue.enemies)
	if catalogue.boss != null:
		all_enemies.append(catalogue.boss)

	# Act / Assert — a blank or repeated id cannot identify a saved archetype.
	var seen := {}
	for enemy in all_enemies:
		assert_object(enemy).override_failure_message("every enemy slot is assigned").is_not_null()
		if enemy == null:
			continue
		assert_str(enemy.id).override_failure_message(
			"%s has a non-empty stable id" % enemy.display_name
		).is_not_empty()
		assert_bool(seen.has(enemy.id)).override_failure_message(
			"id '%s' is unique" % enemy.id
		).is_false()
		seen[enemy.id] = true


func test_enemy_lookup_finds_the_stable_id() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var found := catalogue.enemy_by_id("loup_maudit")
	var missing := catalogue.enemy_by_id("ennemi_inconnu")

	# Assert
	assert_object(found).override_failure_message(
		"loup_maudit resolves by id"
	).is_not_null()
	if found != null:
		assert_str(found.id).override_failure_message(
			"lookup returns the loup maudit"
		).is_equal("loup_maudit")
	assert_object(missing).override_failure_message("unknown id returns null").is_null()


func test_unlock_waves_match_the_shipped_pacing() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var actual := {}
	for enemy in catalogue.enemies:
		if enemy != null:
			actual[enemy.id] = enemy.unlock_wave

	# Assert — exactly one archetype per unlock wave: 0, 2 and 4.
	assert_int(actual.size()).override_failure_message(
		"three normal archetypes carry an unlock wave"
	).is_equal(EXPECTED_UNLOCK_WAVES.size())
	for id in EXPECTED_UNLOCK_WAVES:
		assert_bool(actual.has(id)).override_failure_message(
			"'%s' is in the spawn pool" % id
		).is_true()
		if actual.has(id):
			assert_int(actual[id]).override_failure_message(
				"'%s' unlocks on wave %d" % [id, EXPECTED_UNLOCK_WAVES[id]]
			).is_equal(EXPECTED_UNLOCK_WAVES[id])


func test_wave_zero_never_picks_locked_archetypes() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var spawner := Spawner.new()
	auto_free(spawner)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Act
	var seen := _draw_ids(spawner, 0, catalogue.enemies, rng, DRAW_COUNT)

	# Assert — loup maudit (wave 2) and orc (wave 4) are locked out of wave 0.
	assert_bool(seen.has("loup_maudit")).override_failure_message(
		"wave 0 never spawns the loup maudit"
	).is_false()
	assert_bool(seen.has("orc")).override_failure_message(
		"wave 0 never spawns the orc"
	).is_false()
	assert_bool(seen.has("squelette")).override_failure_message(
		"wave 0 spawns the squelette"
	).is_true()


func test_wave_four_reaches_every_archetype() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var spawner := Spawner.new()
	auto_free(spawner)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Act
	var seen := _draw_ids(spawner, 4, catalogue.enemies, rng, DRAW_COUNT)

	# Assert — by wave 4 every archetype is unlocked and reachable.
	for id in EXPECTED_UNLOCK_WAVES:
		assert_bool(seen.has(id)).override_failure_message(
			"wave 4 can spawn '%s'" % id
		).is_true()


func test_renamed_squelette_is_still_unlocked_at_wave_zero() -> void:
	# Arrange — duplicate before renaming: the catalogue's resource is shared.
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var original := catalogue.enemy_by_id("squelette")
	assert_object(original).override_failure_message(
		"squelette is in the catalogue"
	).is_not_null()
	if original == null:
		return
	var renamed := original.duplicate() as EnemyData
	renamed.display_name = "Renommé"
	var pool: Array[EnemyData] = [renamed]
	var spawner := Spawner.new()
	auto_free(spawner)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Act
	var picked := spawner.pick_enemy(0, pool, rng)

	# Assert — the unlock is keyed on id, so UI text cannot lock a wave-0
	# archetype out.
	assert_object(picked).override_failure_message(
		"a renamed squelette still spawns on wave 0"
	).is_not_null()
	if picked != null:
		assert_str(picked.id).override_failure_message(
			"the pick is still the squelette"
		).is_equal("squelette")


## The regression proof: the old display_name-keyed lookup defaulted any unknown
## name to unlock wave 0, so renaming the loup maudit unlocked it a wave early.
func test_renaming_display_name_does_not_unlock_a_later_archetype() -> void:
	# Arrange — the loup maudit unlocks on wave 2 by id; duplicate first so the
	# shared catalogue resource stays untouched.
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var original := catalogue.enemy_by_id("loup_maudit")
	assert_object(original).override_failure_message(
		"loup_maudit is in the catalogue"
	).is_not_null()
	if original == null:
		return
	var renamed := original.duplicate() as EnemyData
	renamed.display_name = "Renommé"
	var pool: Array[EnemyData] = [renamed]
	var spawner := Spawner.new()
	auto_free(spawner)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Act
	var picked := spawner.pick_enemy(0, pool, rng)

	# Assert — display_name is UI text; only the id decides the unlock wave.
	assert_object(picked).override_failure_message(
		"a renamed loup maudit stays locked until wave 2"
	).is_null()
