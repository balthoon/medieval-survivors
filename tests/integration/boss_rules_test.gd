## Rule checks for slice 0.4, ported from tools/verify_slice04.gd.
##
## Covers the checks that need no live combat: boss wiring, wave cadence, tier
## scaling, telegraph timing, range gating, knockback resistance, spawner
## filtering, the run's finish line and the offer-panel slot rules. The
## live-combat checks from the same source (boss wave spawn, slam damage and
## boss loot) live in a separate suite.
##
## Every test builds its own real main scene through MainSceneFixture and freezes
## it, so gdUnit4 may run the tests in any order.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const BOSS_PATH := "res://data/enemies/seigneur_squelette.tres"
const SQUELETTE_PATH := "res://data/enemies/squelette.tres"
const WAVE_PATH := "res://data/waves/base_wave.tres"
const DAGUE_PATH := "res://data/weapons/dague.tres"
const MARTEAU_PATH := "res://data/weapons/marteau.tres"

## Wave index of the first boss wave. Must stay in step with
## WaveData.boss_every_waves.
const FIRST_BOSS_WAVE := 4
const BOSS_EVERY := 5

## Float tolerance used by the source script's comparisons.
const TOLERANCE := 0.001


func test_wiring_loads_boss_data_and_boss_audio() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	# Act
	var boss_data: EnemyData = main._boss_data
	var sfx: Sfx = main._sfx
	var roar: AudioStream = null
	var slam: AudioStream = null
	if sfx != null:
		roar = sfx._streams.get("boss_roar", null) as AudioStream
		slam = sfx._streams.get("boss_slam", null) as AudioStream

	# Assert
	assert_object(boss_data).override_failure_message("boss resource loaded").is_not_null()
	assert_int(1 if boss_data != null and boss_data.is_elite else 0) \
		.override_failure_message("boss is flagged elite").is_equal(1)
	assert_object(roar).override_failure_message("boss_roar stream loaded").is_not_null()
	assert_object(slam).override_failure_message("boss_slam stream loaded").is_not_null()


func test_boss_cadence_marks_every_fifth_wave() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var wave_data := load(WAVE_PATH) as WaveData
	var director := WaveDirector.new()

	# Act
	director.setup(wave_data)
	var wave_0_is_boss := director.is_boss_wave(0)
	var wave_3_is_boss := director.is_boss_wave(3)
	var wave_4_is_boss := director.is_boss_wave(FIRST_BOSS_WAVE)
	var wave_5_is_boss := director.is_boss_wave(5)
	var wave_9_is_boss := director.is_boss_wave(FIRST_BOSS_WAVE + BOSS_EVERY)
	var wave_14_is_boss := director.is_boss_wave(FIRST_BOSS_WAVE + 2 * BOSS_EVERY)
	var negative_is_boss := director.is_boss_wave(-3)
	var first_tier := director.boss_tier(FIRST_BOSS_WAVE)
	var second_tier := director.boss_tier(FIRST_BOSS_WAVE + BOSS_EVERY)
	var third_tier := director.boss_tier(FIRST_BOSS_WAVE + 2 * BOSS_EVERY)
	var off_tier := director.boss_tier(3)

	# The interval at wave 4 is the cooled-down cadence for that wave, stretched
	# by the boss scale.
	director.wave_index = FIRST_BOSS_WAVE
	var boss_interval := director.spawn_interval()
	var expected_boss_interval := (
		wave_data.base_spawn_interval
		* pow(wave_data.interval_decay_per_wave, float(FIRST_BOSS_WAVE))
		* wave_data.boss_spawn_interval_scale
	)

	# Zero disables bosses entirely, which is how a prototype turns them off.
	var no_boss := WaveData.new()
	no_boss.boss_every_waves = 0
	director.setup(no_boss)
	var disabled_is_boss := director.is_boss_wave(9)

	# Assert
	assert_int(1 if wave_0_is_boss else 0) \
		.override_failure_message("wave 0 is not a boss wave").is_equal(0)
	assert_int(1 if wave_3_is_boss else 0) \
		.override_failure_message("wave 3 is not a boss wave").is_equal(0)
	assert_int(1 if wave_4_is_boss else 0) \
		.override_failure_message("wave 4 is a boss wave").is_equal(1)
	assert_int(1 if wave_5_is_boss else 0) \
		.override_failure_message("wave 5 is not a boss wave").is_equal(0)
	assert_int(1 if wave_9_is_boss else 0) \
		.override_failure_message("wave 9 is a boss wave").is_equal(1)
	assert_int(1 if wave_14_is_boss else 0) \
		.override_failure_message("wave 14 is a boss wave").is_equal(1)
	assert_int(1 if negative_is_boss else 0) \
		.override_failure_message("negative wave is not a boss wave").is_equal(0)
	assert_int(first_tier).override_failure_message("first boss tier").is_equal(0)
	assert_int(second_tier).override_failure_message("second boss tier").is_equal(1)
	assert_int(third_tier).override_failure_message("third boss tier").is_equal(2)
	assert_int(off_tier).override_failure_message("no tier off a boss wave").is_equal(-1)
	assert_float(boss_interval) \
		.override_failure_message("boss wave stretches the spawn interval") \
		.is_equal_approx(expected_boss_interval, TOLERANCE)
	assert_int(1 if disabled_is_boss else 0) \
		.override_failure_message("boss_every_waves=0 disables bosses").is_equal(0)


