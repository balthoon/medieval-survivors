## Regression suite for the level-up offer pool.
##
## A stat at its ceiling must never be offered, and a level-up must never be
## spent on an empty panel. Every test owns its main scene through
## MainSceneFixture, so no test depends on state left by another.
##
## The ceiling tests use a fully capped crit chance: the precision upgrade and
## the two crit pieces are then dead choices, whatever the draw order. The pool
## is emptied on purpose in the fallback test, and the catalogue is replaced in
## the level-consumption test, so both target the guarantee rather than luck.
## Both also spend the run's one evolution, so the weapon branch is closed
## rather than merely quiet (lot 2).
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

## Highest crit chance a hit can reach. Kept local so the suite fails on the
## behaviour, not on a constant moved in the production code.
const CRIT_CAP := 0.75


## Removes every weapon candidate from [param main]'s panel: each carried weapon
## is held at its cap (lot 1) and the run's one evolution is spent (lot 2), with
## its evolved form capped too. This is the loadout where the weapon branch can
## build nothing, which is what the two fallback tests need.
func _spend_weapon_candidates(main: Variant) -> void:
	for carried in main._inventory.weapons:
		if carried != null:
			main._inventory.weapon_levels[carried.id] = maxi(carried.max_level, 1)
	if main._inventory.weapons.is_empty():
		return
	var first: WeaponData = main._inventory.weapons[0]
	if first == null or not main._inventory.evolve_weapon(first):
		return
	var evolved: WeaponData = first.evolves_into
	if evolved != null:
		main._inventory.weapon_levels[evolved.id] = maxi(evolved.max_level, 1)


func test_capped_crit_upgrade_is_never_offered() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._base_stats.crit_chance_bonus = CRIT_CAP
	main._recompute_stats()

	var precision_is_configured := false
	for upgrade in main._upgrades:
		if upgrade != null and upgrade.stat == "crit_chance":
			precision_is_configured = true

	# Act
	var crit_offers := 0
	for offer in main._build_offers(200):
		if offer.kind == "stat" and offer.stat_upgrade != null:
			if offer.stat_upgrade.stat == "crit_chance":
				crit_offers += 1

	# Assert
	assert_bool(precision_is_configured).override_failure_message(
		"the catalogue still configures a crit upgrade, so the check is not vacuous"
	).is_true()
	assert_int(crit_offers).override_failure_message(
		"a capped crit stat is never offered"
	).is_equal(0)


func test_capped_crit_equipment_is_never_offered() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._base_stats.crit_chance_bonus = CRIT_CAP
	main._recompute_stats()

	# Keep only the crit pieces in the equipment pool: a single call with a
	# count above the pool size then proves their absence without relying on a
	# lucky draw.
	var crit_items: Array[EquipmentData] = []
	for item in main._equipment_pool:
		if item != null and item.stat == "crit_chance":
			crit_items.append(item)
	main._equipment_pool.assign(crit_items)

	# Act
	var crit_offers := 0
	for offer in main._build_offers(200):
		if offer.kind == "equipment" and offer.equipment != null:
			if offer.equipment.stat == "crit_chance":
				crit_offers += 1

	# Assert
	assert_int(crit_items.size()).override_failure_message(
		"the catalogue holds crit pieces, so the check is not vacuous"
	).is_greater(0)
	assert_int(crit_offers).override_failure_message(
		"capped crit equipment is never offered"
	).is_equal(0)


func test_empty_candidate_pool_falls_back_to_an_offer() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	main._upgrades.clear()
	main._weapon_pool.clear()
	main._equipment_pool.clear()
	# Nothing at all must remain applicable: the weapon branch is closed by the
	# helper, and every other pool was just cleared.
	_spend_weapon_candidates(main)

	# Act
	var offers: Array[Offer] = main._build_offers(3)

	# Assert
	assert_int(offers.size()).override_failure_message(
		"an empty pool still yields at least one offer"
	).is_greater(0)
	if not offers.is_empty():
		assert_str(offers[0].kind).override_failure_message(
			"the fallback is a stat upgrade"
		).is_equal("stat")


func test_level_is_not_consumed_when_no_offer_exists() -> void:
	# Arrange
	var main: Variant = MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	# Replace the catalogue and re-copy it: no upgrade, no fallback, no content.
	main.catalogue = Catalogue.new()
	main._load_data()
	# The weapon branch is closed by the helper, or the panel is never empty.
	_spend_weapon_candidates(main)
	main.is_paused = false
	main._dead = false
	main._level = 1
	main._xp = main._xp_needed

	# Act
	main._check_level_up()

	# Assert
	assert_int(main._level).override_failure_message(
		"a level with nothing to offer is not consumed"
	).is_equal(1)
	assert_float(main._xp).override_failure_message(
		"the XP that triggered the level-up is kept"
	).is_equal_approx(main._xp_needed, 0.001)
	assert_bool(main._pending_choices.is_empty()).override_failure_message(
		"no panel is opened for an empty pool"
	).is_true()
