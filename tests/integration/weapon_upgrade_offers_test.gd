## Lot 1: weapon-level offers on the level-up panel.
##
## A level-up panel carries at most one weapon row, and that row is either a
## new weapon or a level for a carried one — never both (A2). A weapon at its
## max level leaves the draw, so a panel never spends a row on a choice that
## would change nothing. Every test owns its main scene through
## MainSceneFixture, so no test depends on state left by another.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

## Locale active before a test runs, restored afterwards so no other suite
## inherits a leftover "fr".
var _original_locale: String = ""


func before_test() -> void:
	_original_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_original_locale)


## Every offer of the panel that would add or level a weapon.
func _weapon_rows(offers: Array[Offer]) -> Array[Offer]:
	var rows: Array[Offer] = []
	for offer in offers:
		if offer.kind == "weapon" or offer.kind == "weapon_upgrade":
			rows.append(offer)
	return rows


func test_panel_carries_at_most_one_weapon_row() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true

	# Act
	var rows := _weapon_rows(main._build_offers(200))

	# Assert — two free slots and one upgradable weapon still share one row.
	assert_int(rows.size()).override_failure_message(
		"acquisitions and upgrades compete for a single weapon row"
	).is_equal(1)


func test_upgrade_row_targets_the_next_level_and_shows_its_numbers() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	# The row's rendered text is French; pin the locale so the test does not
	# depend on the machine's or the CI runner's language (after_test restores it).
	TranslationServer.set_locale("fr")
	# Keep only the upgrade candidate: a pool with no new weapon makes the row
	# deterministic without relying on a lucky shuffle.
	main._weapon_pool.clear()
	var weapon: WeaponData = main._inventory.weapons[0]

	# Act
	var rows := _weapon_rows(main._build_offers(200))

	# Assert
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	var offer := rows[0]
	assert_str(offer.kind).is_equal("weapon_upgrade")
	assert_object(offer.weapon).is_same(weapon)
	assert_int(offer.target_level).is_equal(2)
	assert_str(offer.title).contains("niv. 2")
	assert_str(offer.description).contains("niv. 1 → 2")
	assert_str(offer.description).override_failure_message(
		"the row is decorated with the next level's effective numbers"
	).contains("DPS")


func test_rendered_numbers_follow_the_active_locale() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	TranslationServer.set_locale("en")
	main._weapon_pool.clear()

	# Act
	var rows := _weapon_rows(main._build_offers(200))

	# Assert — the whole numbers line is translated, not just the level segment:
	# an English client must never read "lvl 1 → 2 · 12 dégâts".
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	var description := rows[0].description
	assert_str(description).contains("lvl 1 → 2")
	assert_str(description).override_failure_message(
		"the numbers line follows the active locale"
	).contains("damage")
	assert_str(description).not_contains("dégâts")


func test_weapon_at_max_level_is_never_offered_for_upgrade() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._weapon_pool.clear()
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.max_level

	# Act
	var rows := _weapon_rows(main._build_offers(200))

	# Assert
	assert_int(rows.size()).override_failure_message(
		"a capped weapon leaves the draw instead of wasting a row"
	).is_equal(0)


func test_chosen_upgrade_raises_the_level_and_keeps_the_cooldown() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._weapon_system._cooldowns[0] = 1.5

	# Act
	main._apply_offer(Offer.for_weapon_upgrade(weapon, 2))

	# Assert
	assert_int(main._inventory.level_of(weapon)).is_equal(2)
	assert_float(main._weapon_system._cooldowns[0]).override_failure_message(
		"rebuilding the view must not hand the weapon a free cooldown reset"
	).is_equal_approx(1.5, 0.0001)


func test_upgrade_of_a_capped_weapon_changes_nothing() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.max_level

	# Act
	main._apply_offer(Offer.for_weapon_upgrade(weapon, weapon.max_level + 1))

	# Assert
	assert_int(main._inventory.level_of(weapon)).is_equal(weapon.max_level)


func test_new_weapon_enters_at_level_one() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var new_weapon: WeaponData = null
	for candidate in main._weapon_pool:
		if candidate != null and not main._inventory.has_weapon(candidate):
			new_weapon = candidate
			break
	assert_object(new_weapon).override_failure_message(
		"the catalogue holds a weapon the player does not carry yet"
	).is_not_null()
	if new_weapon == null:
		return

	# Act
	main._apply_offer(Offer.for_weapon(new_weapon))

	# Assert
	assert_int(main._inventory.level_of(new_weapon)).is_equal(1)


func test_upgrade_weight_comes_from_the_run_config() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._weapon_pool.clear()

	# Act
	var rows := _weapon_rows(main._build_offers(200))

	# Assert
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	assert_float(rows[0].weight).is_equal_approx(main._config.weapon_upgrade_weight, 0.0001)


func test_explicit_weapon_weight_also_weights_upgrade_rows() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._weapon_pool.clear()

	# Act — the boss loot panel's override.
	var rows := _weapon_rows(main._build_offers(200, 3.0, 2.5))

	# Assert
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	assert_float(rows[0].weight).is_equal_approx(3.0, 0.0001)
