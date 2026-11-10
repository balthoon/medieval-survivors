## Lot 2: weapon evolutions.
##
## An evolution is content, not run state: the evolved weapon is its own
## WeaponData, reached only through [member WeaponData.evolves_into] and never
## listed in [member Catalogue.weapons]. The condition is declarative — a level,
## optionally an equipment passive — and the run allows one evolution in total.
## The evolved weapon keeps the level reached and carries its own, higher cap.
##
## Every test builds its own resources: no file, no scene tree, no shared state,
## so the suite passes in any execution order.
extends GdUnitTestSuite


## A base weapon whose evolution is [param evolved], tuned for these tests.
func _weapon(
	id: String = "test_blade",
	evolved: WeaponData = null,
	max_level: int = 4,
	evolution_level: int = 0,
	evolution_passive: StringName = &""
) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = id
	weapon.display_name = "Lame de test"
	weapon.max_level = max_level
	weapon.evolves_into = evolved
	weapon.evolution_level = evolution_level
	weapon.evolution_passive = evolution_passive
	return weapon


## A distinct evolved weapon with its own, higher cap.
func _evolved(id: String = "test_blade_evolved", max_level: int = 7) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = id
	weapon.display_name = "Lame de test évoluée"
	weapon.max_level = max_level
	return weapon


## A kept weapon whose evolution requires [param passive_id].
func _catalyst(passive_id: StringName) -> EquipmentData:
	var item := EquipmentData.new()
	item.id = "test_catalyst"
	item.display_name = "Anneau de test"
	item.slot = "anneau"
	item.passive_id = passive_id
	item.passive_value = 0.15
	return item


func test_weapon_without_an_evolution_is_never_ready() -> void:
	# Arrange
	var weapon := _weapon()
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 10

	# Act / Assert
	assert_bool(weapon.has_evolution()).is_false()
	assert_bool(inventory.evolution_ready(weapon)).is_false()


func test_evolution_requires_the_declared_level() -> void:
	# Arrange
	var evolved := _evolved()
	var weapon := _weapon("test_blade", evolved)
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = weapon.evolution_level_required() - 1

	# Act
	var before := inventory.evolution_ready(weapon)
	inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var after := inventory.evolution_ready(weapon)

	# Assert
	assert_bool(before).override_failure_message(
		"one level below the requirement the evolution stays locked"
	).is_false()
	assert_bool(after).is_true()


func test_evolution_level_falls_back_to_the_base_cap() -> void:
	# Arrange
	var weapon := _weapon("test_blade", _evolved(), 4)
	var early := _weapon("test_early", _evolved("test_early_evolved"), 4, 2)

	# Act / Assert — zero means "at the weapon's own max_level".
	assert_int(weapon.evolution_level_required()).is_equal(4)
	assert_int(early.evolution_level_required()).is_equal(2)


func test_evolution_requires_the_carried_catalyst() -> void:
	# Arrange
	var weapon := _weapon("test_blade", _evolved(), 4, 0, &"rage")
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 4

	# Act
	var without := inventory.evolution_ready(weapon)
	inventory.equip(_catalyst(&"rage"))
	var with := inventory.evolution_ready(weapon)

	# Assert
	assert_bool(without).override_failure_message(
		"the passive is a condition, not a cosmetic: without it the evolution waits"
	).is_false()
	assert_bool(with).is_true()


func test_a_different_passive_does_not_unlock_the_evolution() -> void:
	# Arrange
	var weapon := _weapon("test_blade", _evolved(), 4, 0, &"rage")
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 4
	inventory.equip(_catalyst(&"level_up_heal"))

	# Act — the token is matched exactly, never by containment or by slot.
	var ready := inventory.evolution_ready(weapon)

	# Assert
	assert_bool(ready).is_false()