func test_boss_scaling_applies_tier_multipliers() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var boss_data := load(BOSS_PATH) as EnemyData
	var plain_data := load(SQUELETTE_PATH) as EnemyData

	# Act
	var boss := Enemy.create(boss_data, 1.0, 1.0)
	auto_free(boss)
	var scaled := Enemy.create(boss_data, 1.9, 1.35)
	auto_free(scaled)
	var plain := Enemy.create(plain_data)
	auto_free(plain)

	# Assert
	assert_float(boss.max_hp) \
		.override_failure_message("tier 0 keeps the authored hp").is_equal_approx(480.0, TOLERANCE)
	assert_float(boss.contact_damage) \
		.override_failure_message("tier 0 keeps the authored contact damage") \
		.is_equal_approx(16.0, TOLERANCE)
	assert_float(boss.slam_damage) \
		.override_failure_message("tier 0 keeps the authored slam damage") \
		.is_equal_approx(22.0, TOLERANCE)
	assert_float(boss.slam_radius) \
		.override_failure_message("slam radius is not scaled").is_equal_approx(96.0, TOLERANCE)
	assert_float(boss.hp) \
		.override_failure_message("boss spawns at full hp").is_equal_approx(480.0, TOLERANCE)
	assert_float(scaled.max_hp) \
		.override_failure_message("tier 1 scales hp").is_equal_approx(912.0, TOLERANCE)
	assert_float(scaled.contact_damage) \
		.override_failure_message("tier 1 scales contact damage").is_equal_approx(21.6, TOLERANCE)
	assert_float(scaled.slam_damage) \
		.override_failure_message("tier 1 scales slam damage").is_equal_approx(29.7, TOLERANCE)
	assert_float(plain.max_hp) \
		.override_failure_message("plain enemy max hp is its own").is_equal_approx(20.0, TOLERANCE)
	assert_float(plain.slam_damage) \
		.override_failure_message("plain enemy has no slam").is_equal_approx(0.0, TOLERANCE)
	assert_int(1 if plain.is_telegraphing() else 0) \
		.override_failure_message("plain enemy does not telegraph").is_equal(0)


