## Lot 3: what equipment identity changes inside a real run.
##
## The unit suite covers the rules in isolation (Stats, Inventory, the
## resources). This suite drives the real main scene to prove the wiring: set
## bonuses are rebuilt and applied once, the rage passive reaches weapon damage,
## the amulet heals on a level-up, and an equipment offer prints the passive and
## the set line. Every test owns its scene through MainSceneFixture.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")


## Instantiates the run and stops the wave director, so the test only sees what
## it equips itself. Pauses the run by default: the rage test relies on the
## health fraction staying put between two reads.
func _start_run(suite: Node, paused: bool = true) -> Node:
	var main: Variant = MainSceneFixture.instantiate(suite)
	if main == null:
		return null
	await MainSceneFixture.await_ready(suite)
	MainSceneFixture.silence_waves(main)
	main.is_paused = paused
	return main


## A piece of the catalogue by id, asserting it exists.
func _piece(main: Variant, id: String) -> EquipmentData:
	var item: EquipmentData = main.catalogue.equipment_by_id(id)
	assert_object(item).override_failure_message("catalogue holds '%s'" % id).is_not_null()
	return item


func test_duelliste_bonus_is_applied_once_with_both_pieces_worn() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var base_crit: float = main._player.stats.crit_chance_bonus
	var casque := _piece(main, "casque_ancien")
	var gants := _piece(main, "gants_precis")
	assert_object(casque).is_not_null()
	assert_object(gants).is_not_null()
	if casque == null or gants == null:
		return

	# Act
	main._inventory.equip(casque)
	main._recompute_stats()
	var with_one: float = main._player.stats.crit_chance_bonus
	main._inventory.equip(gants)
	main._recompute_stats()
	var with_both: float = main._player.stats.crit_chance_bonus
	# A second rebuild must not stack the set on top of itself.
	main._recompute_stats()
	var rebuilt: float = main._player.stats.crit_chance_bonus
	var completed: PackedStringArray = main._completed_set_ids()

	# Assert
	assert_float(with_one).is_equal_approx(base_crit + casque.amount, 0.0001)
	assert_float(with_both).override_failure_message(
		"two Duelliste pieces add +12 % crit on top of their own +16 %"
	).is_equal_approx(base_crit + casque.amount + gants.amount + 0.12, 0.0001)
	assert_float(rebuilt).override_failure_message(
		"rebuilding the stats applies the set once, never cumulatively"
	).is_equal_approx(with_both, 0.0001)
	assert_bool(completed.has("duelliste")).is_true()


func test_swapping_a_set_piece_removes_the_bonus() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var base_crit: float = main._player.stats.crit_chance_bonus
	var casque := _piece(main, "casque_ancien")
	var gants := _piece(main, "gants_precis")
	var replacement := _piece(main, "gants_fer")
	assert_object(replacement).is_not_null()
	if casque == null or gants == null or replacement == null:
		return
	main._inventory.equip(casque)
	main._inventory.equip(gants)
	main._recompute_stats()

	# Act — the glove slot loses its set piece.
	main._inventory.equip(replacement)
	main._recompute_stats()

	# Assert — only the helmet's own crit remains; no set bonus, no ghost piece.
	assert_float(main._player.stats.crit_chance_bonus).override_failure_message(
		"breaking the set removes its +12 % crit"
	).is_equal_approx(base_crit + casque.amount, 0.0001)
	assert_bool(main._completed_set_ids().has("duelliste")).is_false()