func test_evolution_preserves_the_level_and_moves_the_entry() -> void:
	# Arrange
	var evolved := _evolved()
	var weapon := _weapon("test_blade", evolved)
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 4

	# Act
	var evolved_ok := inventory.evolve_weapon(weapon)

	# Assert — A5: the evolved weapon keeps the level and opens a higher cap.
	assert_bool(evolved_ok).is_true()
	assert_int(inventory.level_of(evolved)).is_equal(4)
	assert_int(inventory.level_of(weapon)).override_failure_message(
		"the base weapon's level entry is dropped with it"
	).is_equal(1)
	assert_object(inventory.weapons[0]).is_same(evolved)
	assert_str(inventory.evolved_weapon_id).is_equal("test_blade")
	assert_bool(inventory.can_upgrade_weapon(evolved)).is_true()


func test_evolved_weapon_can_reach_its_own_cap() -> void:
	# Arrange
	var evolved := _evolved("test_blade_evolved", 7)
	var weapon := _weapon("test_blade", evolved)
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 4
	inventory.evolve_weapon(weapon)

	# Act
	for _level in 3:
		inventory.upgrade_weapon(evolved)
	var refused := inventory.upgrade_weapon(evolved)

	# Assert — 4 kept plus three levels reaches the evolved cap of 7, no further.
	assert_int(inventory.level_of(evolved)).is_equal(7)
	assert_bool(refused).is_false()


func test_second_evolution_is_refused_in_the_same_run() -> void:
	# Arrange
	var first := _weapon("first", _evolved("first_evolved"))
	var second := _weapon("second", _evolved("second_evolved"))
	var inventory := Inventory.new()
	inventory.add_weapon(first)
	inventory.add_weapon(second)
	inventory.weapon_levels[first.id] = 4
	inventory.weapon_levels[second.id] = 4

	# Act
	var first_ok := inventory.evolve_weapon(first)
	var second_ready := inventory.evolution_ready(second)
	var second_ok := inventory.evolve_weapon(second)

	# Assert — one evolution per run, whatever the second weapon's state.
	assert_bool(first_ok).is_true()
	assert_bool(second_ready).is_false()
	assert_bool(second_ok).is_false()
	assert_object(inventory.weapons[1]).is_same(second)


func test_evolution_refuses_a_weapon_not_carried() -> void:
	# Arrange
	var weapon := _weapon("test_blade", _evolved())
	var inventory := Inventory.new()
	inventory.weapon_levels[weapon.id] = 4

	# Act
	var evolved := inventory.evolve_weapon(weapon)

	# Assert
	assert_bool(evolved).is_false()
	assert_str(inventory.evolved_weapon_id).is_empty()


func test_new_run_clears_the_evolution() -> void:
	# Arrange
	var weapon := _weapon("test_blade", _evolved())
	var inventory := Inventory.new()
	inventory.setup_starting(weapon)
	inventory.weapon_levels[weapon.id] = 4
	inventory.evolve_weapon(weapon)

	# Act
	inventory.setup_starting(weapon)

	# Assert — a fresh run can evolve again, and the base is the carried weapon.
	assert_str(inventory.evolved_weapon_id).is_empty()
	assert_bool(inventory.has_evolved_from(weapon)).is_false()
	assert_object(inventory.weapons[0]).is_same(weapon)
	assert_int(inventory.level_of(weapon)).is_equal(1)


func test_evolution_marks_the_base_as_spent() -> void:
	# Arrange
	var evolved := _evolved()
	var weapon := _weapon("test_blade", evolved)
	var inventory := Inventory.new()
	inventory.add_weapon(weapon)
	inventory.weapon_levels[weapon.id] = 4

	# Act
	inventory.evolve_weapon(weapon)

	# Assert — the base must leave the acquisition pool, or a later panel could
	# hand it back and undo the evolution.
	assert_bool(inventory.has_evolved_from(weapon)).is_true()


func test_evolution_offer_carries_both_weapons_and_keeps_the_level() -> void:
	# Arrange
	var evolved := _evolved()
	var weapon := _weapon("test_blade", evolved)

	# Act
	var offer := Offer.for_weapon_evolution(weapon, evolved, 4)

	# Assert
	assert_str(offer.kind).is_equal("weapon_evolution")
	assert_object(offer.weapon).is_same(weapon)
	assert_object(offer.evolved_weapon).is_same(evolved)
	assert_int(offer.target_level).is_equal(4)
	assert_str(offer.title).contains("Lame de test évoluée")
	assert_str(offer.description).is_equal(evolved.description)