func test_telegraph_timing_lands_one_strike_per_windup() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	auto_free(boss)
	boss.position = Vector2.ZERO
	var strikes := [0]
	var last_damage := [0.0]
	boss.slam_struck.connect(
		func(_at: Vector2, _radius: float, damage: float) -> void:
			strikes[0] += 1
			last_damage[0] = damage
	)

	# Act
	# The boss starts inside range, so the first step opens the windup.
	boss.step_special(Vector2.ZERO, 0.1)
	var first_step_telegraphs := boss.is_telegraphing()

	# 0.1 + 0.7 = 0.8 s of a 0.85 s windup: nothing lands yet. The first step
	# only opened the windup, it does not spend any of it.
	for _step in 7:
		boss.step_special(Vector2.ZERO, 0.1)
	var strikes_before_the_end: int = strikes[0]
	var progress := boss.windup_progress()

	# Two more tenths cross 0.85 s: exactly one strike, then the boss is free.
	boss.step_special(Vector2.ZERO, 0.1)
	var strikes_just_before_the_end: int = strikes[0]
	boss.step_special(Vector2.ZERO, 0.1)
	var strikes_at_impact: int = strikes[0]
	var impact_damage: float = last_damage[0]
	var rooted_after_impact := boss.is_telegraphing()

	# Cooldown is 4.5 s: it must not strike again inside it.
	for _step in 40:
		boss.step_special(Vector2.ZERO, 0.1)
	var strikes_during_cooldown: int = strikes[0]

	# Past the cooldown it winds up again, so the signal repeats.
	for _step in 10:
		boss.step_special(Vector2.ZERO, 0.1)
	var telegraphs_after_cooldown := boss.is_telegraphing()
	for _step in 9:
		boss.step_special(Vector2.ZERO, 0.1)
	var strikes_after_second_windup: int = strikes[0]

	# Assert
	assert_int(1 if first_step_telegraphs else 0) \
		.override_failure_message("windup starts in range").is_equal(1)
	assert_int(strikes_before_the_end) \
		.override_failure_message("no strike before the telegraph ends").is_equal(0)
	assert_int(1 if progress > 0.8 and progress < 1.0 else 0) \
		.override_failure_message("windup progress is partway").is_equal(1)
	assert_int(strikes_just_before_the_end) \
		.override_failure_message("still no strike just before the end").is_equal(0)
	assert_int(strikes_at_impact).override_failure_message("exactly one strike").is_equal(1)
	assert_float(impact_damage) \
		.override_failure_message("strike carries the scaled damage").is_equal_approx(22.0, TOLERANCE)
	assert_int(1 if rooted_after_impact else 0) \
		.override_failure_message("boss is no longer rooted").is_equal(0)
	assert_int(strikes_during_cooldown) \
		.override_failure_message("cooldown blocks a second strike").is_equal(1)
	assert_int(1 if telegraphs_after_cooldown else 0) \
		.override_failure_message("windup restarts after the cooldown").is_equal(1)
	assert_int(strikes_after_second_windup) \
		.override_failure_message("second strike lands").is_equal(2)


func test_range_gate_ignores_targets_beyond_slam_radius() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	auto_free(boss)
	boss.position = Vector2.ZERO

	# Act
	# 200 px away, outside the 96 px slam radius.
	boss.step_special(Vector2(200.0, 0.0), 5.0)

	# Assert
	assert_int(1 if boss.is_telegraphing() else 0) \
		.override_failure_message("no windup outside slam range").is_equal(0)


func test_knockback_resistance_cuts_boss_push() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	auto_free(boss)
	boss.position = Vector2(100.0, 0.0)
	var plain := Enemy.create(load(SQUELETTE_PATH) as EnemyData)
	auto_free(plain)
	plain.position = Vector2(100.0, 0.0)

	# Act
	boss.apply_knockback(Vector2.ZERO, 100.0)
	plain.apply_knockback(Vector2.ZERO, 100.0)

	# Assert
	assert_float(boss.position.x) \
		.override_failure_message("boss resists 85% of a knockback").is_equal_approx(115.0, TOLERANCE)
	assert_float(plain.position.x) \
		.override_failure_message("plain enemy takes the full knockback") \
		.is_equal_approx(200.0, TOLERANCE)