func test_helmet_choice_completes_one_set_or_the_other() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var base_hp: float = main._player.stats.max_hp
	var casque_fer := _piece(main, "casque_fer")
	var casque_ancien := _piece(main, "casque_ancien")
	var plastron := _piece(main, "plastron_mailles")
	var gants := _piece(main, "gants_precis")
	assert_object(plastron).is_not_null()
	if casque_fer == null or casque_ancien == null or plastron == null or gants == null:
		return
	main._inventory.equip(casque_ancien)
	main._inventory.equip(gants)
	main._recompute_stats()
	var duelliste_hp: float = main._player.stats.max_hp

	# Act — the iron helmet displaces the ancient one.
	main._inventory.equip(casque_fer)
	main._recompute_stats()
	var switched_hp: float = main._player.stats.max_hp
	var after_switch: PackedStringArray = main._completed_set_ids()
	main._inventory.equip(plastron)
	main._recompute_stats()
	var colosse_hp: float = main._player.stats.max_hp

	# Assert — Colosse takes the helmet slot, so both sets can never be complete.
	assert_float(duelliste_hp).is_equal_approx(base_hp, 0.0001)
	assert_bool(after_switch.has("duelliste")).override_failure_message(
		"the iron helmet breaks the Duelliste set"
	).is_false()
	assert_bool(after_switch.has("colosse")).override_failure_message(
		"Colosse still misses its chest piece"
	).is_false()
	assert_float(colosse_hp).override_failure_message(
		"Colosse = iron helmet + mail chest + its +30 HP bonus"
	).is_equal_approx(base_hp + casque_fer.amount + plastron.amount + 30.0, 0.0001)
	assert_bool(main._completed_set_ids().has("colosse")).is_true()


func test_rage_ring_raises_weapon_damage_below_half_health() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var ring := _piece(main, "anneau_rubis")
	assert_object(ring).is_not_null()
	if ring == null:
		return
	main._inventory.equip(ring)
	main._recompute_stats()
	var stats: Stats = main._player.stats
	var weapon: WeaponData = main._inventory.weapons[0]
	main._player.hp = stats.max_hp
	main._recompute_stats()

	# Act
	var healthy: float = main._player.stats.weapon_damage(
		weapon, main._inventory.level_of(weapon)
	)
	main._player.hp = main._player.stats.max_hp * 0.3
	main._recompute_stats()
	var enraged: float = main._player.stats.weapon_damage(
		weapon, main._inventory.level_of(weapon)
	)

	# Assert — 15 % more damage, on top of the ring's own +22 %.
	assert_float(main._player.stats.rage_bonus).is_equal_approx(0.15, 0.0001)
	assert_float(enraged / healthy).override_failure_message(
		"rage multiplies weapon damage by 1.15 below the threshold"
	).is_equal_approx(1.15, 0.0001)


func test_amulette_heals_on_every_level_gained() -> void:
	# Arrange
	var main: Variant = await _start_run(self, false)
	assert_object(main).is_not_null()
	if main == null:
		return
	var amulet := _piece(main, "amulette_sang")
	assert_object(amulet).is_not_null()
	if amulet == null:
		return
	main._inventory.equip(amulet)
	main._recompute_stats()
	main._player.hp = 50.0
	var before_level: int = main._level

	# Act — cross the experience threshold with the panel free to open.
	main._xp = main._xp_needed
	main._check_level_up()

	# Assert
	assert_int(main._level).is_equal(before_level + 1)
	assert_float(main._player.hp).override_failure_message(
		"the amulet restores 8 HP before the panel opens"
	).is_equal_approx(58.0, 0.0001)
	assert_str(main._hud._panel_title.text).override_failure_message(
		"the panel title names the amount the amulet restored"
	).contains("8")


func test_level_up_heal_reports_zero_at_full_health() -> void:
	# Arrange
	var main: Variant = await _start_run(self, false)
	assert_object(main).is_not_null()
	if main == null:
		return
	var amulet := _piece(main, "amulette_sang")
	assert_object(amulet).is_not_null()
	if amulet == null:
		return
	main._inventory.equip(amulet)
	main._recompute_stats()
	main._player.hp = main._player.stats.max_hp

	# Act — at full health the 8 HP heal restores nothing.
	main._xp = main._xp_needed
	main._check_level_up()

	# Assert — the title reports the measured heal, never the nominal 8.
	assert_str(main._hud._panel_title.text).override_failure_message(
		"a full-health level up shows +0, never the amulet's nominal +8"
	).contains("+0")
	assert_str(main._hud._panel_title.text).not_contains("8")


