## Integration tests for the boss fight of slice 0.4: the boss wave, the boss
## slam and the boss loot panel.
##
## Ported from the live-combat checks of tools/verify_slice04.gd
## (_check_boss_wave_spawn, _check_slam_damage, _check_boss_loot). Each test
## instantiates the real main scene, silences the wave spawner and drives the
## boss by hand, so nothing from a previous test or a live wave can race the
## assertions. Every test sets up its own scene: gdUnit4 may run them in any
## order.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

## Wave index of the first boss wave. Must stay in step with
## WaveData.boss_every_waves.
const FIRST_BOSS_WAVE := 4
const BOSS_EVERY := 5


## The first boss wave spawns exactly one tier-0 boss, registered with the enemy
## manager and shown on the boss bar, and a second boss wave does not stack a
## second boss on top of it.
func test_boss_wave_spawns_one_tier_zero_boss() -> void:
	# Arrange -- a real run with the wave spawner silenced and a clean enemy
	# field, so the only boss on stage is the one this test spawns.
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())
	var hud := main.get_node("HUD") as HUD

	# Act -- start the first boss wave by hand.
	main._on_wave_started(FIRST_BOSS_WAVE)
	var boss: Enemy = main._boss

	# Assert
	assert_object(boss).override_failure_message("boss wave spawned a boss").is_not_null()
	if boss == null:
		return
	var boss_bar := hud.get_node("BossBar") as Control
	var boss_name := hud.get_node("BossBar/BossName") as Label
	var boss_fill := hud.get_node("BossBar/BossBarFill") as ColorRect

	assert_float(boss.max_hp).override_failure_message("tier-0 boss hp").is_equal_approx(
		480.0, 0.001
	)
	assert_bool(manager.enemies.has(boss)).override_failure_message(
		"boss is in the manager"
	).is_true()
	assert_bool(boss_bar.visible).override_failure_message("boss bar is visible").is_true()
	assert_str(boss_name.text).override_failure_message(
		"boss bar shows the boss name"
	).is_equal("SEIGNEUR SQUELETTE")

	# Half health halves the strip: 560 px wide.
	hud.update_boss(240.0, 480.0)
	assert_float(boss_fill.size.x).override_failure_message(
		"boss bar halves at half health"
	).is_equal_approx(280.0, 0.001)

	# Act -- a second boss wave while the first boss still lives.
	main._on_wave_started(FIRST_BOSS_WAVE + BOSS_EVERY)

	# Assert -- the living boss is reused, never duplicated.
	assert_object(main._boss).override_failure_message("no duplicate boss spawned").is_same(boss)


## The boss slam hurts the player inside its disc and leaves them untouched
## outside it: the slam is the boss's only reach.
func test_boss_slam_damages_only_inside_its_radius() -> void:
	# Arrange -- a real run with the wave spawner silenced, at full health and
	# vulnerable.
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var player := main.get_node("Player") as Player
	player.heal(1000.0)
	player.invulnerable_time = 0.0
	var before := player.hp

	# Act -- a slam landing 500 px away, well outside the 96 px radius, then one
	# landing on the player.
	main._on_boss_slam(player.position + Vector2(500.0, 0.0), 96.0, 22.0)
	var hp_after_miss := player.hp
	player.invulnerable_time = 0.0
	main._on_boss_slam(player.position, 96.0, 22.0)

	# Assert
	assert_float(hp_after_miss).override_failure_message(
		"slam misses outside its radius"
	).is_equal_approx(before, 0.001)
	assert_float(player.hp).override_failure_message(
		"slam damages the player inside its radius"
	).is_equal_approx(before - 22.0, 0.001)


## A boss death clears the boss, hides its bar and opens the three-choice boss
## loot panel, which answering closes and returns to the run.
func test_boss_kill_opens_boss_loot_panel() -> void:
	# Arrange -- a real run with the wave spawner silenced, holding the boss of
	# the first boss wave. The boss is spawned here rather than reused from
	# another test: each test owns its scene.
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)
	MainSceneFixture.silence_waves(main)
	var manager := main.get_node("EnemyManager") as EnemyManager
	manager.remove_dead(Callable())
	main._on_wave_started(FIRST_BOSS_WAVE)
	var boss: Enemy = main._boss
	assert_object(boss).override_failure_message("boss spawned for the kill").is_not_null()
	if boss == null:
		return
	var hud := main.get_node("HUD") as HUD
	var boss_bar := hud.get_node("BossBar") as Control
	var panel := hud.get_node("UpgradePanel") as Control
	var title := hud.get_node("UpgradePanel/Title") as Label

	# Act -- kill the boss by hand and collect; the kill and the loot panel land
	# on the same call.
	boss.hp = 0.0
	main._collect_pickups(0.0)

	# Assert -- the death is consumed and the loot panel owns the run.
	assert_object(main._boss).override_failure_message("boss reference cleared on death").is_null()
	assert_bool(boss_bar.visible).override_failure_message("boss bar hidden on death").is_false()
	assert_bool(main.is_paused).override_failure_message("loot panel opened").is_true()
	assert_int(main._pending_choices.size()).override_failure_message(
		"loot panel has three choices"
	).is_equal(3)
	assert_bool(main._boss_loot_open).override_failure_message(
		"loot panel is flagged as boss loot"
	).is_true()
	assert_str(title.text).override_failure_message("loot panel title").is_equal("Butin du boss")
	assert_bool(panel.visible).override_failure_message("loot panel is visible").is_true()

	# Act -- answer the panel's first choice.
	main._on_upgrade_chosen(0)

	# Assert -- the panel closed and the run resumed.
	assert_bool(panel.visible).override_failure_message("loot panel closed").is_false()
	assert_bool(main._boss_loot_open).override_failure_message("boss loot flag cleared").is_false()
