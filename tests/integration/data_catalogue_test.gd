## Integration check for W0-E3 story 2: `data/catalogue.tres` is the single
## enumeration of every content resource a run may draw from.
##
## Each test loads the resource itself and never touches the shared run scene,
## so the suite passes in any execution order and relies on no other test.
extends GdUnitTestSuite

const CATALOGUE_PATH := "res://data/catalogue.tres"

const EXPECTED_ENEMIES := 3
const EXPECTED_BOSS := 1
const EXPECTED_WEAPONS := 10
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
		"10 weapons"
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


func test_every_weapon_has_a_unique_id_and_a_known_mechanic() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var seen := {}

	# Act / Assert — W2-E2 adds the six new weapons; a duplicate id would make
	# Inventory.has_weapon() lie, and an unknown token would fall back to cleave.
	for index in catalogue.weapons.size():
		var weapon := catalogue.weapons[index]
		assert_object(weapon).override_failure_message(
			"weapons[%d] is assigned" % index
		).is_not_null()
		if weapon == null:
			continue
		assert_bool(weapon.id.is_empty()).override_failure_message(
			"weapons[%d] has a non-empty id" % index
		).is_false()
		assert_bool(seen.has(weapon.id)).override_failure_message(
			"weapon id '%s' is unique" % weapon.id
		).is_false()
		seen[weapon.id] = true
		assert_bool(weapon.has_known_mechanic()).override_failure_message(
			"weapon '%s' carries a known mechanic, got '%s'" % [weapon.id, weapon.mechanic]
		).is_true()


func test_fallback_upgrade_is_configured_and_never_dead() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var fallback := catalogue.fallback_upgrade

	# Assert — the fallback is what keeps a level-up from ever showing an empty
	# panel, so it must exist, stay part of the normal upgrade list, and carry a
	# stat that a ceiling can never make dead. Crit is checked at its own cap.
	assert_object(fallback).override_failure_message(
		"fallback_upgrade is assigned"
	).is_not_null()
	if fallback == null:
		return
	assert_bool(catalogue.upgrades.has(fallback)).override_failure_message(
		"the fallback is also a normal upgrade, not a hidden special case"
	).is_true()
	var capped_stats := Stats.new()
	capped_stats.crit_chance_bonus = Stats.CRIT_CAP
	assert_bool(capped_stats.is_capped(fallback.stat)).override_failure_message(
		"fallback_upgrade '%s' carries an uncapped stat" % fallback.stat
	).is_false()


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


func test_catalogue_registers_the_three_sets_with_their_design_values() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act / Assert — the values the lot 3 design locked: a set is worth roughly
	# two pieces of its own stat, and every set needs exactly two pieces.
	assert_int(catalogue.sets.size()).override_failure_message(
		"3 equipment sets"
	).is_equal(3)
	var expected := {
		"duelliste": ["crit_chance", 0.12],
		"colosse": ["max_hp", 30.0],
		"coureur_des_bois": ["attack_speed", 0.1],
	}
	var seen := {}
	for set_data in catalogue.sets:
		assert_object(set_data).override_failure_message(
			"every set entry is assigned"
		).is_not_null()
		if set_data == null:
			continue
		assert_bool(seen.has(set_data.id)).override_failure_message(
			"set id '%s' is unique" % set_data.id
		).is_false()
		seen[set_data.id] = true
		assert_int(set_data.required_pieces).override_failure_message(
			"set '%s' is a two-piece set" % set_data.id
		).is_equal(2)
		assert_bool(expected.has(set_data.id)).override_failure_message(
			"set '%s' is one of the designed sets" % set_data.id
		).is_true()
		if not expected.has(set_data.id):
			continue
		assert_str(set_data.stat).override_failure_message(
			"set '%s' grants %s" % [set_data.id, expected[set_data.id][0]]
		).is_equal(expected[set_data.id][0])
		assert_float(set_data.amount).override_failure_message(
			"set '%s' grants %s" % [set_data.id, str(expected[set_data.id][1])]
		).is_equal_approx(float(expected[set_data.id][1]), 0.0001)


func test_every_set_id_names_a_registered_set_with_enough_pieces() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return
	var pieces_by_set := {}

	# Act
	for item in catalogue.equipment:
		if item == null or item.set_id.is_empty():
			continue
		var set_data := catalogue.set_by_id(item.set_id)
		assert_object(set_data).override_failure_message(
			"piece '%s' names registered set '%s'" % [item.id, item.set_id]
		).is_not_null()
		pieces_by_set[item.set_id] = int(pieces_by_set.get(item.set_id, 0)) + 1

	# Assert — no set can ship without the pieces that complete it, and no piece
	# points at a set the catalogue does not carry.
	for set_data in catalogue.sets:
		if set_data == null:
			continue
		assert_int(int(pieces_by_set.get(set_data.id, 0))).override_failure_message(
			"set '%s' has at least %d pieces in the catalogue"
			% [set_data.id, set_data.required_pieces]
		).is_greater_equal(set_data.required_pieces)


func test_the_two_rare_passives_are_carried_by_their_designed_pieces() -> void:
	# Arrange
	var catalogue := _load_catalogue()
	assert_object(catalogue).is_not_null()
	if catalogue == null:
		return

	# Act
	var ring := catalogue.equipment_by_id("anneau_rubis")
	var amulet := catalogue.equipment_by_id("amulette_sang")

	# Assert — the passives live on the two pieces that had no set otherwise.
	assert_object(ring).is_not_null()
	assert_object(amulet).is_not_null()
	if ring == null or amulet == null:
		return
	assert_str(String(ring.passive_id)).is_equal("rage")
	assert_float(ring.passive_value).is_equal_approx(0.15, 0.0001)
	assert_str(String(amulet.passive_id)).is_equal("level_up_heal")
	assert_float(amulet.passive_value).is_equal_approx(8.0, 0.0001)
