## Throwaway verification for slice 0.4: the boss wave, the boss itself and its
## loot. Loads the real main scene, freezes the run, then drives the wave
## director, an enemy built from the boss resource, and a full boss kill by hand.
## Prints PASS/FAIL lines and exits non-zero on any failure.
##
##   godot --path . --script res://tools/verify_slice04.gd
extends SceneTree

const BOSS_PATH := "res://data/enemies/seigneur_squelette.tres"
const SQUELETTE_PATH := "res://data/enemies/squelette.tres"
const WAVE_PATH := "res://data/waves/base_wave.tres"

## Wave index of the first boss wave. Must stay in step with
## WaveData.boss_every_waves.
const FIRST_BOSS_WAVE := 4
const BOSS_EVERY := 5

var _frame := 0
var _failures := 0
var _main: Node = null
var _player: Player = null
var _manager: EnemyManager = null


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("verify: could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	_player = _main.get_node_or_null("Player") as Player
	_manager = _main.get_node_or_null("EnemyManager") as EnemyManager
	if _player == null or _manager == null:
		print("FAIL: could not find Player / EnemyManager")
		quit(1)
		return true

	# Freeze the run: every check below is driven by hand, so nothing may race it.
	_main.is_paused = true
	_main._enemy_pool.clear()
	_manager.remove_dead(Callable())

	_check_wiring()
	_check_boss_cadence()
	_check_boss_scaling()
	_check_telegraph_timing()
	_check_range_gate()
	_check_knockback_resistance()
	_check_spawner_ignores_boss()
	_check_no_duplicate_slots()
	_check_boss_wave_spawn()
	_check_slam_damage()
	_check_boss_loot()
	_check_weapon_offer_cap()

	print("verify: failures=%d" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _check_wiring() -> void:
	_expect("boss resource loaded", 1 if _main._boss_data != null else 0, 1)
	_expect("boss is flagged elite", 1 if _main._boss_data != null and _main._boss_data.is_elite else 0, 1)
	_expect(
		"boss_roar stream loaded",
		1 if _main._sfx != null and _main._sfx._streams.get("boss_roar", null) != null else 0,
		1,
	)
	_expect(
		"boss_slam stream loaded",
		1 if _main._sfx != null and _main._sfx._streams.get("boss_slam", null) != null else 0,
		1,
	)


func _check_boss_cadence() -> void:
	var director := WaveDirector.new()
	director.setup(load(WAVE_PATH) as WaveData)

	_expect("wave 0 is not a boss wave", 1 if director.is_boss_wave(0) else 0, 0)
	_expect("wave 3 is not a boss wave", 1 if director.is_boss_wave(3) else 0, 0)
	_expect("wave 4 is a boss wave", 1 if director.is_boss_wave(FIRST_BOSS_WAVE) else 0, 1)
	_expect("wave 5 is not a boss wave", 1 if director.is_boss_wave(5) else 0, 0)
	_expect("wave 9 is a boss wave", 1 if director.is_boss_wave(9) else 0, 1)
	_expect("wave 14 is a boss wave", 1 if director.is_boss_wave(14) else 0, 1)
	_expect("negative wave is not a boss wave", 1 if director.is_boss_wave(-3) else 0, 0)

	_expect("first boss tier", director.boss_tier(FIRST_BOSS_WAVE), 0)
	_expect("second boss tier", director.boss_tier(9), 1)
	_expect("third boss tier", director.boss_tier(14), 2)
	_expect("no tier off a boss wave", director.boss_tier(3), -1)

	# The horde must thin out during a boss wave. The interval at wave 4 is the
	# cooled-down cadence for that wave, stretched by the boss scale.
	var wave_data := load(WAVE_PATH) as WaveData
	director.wave_index = FIRST_BOSS_WAVE
	var expected_boss_interval := (
		wave_data.base_spawn_interval
		* pow(wave_data.interval_decay_per_wave, float(FIRST_BOSS_WAVE))
		* wave_data.boss_spawn_interval_scale
	)
	_expect_float(
		"boss wave stretches the spawn interval",
		director.spawn_interval(),
		expected_boss_interval,
	)

	# Zero disables bosses entirely, which is how a prototype turns them off.
	var no_boss := WaveData.new()
	no_boss.boss_every_waves = 0
	director.setup(no_boss)
	_expect("boss_every_waves=0 disables bosses", 1 if director.is_boss_wave(9) else 0, 0)


func _check_boss_scaling() -> void:
	var boss_data := load(BOSS_PATH) as EnemyData
	var boss := Enemy.create(boss_data, 1.0, 1.0)
	_expect_float("tier 0 keeps the authored hp", boss.max_hp, 480.0)
	_expect_float("tier 0 keeps the authored contact damage", boss.contact_damage, 16.0)
	_expect_float("tier 0 keeps the authored slam damage", boss.slam_damage, 22.0)
	_expect_float("slam radius is not scaled", boss.slam_radius, 96.0)
	_expect_float("boss spawns at full hp", boss.hp, 480.0)
	boss.free()

	var scaled := Enemy.create(boss_data, 1.9, 1.35)
	_expect_float("tier 1 scales hp", scaled.max_hp, 912.0)
	_expect_float("tier 1 scales contact damage", scaled.contact_damage, 21.6)
	_expect_float("tier 1 scales slam damage", scaled.slam_damage, 29.7)
	scaled.free()

	var plain := Enemy.create(load(SQUELETTE_PATH) as EnemyData)
	_expect_float("plain enemy max hp is its own", plain.max_hp, 20.0)
	_expect_float("plain enemy has no slam", plain.slam_damage, 0.0)
	_expect("plain enemy does not telegraph", 1 if plain.is_telegraphing() else 0, 0)
	plain.free()


func _check_telegraph_timing() -> void:
	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	boss.position = Vector2.ZERO
	var strikes := [0]
	var last_damage := [0.0]
	boss.slam_struck.connect(
		func(_at: Vector2, _radius: float, damage: float) -> void:
			strikes[0] += 1
			last_damage[0] = damage
	)

	# The boss starts inside range, so the first step opens the windup.
	boss.step_special(Vector2.ZERO, 0.1)
	_expect("windup starts in range", 1 if boss.is_telegraphing() else 0, 1)

	# 0.1 + 0.7 = 0.8 s of a 0.85 s windup: nothing lands yet. The first step only
	# opened the windup, it does not spend any of it.
	for _step in 7:
		boss.step_special(Vector2.ZERO, 0.1)
	_expect("no strike before the telegraph ends", strikes[0], 0)
	var progress := boss.windup_progress()
	_expect("windup progress is partway", 1 if progress > 0.8 and progress < 1.0 else 0, 1)

	# Two more tenths cross 0.85 s: exactly one strike, then the boss is free.
	boss.step_special(Vector2.ZERO, 0.1)
	_expect("still no strike just before the end", strikes[0], 0)
	boss.step_special(Vector2.ZERO, 0.1)
	_expect("exactly one strike", strikes[0], 1)
	_expect_float("strike carries the scaled damage", last_damage[0], 22.0)
	_expect("boss is no longer rooted", 1 if boss.is_telegraphing() else 0, 0)

	# Cooldown is 4.5 s: it must not strike again inside it.
	for _step in 40:
		boss.step_special(Vector2.ZERO, 0.1)
	_expect("cooldown blocks a second strike", strikes[0], 1)

	# Past the cooldown it winds up again, so the signal repeats.
	for _step in 10:
		boss.step_special(Vector2.ZERO, 0.1)
	_expect("windup restarts after the cooldown", 1 if boss.is_telegraphing() else 0, 1)
	for _step in 9:
		boss.step_special(Vector2.ZERO, 0.1)
	_expect("second strike lands", strikes[0], 2)
	boss.free()


func _check_range_gate() -> void:
	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	boss.position = Vector2.ZERO
	# 200 px away, outside the 96 px slam radius.
	boss.step_special(Vector2(200.0, 0.0), 5.0)
	_expect("no windup outside slam range", 1 if boss.is_telegraphing() else 0, 0)
	boss.free()


func _check_knockback_resistance() -> void:
	var boss := Enemy.create(load(BOSS_PATH) as EnemyData)
	boss.position = Vector2(100.0, 0.0)
	boss.apply_knockback(Vector2.ZERO, 100.0)
	_expect_float("boss resists 85% of a knockback", boss.position.x, 115.0)
	boss.free()

	var plain := Enemy.create(load(SQUELETTE_PATH) as EnemyData)
	plain.position = Vector2(100.0, 0.0)
	plain.apply_knockback(Vector2.ZERO, 100.0)
	_expect_float("plain enemy takes the full knockback", plain.position.x, 200.0)
	plain.free()


func _check_spawner_ignores_boss() -> void:
	var spawner := Spawner.new()
	var pool: Array[EnemyData] = [
		load(BOSS_PATH) as EnemyData,
		load(SQUELETTE_PATH) as EnemyData,
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var elite_picks := 0
	for _roll in 300:
		var picked := spawner.pick_enemy(20, pool, rng)
		if picked != null and picked.is_elite:
			elite_picks += 1
	_expect("the horde never picks the boss", elite_picks, 0)
	spawner.free()


func _check_no_duplicate_slots() -> void:
	# Two helmets, one chest piece and one pair of boots. Every draw of three
	# must hold at most one helmet: wearing both is impossible.
	var pool: Array[Offer] = []
	for item in [
		_make_item("casque", "max_hp", 10.0),
		_make_item("casque", "max_hp", 20.0),
		_make_item("plastron", "damage", 0.1),
		_make_item("bottes", "move_speed", 0.1),
	]:
		var offer := Offer.for_equipment(item)
		offer.weight = 1.0
		pool.append(offer)

	var worst := 0
	for _draw in 200:
		var picked: Array[Offer] = _main._pick_weighted(pool, 3)
		var helmets := 0
		for offer in picked:
			if offer.kind == "equipment" and offer.equipment != null:
				if offer.equipment.slot == "casque":
					helmets += 1
		worst = maxi(worst, helmets)
	_expect("never two pieces for the same slot", worst, 1)


func _make_item(slot: String, stat: String, amount: float) -> EquipmentData:
	var item := EquipmentData.new()
	item.slot = slot
	item.stat = stat
	item.amount = amount
	item.display_name = slot
	return item


func _check_boss_wave_spawn() -> void:
	_main._on_wave_started(FIRST_BOSS_WAVE)
	_expect("boss wave spawned a boss", 1 if _main._boss != null else 0, 1)
	if _main._boss == null:
		return
	_expect_float("tier-0 boss hp", _main._boss.max_hp, 480.0)
	_expect("boss is in the manager", 1 if _manager.enemies.has(_main._boss) else 0, 1)
	_expect(
		"boss bar is visible",
		1 if _main._hud.get_node("BossBar").visible else 0,
		1,
	)
	_expect(
		"boss bar shows the boss name",
		1 if _main._hud.get_node("BossBar/BossName").text == "SEIGNEUR SQUELETTE" else 0,
		1,
	)

	# Half health halves the strip: 560 px wide.
	_main._hud.update_boss(240.0, 480.0)
	_expect_float(
		"boss bar halves at half health",
		_main._hud.get_node("BossBar/BossBarFill").size.x,
		280.0,
	)

	# A second boss wave while it lives must not spawn a second boss.
	var first: Enemy = _main._boss
	_main._on_wave_started(FIRST_BOSS_WAVE + BOSS_EVERY)
	_expect("no duplicate boss spawned", 1 if _main._boss == first else 0, 1)


func _check_slam_damage() -> void:
	# The slam is the boss's only reach: it must hurt inside the disc and leave
	# the player alone outside it.
	_player.heal(1000.0)
	_player.invulnerable_time = 0.0
	var before := _player.hp
	_main._on_boss_slam(_player.position + Vector2(500.0, 0.0), 96.0, 22.0)
	_expect_float("slam misses outside its radius", _player.hp, before)

	_player.invulnerable_time = 0.0
	_main._on_boss_slam(_player.position, 96.0, 22.0)
	_expect_float("slam damages the player inside its radius", _player.hp, before - 22.0)


func _check_boss_loot() -> void:
	if _main._boss == null:
		print("FAIL: no boss to kill")
		_failures += 1
		return

	_main._boss.hp = 0.0
	_main._collect_pickups(0.0)

	_expect("boss reference cleared on death", 1 if _main._boss == null else 0, 1)
	_expect(
		"boss bar hidden on death",
		1 if not _main._hud.get_node("BossBar").visible else 0,
		1,
	)
	_expect("loot panel opened", 1 if _main.is_paused else 0, 1)
	_expect("loot panel has three choices", _main._pending_choices.size(), 3)
	_expect("loot panel is flagged as boss loot", 1 if _main._boss_loot_open else 0, 1)
	_expect(
		"loot panel title",
		1 if _main._hud.get_node("UpgradePanel/Title").text == "Butin du boss" else 0,
		1,
	)
	_expect(
		"loot panel is visible",
		1 if _main._hud.get_node("UpgradePanel").visible else 0,
		1,
	)

	# Answering the panel must close it and return to the run.
	_main._on_upgrade_chosen(0)
	_expect("loot panel closed", 1 if _main._hud.get_node("UpgradePanel").visible else 0, 0)
	_expect("boss loot flag cleared", 1 if _main._boss_loot_open else 0, 0)


func _check_weapon_offer_cap() -> void:
	# The run starts with one weapon. Adding a second leaves exactly one slot,
	# so no panel may offer two weapons any more.
	_main._gain_weapon(load("res://data/weapons/dague.tres"))
	_expect("one weapon slot left", _main._inventory.free_weapon_slots(), 1)

	var worst := 0
	for _draw in 80:
		var picked: Array[Offer] = _main._build_offers(3)
		var weapons := 0
		for offer in picked:
			if offer.kind == "weapon":
				weapons += 1
		worst = maxi(worst, weapons)
	_expect("weapon offers capped by free slots", 1 if worst <= 1 else 0, 1)

	# With every slot taken, no weapon is offered at all.
	_main._gain_weapon(load("res://data/weapons/marteau.tres"))
	_expect("no free weapon slot", _main._inventory.free_weapon_slots(), 0)
	var offered_weapon := 0
	for _draw in 80:
		for offer in _main._build_offers(3):
			if offer.kind == "weapon":
				offered_weapon += 1
	_expect("a full loadout offers no weapon", offered_weapon, 0)


func _expect(label: String, actual: int, expected: int) -> void:
	if actual == expected:
		print("PASS: %s (%d)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s - got %d, expected %d" % [label, actual, expected])


func _expect_float(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) <= 0.001:
		print("PASS: %s (%.3f)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s - got %.3f, expected %.3f" % [label, actual, expected])


func _expect_text(label: String, actual: String, expected: String) -> void:
	if actual == expected:
		print("PASS: %s (%s)" % [label, actual])
		return
	_failures += 1
	print("FAIL: %s - got '%s', expected '%s'" % [label, actual, expected])
