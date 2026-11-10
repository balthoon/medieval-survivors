## Unit check for the stat ceilings a level-up offer must respect.
##
## [method Stats.is_capped] answers for the player's bonus alone;
## [method Stats.crit_is_capped_for] answers for the weapons actually carried.
## Both are needed: a 0.70 bonus is below the cap, but a 0.05-base weapon
## already crits at 0.75, so the bonus is dead without being capped itself.
##
## Plain RefCounted data, no scene and no shared state, so the suite passes in
## any execution order.
extends GdUnitTestSuite

## Weapon base crit used in the tests. Below the cap on its own.
const LOW_BASE_CRIT := 0.05


func _weapon_with_crit(base_crit: float) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.crit_chance = base_crit
	return weapon


func test_uncapped_stats_never_report_capped() -> void:
	# Arrange — crit is pushed to its ceiling, so any wrongly shared cap shows.
	var stats := Stats.new()
	stats.crit_chance_bonus = Stats.CRIT_CAP

	# Act / Assert
	for stat in ["damage", "attack_speed", "max_hp", "move_speed", "range"]:
		assert_bool(stats.is_capped(stat)).override_failure_message(
			"'%s' is uncapped and must never be treated as dead" % stat
		).is_false()


func test_crit_bonus_is_capped_only_at_the_ceiling() -> void:
	# Arrange
	var stats := Stats.new()

	# Act / Assert
	stats.crit_chance_bonus = Stats.CRIT_CAP - 0.1
	assert_bool(stats.is_capped("crit_chance")).override_failure_message(
		"a bonus below the ceiling can still grow"
	).is_false()
	stats.crit_chance_bonus = Stats.CRIT_CAP
	assert_bool(stats.is_capped("crit_chance")).override_failure_message(
		"a bonus at the ceiling cannot grow"
	).is_true()


func test_empty_loadout_counts_as_crit_capped() -> void:
	# Arrange
	var stats := Stats.new()
	var no_weapons: Array[WeaponData] = []

	# Act
	var capped := stats.crit_is_capped_for(no_weapons)

	# Assert — no weapon can benefit from a crit bonus.
	assert_bool(capped).override_failure_message(
		"an empty loadout has nothing a crit bonus could raise"
	).is_true()


func test_crit_stays_offerable_while_one_weapon_can_benefit() -> void:
	# Arrange — the second weapon is at the cap, the first is far from it.
	var stats := Stats.new()
	var weapons: Array[WeaponData] = [
		_weapon_with_crit(LOW_BASE_CRIT),
		_weapon_with_crit(Stats.CRIT_CAP),
	]

	# Act
	var capped := stats.crit_is_capped_for(weapons)

	# Assert
	assert_bool(capped).override_failure_message(
		"one weapon still below the cap keeps the bonus useful"
	).is_false()


func test_weapon_base_crit_reaching_the_cap_is_capped_before_the_bonus() -> void:
	# Arrange — the defect this pair of methods exists for: the bonus alone is
	# 0.05 short of the ceiling, yet 0.05 + 0.70 already lands exactly on it.
	var stats := Stats.new()
	stats.crit_chance_bonus = Stats.CRIT_CAP - LOW_BASE_CRIT
	var weapons: Array[WeaponData] = [_weapon_with_crit(LOW_BASE_CRIT)]

	# Act
	var bonus_capped := stats.is_capped("crit_chance")
	var all_weapons_capped := stats.crit_is_capped_for(weapons)

	# Assert
	assert_bool(bonus_capped).override_failure_message(
		"the bonus itself is below the ceiling"
	).is_false()
	assert_bool(all_weapons_capped).override_failure_message(
		"every carried weapon already crits at the ceiling"
	).is_true()


func test_null_weapon_entries_are_ignored() -> void:
	# Arrange — a blank slot must not make the loadout look un-capped.
	var stats := Stats.new()
	var weapons: Array[WeaponData] = [null, _weapon_with_crit(Stats.CRIT_CAP)]

	# Act
	var capped := stats.crit_is_capped_for(weapons)

	# Assert
	assert_bool(capped).override_failure_message(
		"null entries add no weapon that could benefit"
	).is_true()
