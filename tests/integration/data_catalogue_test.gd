## Integration check for W0-E3 story 2: `data/catalogue.tres` is the single
## enumeration of every content resource a run may draw from.
##
## Each test loads the resource itself and never touches the shared run scene,
## so the suite passes in any execution order and relies on no other test.
extends GdUnitTestSuite

const CATALOGUE_PATH := "res://data/catalogue.tres"

const EXPECTED_ENEMIES := 3
const EXPECTED_BOSS := 1
const EXPECTED_WEAPONS := 4
const EXPECTED_EQUIPMENT := 12
const EXPECTED_UPGRADES := 5
const EXPECTED_WAVE := 1
const EXPECTED_CLASS := 1


func _load_catalogue() -> Catalogue:
	return load(CATALOGUE_PATH) as Catalogue


## Fails when two entries of [param list] are the same resource instance. Two
## distinct resources with equal values are allowed; a list that names one file
## twice is not.
func _assert_no_shared_instances(list: Array, label: String) -> void:
	var seen := {}
	for index in list.size():
		var entry: Resource = list[index]
		if entry == null:
			continue
		var instance_id := entry.get_instance_id()
		assert_bool(seen.has(instance_id)).override_failure_message(
			"%s lists the same resource twice, at index %d" % [label, index]
		).is_false()
		seen[instance_id] = true


func test_catalogue_resource_loads() -> void:
	# Arrange / Act
	var catalogue := _load_catalogue()

	# Assert
	assert_object(catalogue).override_failure_message(
		"data/catalogue.tres loads as a Catalogue resource"
	).is_not_null()
	assert_bool(catalogue is Catalogue).override_failure_message(
		"data/catalogue.tres carries the Catalogue script"
	).is_true()


func test_catalogue_lists_have_expected_counts() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Assert — one entry per existing content file, and nothing else.
	assert_int(catalogue.enemies.size()).override_failure_message(
		"3 enemy archetypes"
	).is_equal(EXPECTED_ENEMIES)
	assert_int(catalogue.weapons.size()).override_failure_message(
		"4 weapons"
	).is_equal(EXPECTED_WEAPONS)
	assert_int(catalogue.equipment.size()).override_failure_message(
		"12 pieces of equipment"
	).is_equal(EXPECTED_EQUIPMENT)
	assert_int(catalogue.upgrades.size()).override_failure_message(
		"5 stat upgrades"
	).is_equal(EXPECTED_UPGRADES)
	assert_int(1 if catalogue.boss != null else 0).override_failure_message(
		"1 boss"
	).is_equal(EXPECTED_BOSS)
	assert_int(1 if catalogue.wave != null else 0).override_failure_message(
		"1 wave tuning resource"
	).is_equal(EXPECTED_WAVE)
	assert_int(1 if catalogue.starting_class != null else 0).override_failure_message(
		"1 starting class"
	).is_equal(EXPECTED_CLASS)


func test_every_catalogue_entry_is_not_null() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act / Assert — no blank slot in any list, and each single is present.
	for index in catalogue.enemies.size():
		assert_object(catalogue.enemies[index]).override_failure_message(
			"enemies[%d] is assigned" % index
		).is_not_null()
	for index in catalogue.weapons.size():
		assert_object(catalogue.weapons[index]).override_failure_message(
			"weapons[%d] is assigned" % index
		).is_not_null()
	for index in catalogue.equipment.size():
		assert_object(catalogue.equipment[index]).override_failure_message(
			"equipment[%d] is assigned" % index
		).is_not_null()
	for index in catalogue.upgrades.size():
		assert_object(catalogue.upgrades[index]).override_failure_message(
			"upgrades[%d] is assigned" % index
		).is_not_null()
	assert_object(catalogue.boss).override_failure_message("boss is assigned").is_not_null()
	assert_object(catalogue.wave).override_failure_message("wave is assigned").is_not_null()
	assert_object(catalogue.starting_class).override_failure_message(
		"starting_class is assigned"
	).is_not_null()


func test_boss_is_not_in_the_enemy_pool() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var boss_in_pool := catalogue.enemies.has(catalogue.boss)

	# Assert — the horde must never field the boss.
	assert_bool(boss_in_pool).override_failure_message(
		"boss is absent from enemies"
	).is_false()


func test_no_list_repeats_a_resource_instance() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act / Assert
	_assert_no_shared_instances(catalogue.enemies, "enemies")
	_assert_no_shared_instances(catalogue.weapons, "weapons")
	_assert_no_shared_instances(catalogue.equipment, "equipment")
	_assert_no_shared_instances(catalogue.upgrades, "upgrades")


func test_weapon_lookup_finds_the_stable_id() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var found := catalogue.weapon_by_id("dague")
	var missing := catalogue.weapon_by_id("arme_inconnue")

	# Assert
	assert_object(found).override_failure_message("dague resolves by id").is_not_null()
	if found != null:
		assert_str(found.id).override_failure_message("lookup returns the dague").is_equal("dague")
	assert_object(missing).override_failure_message("unknown id returns null").is_null()


func test_equipment_lookup_finds_the_stable_id() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var found := catalogue.equipment_by_id("casque_fer")
	var missing := catalogue.equipment_by_id("objet_inconnu")

	# Assert
	assert_object(found).override_failure_message(
		"casque_fer resolves by id"
	).is_not_null()
	if found != null:
		assert_str(found.id).override_failure_message(
			"lookup returns the casque de fer"
		).is_equal("casque_fer")
	assert_object(missing).override_failure_message("unknown id returns null").is_null()
