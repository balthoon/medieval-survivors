## Lot 2: weapon-evolution offers on the level-up panel.
##
## An evolution is a dedicated offer, never a weighted candidate: the panel its
## condition unlocks shows it as the first row, it owns the panel's single weapon
## row (A2), and the run allows one evolution in total. The condition is
## declarative — a level on the weapon, optionally an equipment passive — and the
## evolved weapon keeps the level reached, then climbs to its own higher cap.
##
## Every test owns its main scene through MainSceneFixture, so no test depends on
## state left by another.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

## Locale active before a test runs, restored afterwards so no other suite
## inherits a leftover "fr".
var _original_locale: String = ""


func before_test() -> void:
	_original_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_original_locale)


## Every evolution row of the panel.
func _evolution_rows(offers: Array[Offer]) -> Array[Offer]:
	var rows: Array[Offer] = []
	for offer in offers:
		if offer.kind == "weapon_evolution":
			rows.append(offer)
	return rows


## The first catalogue weapon whose evolution needs [param passive_id].
func _catalyst_weapon(main: Variant, passive_id: StringName) -> WeaponData:
	for candidate in main._weapon_pool:
		if candidate != null and candidate.evolution_passive == passive_id:
			return candidate
	return null


func test_evolution_is_never_offered_below_the_required_level() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required() - 1

	# Act
	var rows := _evolution_rows(main._build_offers(200))

	# Assert — the condition is unmet, so the offer must not appear at all.
	assert_int(rows.size()).is_equal(0)


func test_evolution_is_offered_once_the_level_is_reached() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()

	# Act
	var rows := _evolution_rows(main._build_offers(200))

	# Assert
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	assert_object(rows[0].weapon).is_same(weapon)
	assert_object(rows[0].evolved_weapon).is_same(weapon.evolves_into)
	assert_int(rows[0].target_level).is_equal(weapon.evolution_level_required())


func test_evolution_is_the_first_row_of_its_panel() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()

	# Act
	var offers: Array[Offer] = main._build_offers(200)

	# Assert — display priority: the reward is never buried under stat rows.
	assert_int(offers.size()).is_greater(0)
	assert_str(offers[0].kind).is_equal("weapon_evolution")


func test_evolution_panel_carries_no_other_weapon_row() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()

	# Act
	var offers: Array[Offer] = main._build_offers(200)

	# Assert — A2: the evolution owns the panel's single weapon row.
	for offer in offers:
		assert_str(offer.kind).override_failure_message(
			"an evolution panel never shows a second weapon row"
		).is_not_equal("weapon")
		assert_str(offer.kind).is_not_equal("weapon_upgrade")


func test_catalyst_evolution_waits_for_the_passive() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon := _catalyst_weapon(main, &"rage")
	assert_object(weapon).override_failure_message(
		"the catalogue holds a rage-catalysed evolution"
	).is_not_null()
	if weapon == null:
		return
	main._inventory.add_weapon(weapon)
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()

	# Act — the level alone is not enough: the catalyst must be worn.
	var without := _evolution_rows(main._build_offers(200))
	var catalyst: EquipmentData = null
	for item in main._equipment_pool:
		if item != null and item.passive_id == &"rage":
			catalyst = item
			break
	assert_object(catalyst).is_not_null()
	if catalyst == null:
		return
	main._inventory.equip(catalyst)
	var with := _evolution_rows(main._build_offers(200))

	# Assert
	assert_int(without.size()).is_equal(0)
	assert_int(with.size()).is_equal(1)
	if with.is_empty():
		return
	assert_object(with[0].weapon).is_same(weapon)


func test_evolution_row_states_the_kept_level_and_the_new_cap() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	TranslationServer.set_locale("fr")
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()

	# Act
	var rows := _evolution_rows(main._build_offers(200))

	# Assert — nothing is lost: the level is kept and the ceiling opens.
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	var description := rows[0].description
	assert_str(description).contains("conservé")
	assert_str(description).contains("max %d" % weapon.evolves_into.max_level)
	assert_str(description).override_failure_message(
		"the row still prints the evolved weapon's effective numbers"
	).contains("DPS")


func test_taking_the_evolution_keeps_the_level_and_the_cooldown() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	main._weapon_system._cooldowns[0] = 1.5
	var rows := _evolution_rows(main._build_offers(200))
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return

	# Act
	main._apply_offer(rows[0])

	# Assert
	var evolved := weapon.evolves_into
	assert_bool(main._inventory.has_weapon(evolved)).is_true()
	assert_bool(main._inventory.has_weapon(weapon)).is_false()
	assert_int(main._inventory.level_of(evolved)).is_equal(weapon.evolution_level_required())
	assert_str(main._inventory.evolved_weapon_id).is_equal(weapon.id)
	assert_float(main._weapon_system._cooldowns[0]).override_failure_message(
		"evolving mid-run must not hand the weapon a free cooldown reset"
	).is_equal_approx(1.5, 0.0001)


func test_evolution_is_offered_once_then_withdrawn() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var rows := _evolution_rows(main._build_offers(200))
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return

	# Act
	main._apply_offer(rows[0])
	var after := _evolution_rows(main._build_offers(200))

	# Assert — one evolution per run: the offer never comes back.
	assert_int(after.size()).is_equal(0)


func test_evolved_base_is_never_offered_as_a_new_weapon() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var rows := _evolution_rows(main._build_offers(200))
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	main._apply_offer(rows[0])

	# Act — a later panel, with weapon slots gone and the base back in the pool.
	var offers: Array[Offer] = main._build_offers(200)

	# Assert — re-offering the base would undo the evolution.
	for offer in offers:
		if offer.kind == "weapon":
			assert_str(offer.weapon.id).is_not_equal(weapon.id)


func test_evolved_weapon_can_still_be_leveled() -> void:
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
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var rows := _evolution_rows(main._build_offers(200))
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return
	main._apply_offer(rows[0])
	var evolved := weapon.evolves_into

	# Act
	var offers: Array[Offer] = main._build_offers(200)

	# Assert — the evolved cap is 7: the level-4 weapon still has room to grow.
	var upgraded := false
	for offer in offers:
		if offer.kind == "weapon_upgrade" and offer.weapon == evolved:
			upgraded = true
			assert_int(offer.target_level).is_equal(
				weapon.evolution_level_required() + 1
			)
	assert_bool(upgraded).is_true()


func test_evolution_shows_its_banner_and_a_wave_clears_it() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var weapon: WeaponData = main._inventory.weapons[0]
	main._inventory.weapon_levels[weapon.id] = weapon.evolution_level_required()
	var rows := _evolution_rows(main._build_offers(200))
	assert_int(rows.size()).is_equal(1)
	if rows.is_empty():
		return

	# Act
	main._apply_offer(rows[0])

	# Assert — ring, sound and banner are tuned in RunConfig, and the banner
	# names the evolved weapon on the HUD's largest label.
	assert_str(main._hud._wave_banner.text).contains(weapon.evolves_into.display_name)
	assert_bool(main._hud._wave_banner.visible).is_true()
	assert_float(main._hud._banner_time).is_equal_approx(
		main._config.evolution_banner_seconds, 0.0001
	)
	assert_bool(main._hud._wave_banner.has_theme_color_override("font_color")).is_true()

	# Act — the next wave reuses the label.
	main._hud.show_wave_banner(0)

	# Assert — a wave banner must not inherit the evolution colour.
	assert_bool(main._hud._wave_banner.has_theme_color_override("font_color")).is_false()