func test_spawner_pick_never_returns_the_boss() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var spawner := Spawner.new()
	auto_free(spawner)
	var pool: Array[EnemyData] = [
		load(BOSS_PATH) as EnemyData,
		load(SQUELETTE_PATH) as EnemyData,
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	# Act
	var elite_picks := 0
	for _roll in 300:
		var picked := spawner.pick_enemy(20, pool, rng)
		if picked != null and picked.is_elite:
			elite_picks += 1

	# Assert
	assert_int(elite_picks).override_failure_message("the horde never picks the boss").is_equal(0)


func test_finish_line_parks_the_run_on_the_last_wave() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	var data := load(WAVE_PATH) as WaveData
	var director := WaveDirector.new()
	director.setup(data)

	# Act
	var wave_0_is_final := director.is_final_wave(0)
	var last_wave_is_final := director.is_final_wave(data.total_waves - 1)
	var fresh_run_finished := director.has_finished()

	# Run the clock just past the end of the last wave.
	director.wave_index = data.total_waves - 1
	director.time_in_wave = data.duration - 0.01
	director.tick(0.02)
	var finished_after_last_wave := director.has_finished()
	var parked_wave_index := director.wave_index
	var parked_time_left := director.time_left()

	# Zero disables the finish line, which is how a prototype keeps running.
	var endless := WaveData.new()
	endless.total_waves = 0
	director.setup(endless)
	director.wave_index = 50
	director.time_in_wave = endless.duration - 0.01
	director.tick(0.02)
	var endless_finished := director.has_finished()
	var endless_wave_index := director.wave_index

	# Assert
	assert_int(1 if wave_0_is_final else 0) \
		.override_failure_message("wave 0 is not the last wave").is_equal(0)
	assert_int(1 if last_wave_is_final else 0) \
		.override_failure_message("the last wave is final").is_equal(1)
	assert_int(1 if fresh_run_finished else 0) \
		.override_failure_message("a fresh run has not finished").is_equal(0)
	assert_int(1 if finished_after_last_wave else 0) \
		.override_failure_message("the last wave finishes the run").is_equal(1)
	assert_int(parked_wave_index) \
		.override_failure_message("the wave index does not roll past the last") \
		.is_equal(data.total_waves - 1)
	assert_float(parked_time_left) \
		.override_failure_message("the clock parks at zero seconds left") \
		.is_equal_approx(0.0, TOLERANCE)
	assert_int(1 if endless_finished else 0) \
		.override_failure_message("an endless run never finishes").is_equal(0)
	assert_int(endless_wave_index) \
		.override_failure_message("an endless run advances past any wave").is_equal(51)


func test_equipment_draw_never_offers_two_items_for_one_slot() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	# Two helmets, one chest piece and one pair of boots. Every draw of three
	# must hold at most one helmet: wearing both is impossible.
	var items: Array[EquipmentData] = [
		_make_item("casque", "max_hp", 10.0),
		_make_item("casque", "max_hp", 20.0),
		_make_item("plastron", "damage", 0.1),
		_make_item("bottes", "move_speed", 0.1),
	]
	var pool: Array[Offer] = []
	for item in items:
		var offer := Offer.for_equipment(item)
		offer.weight = 1.0
		pool.append(offer)

	# Act
	var worst := 0
	for _draw in 200:
		var picked: Array[Offer] = main._pick_weighted(pool, 3)
		var helmets := 0
		for offer in picked:
			if offer.kind == "equipment" and offer.equipment != null:
				if offer.equipment.slot == "casque":
					helmets += 1
		worst = maxi(worst, helmets)

	# Assert
	assert_int(worst).override_failure_message("never two pieces for the same slot").is_equal(1)


func test_weapon_offers_capped_by_free_slots() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())

	# Act
	# The run starts with one weapon. Adding a second leaves exactly one slot,
	# so no panel may offer two weapons any more.
	main._gain_weapon(load(DAGUE_PATH) as WeaponData)
	var free_after_one: int = main._inventory.free_weapon_slots()

	var worst := 0
	for _draw in 80:
		var picked: Array[Offer] = main._build_offers(3)
		var weapons := 0
		for offer in picked:
			if offer.kind == "weapon":
				weapons += 1
		worst = maxi(worst, weapons)

	# With every slot taken, no weapon is offered at all.
	main._gain_weapon(load(MARTEAU_PATH) as WeaponData)
	var free_after_two: int = main._inventory.free_weapon_slots()
	var offered_weapon := 0
	for _draw in 80:
		var picked: Array[Offer] = main._build_offers(3)
		for offer in picked:
			if offer.kind == "weapon":
				offered_weapon += 1

	# Assert
	assert_int(free_after_one).override_failure_message("one weapon slot left").is_equal(1)
	assert_int(1 if worst <= 1 else 0) \
		.override_failure_message("weapon offers capped by free slots").is_equal(1)
	assert_int(free_after_two).override_failure_message("no free weapon slot").is_equal(0)
	assert_int(offered_weapon).override_failure_message("a full loadout offers no weapon").is_equal(0)


## Builds a piece of equipment for the slot-rules pool.
func _make_item(slot: String, stat: String, amount: float) -> EquipmentData:
	var item := EquipmentData.new()
	item.slot = slot
	item.stat = stat
	item.amount = amount
	item.display_name = slot
	return item