func test_hud_summary_reports_set_progress_and_completion() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	# A fresh run wears no set piece, so the line stays out of the way.
	assert_bool(main._hud._set_summary.visible).is_false()
	var casque_fer := _piece(main, "casque_fer")
	var plastron := _piece(main, "plastron_mailles")
	assert_object(casque_fer).is_not_null()
	assert_object(plastron).is_not_null()
	if casque_fer == null or plastron == null:
		return
	main._inventory.equip(casque_fer)
	main._inventory.equip(plastron)
	main._recompute_stats()

	# Act
	main._refresh_hud()

	# Assert — completion is spelled out, with the same diamond as the rows.
	assert_bool(main._hud._set_summary.visible).is_true()
	assert_str(main._hud._set_summary.text).contains("Colosse 2/2")
	assert_str(main._hud._set_summary.text).contains("◆")

	# Act — the ancient helmet breaks Colosse and starts Duelliste.
	var casque_ancien := _piece(main, "casque_ancien")
	assert_object(casque_ancien).is_not_null()
	if casque_ancien == null:
		return
	main._inventory.equip(casque_ancien)
	main._recompute_stats()
	main._refresh_hud()

	# Assert — both sets are now one piece short, and neither is marked.
	assert_str(main._hud._set_summary.text).contains("Colosse 1/2")
	assert_str(main._hud._set_summary.text).contains("Duelliste 1/2")
	assert_str(main._hud._set_summary.text).not_contains("◆")


func test_hud_marks_rage_on_the_piece_that_carries_it() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var ring := _piece(main, "anneau_rubis")
	assert_object(ring).is_not_null()
	if ring == null:
		return
	main._inventory.equip(ring)
	main._recompute_stats()
	main._player.hp = main._player.stats.max_hp
	main._recompute_stats()
	main._refresh_hud()
	var marker := Loc.text("equipment.rage_active", "ACTIF")
	var healthy_line: String = main._hud._equipment_labels[4].text

	# Act — below the threshold the ring's line names the state.
	main._player.hp = main._player.stats.max_hp * 0.3
	main._recompute_stats()
	main._refresh_hud()
	var enraged_line: String = main._hud._equipment_labels[4].text

	# Assert
	assert_str(healthy_line).not_contains(marker)
	assert_str(enraged_line).override_failure_message(
		"the rage state is written on the ring's line, not shown by colour alone"
	).contains(marker)


func test_equipment_offer_describes_the_passive_and_the_set() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var ring := _piece(main, "anneau_rubis")
	var helmet := _piece(main, "casque_ancien")
	assert_object(ring).is_not_null()
	assert_object(helmet).is_not_null()
	if ring == null or helmet == null:
		return

	# Act
	var ring_offer := Offer.for_equipment(ring)
	main._decorate_offer(ring_offer)
	var helmet_offer := Offer.for_equipment(helmet)
	main._decorate_offer(helmet_offer)

	# Assert — the two lines are locale-independent: the value and the set name
	# show in both French and English.
	assert_str(ring_offer.description).override_failure_message(
		"an offer names the rage passive and its numbers"
	).contains("15")
	assert_str(ring_offer.description).contains("50")
	assert_str(helmet_offer.description).override_failure_message(
		"a set piece shows the set it would advance"
	).contains("Duelliste")
	assert_str(helmet_offer.description).contains("(1/2)")


func test_equipment_offer_names_the_completion_bonus() -> void:
	# Arrange
	var main: Variant = await _start_run(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	var helmet := _piece(main, "casque_ancien")
	var gloves := _piece(main, "gants_precis")
	assert_object(helmet).is_not_null()
	assert_object(gloves).is_not_null()
	if helmet == null or gloves == null:
		return
	main._inventory.equip(gloves)

	# Act
	var offer := Offer.for_equipment(helmet)
	main._decorate_offer(offer)

	# Assert — taking the helmet completes the set, so the line announces the
	# bonus instead of the progress.
	assert_str(offer.description).contains("Duelliste")
	assert_str(offer.description).override_failure_message(
		"a completing piece shows the bonus, not (2/2)"
	).contains("12")
	assert_str(offer.description).not_contains("(2/2)")
