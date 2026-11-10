## Integration tests for W2-E2: the ten weapon mechanics resolve in play.
##
## The two projectile formulas are pure math and are asserted through
## Projectile.mechanic_damage(). Everything else runs against the real main
## scene with a single weapon equipped, waves silenced and _process paused, so
## every step is driven by the test and no frame races the assertions.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

const DAGUE := "res://data/weapons/dague.tres"
const ARC := "res://data/weapons/arc_court.tres"
const ARBALETE := "res://data/weapons/arbalete.tres"
const BATON := "res://data/weapons/baton.tres"
const FAUX := "res://data/weapons/faux.tres"
const ORBE := "res://data/weapons/orbe.tres"
const ENCENSOIR := "res://data/weapons/encensoir.tres"
const LAME_VAMPIRE := "res://data/weapons/lame_vampire.tres"

const FLOAT_EPSILON := 0.001


func test_bow_bonus_scales_from_contact_to_full_range() -> void:
	# Arrange
	var weapon := load(ARC) as WeaponData
	assert_object(weapon).is_not_null()
	if weapon == null:
		return

	# Act — GDD F6: ×1.0 at contact, ×1.5 at full range, capped beyond it.
	var at_contact := Projectile.mechanic_damage(weapon, 10.0, 0.0, 320.0, 0)
	var at_half := Projectile.mechanic_damage(weapon, 10.0, 160.0, 320.0, 0)
	var beyond := Projectile.mechanic_damage(weapon, 10.0, 400.0, 320.0, 0)

	# Assert
	_assert_close("contact keeps the base hit", at_contact, 10.0)
	_assert_close("half range adds half the bonus", at_half, 12.5)
	_assert_close("beyond range is capped", beyond, 15.0)


func test_pierce_falloff_compounds_per_rank() -> void:
	# Arrange
	var weapon := load(ARBALETE) as WeaponData
	assert_object(weapon).is_not_null()
	if weapon == null:
		return

	# Act — GDD F8: the first living victim is rank 0, at full damage.
	var rank_0 := Projectile.mechanic_damage(weapon, 10.0, 0.0, 380.0, 0)
	var rank_1 := Projectile.mechanic_damage(weapon, 10.0, 0.0, 380.0, 1)
	var rank_2 := Projectile.mechanic_damage(weapon, 10.0, 0.0, 380.0, 2)

	# Assert
	_assert_close("first victim takes full damage", rank_0, 10.0)
	_assert_close("second victim takes 85 percent", rank_1, 8.5)
	_assert_close("third victim takes 85 percent squared", rank_2, 7.225)


func test_piercing_bolt_damages_two_aligned_enemies() -> void:
	# Arrange
	var stats := Stats.new()
	var rng := _seeded_rng()
	var container: Node2D = auto_free(Node2D.new())
	var manager: EnemyManager = auto_free(EnemyManager.new())
	var weapon := _test_weapon(&"pierce", 10.0)
	weapon.pierce_falloff = 0.5
	var first := manager.spawn(_dummy_enemy(100.0), Vector2(40.0, 0.0), container)
	var second := manager.spawn(_dummy_enemy(100.0), Vector2(80.0, 0.0), container)
	var bolt: Projectile = auto_free(Projectile.create(weapon, stats, rng, Vector2.ZERO, Vector2.RIGHT))

	# Act
	for _i in 10:
		if bolt.step(0.1, manager):
			break

	# Assert
	_assert_close("first victim takes the full hit", first.hp, 90.0)
	_assert_close("second victim takes the falloff hit", second.hp, 95.0)


func test_plain_bolt_stops_at_the_first_enemy() -> void:
	# Arrange
	var stats := Stats.new()
	var rng := _seeded_rng()
	var container: Node2D = auto_free(Node2D.new())
	var manager: EnemyManager = auto_free(EnemyManager.new())
	var weapon := _test_weapon(&"cleave", 10.0)
	var first := manager.spawn(_dummy_enemy(100.0), Vector2(40.0, 0.0), container)
	var second := manager.spawn(_dummy_enemy(100.0), Vector2(80.0, 0.0), container)
	var bolt: Projectile = auto_free(Projectile.create(weapon, stats, rng, Vector2.ZERO, Vector2.RIGHT))

	# Act
	for _i in 10:
		if bolt.step(0.1, manager):
			break

	# Assert
	_assert_close("first victim is hit", first.hp, 90.0)
	_assert_close("the bolt never reaches the second", second.hp, 100.0)


func test_execution_refunds_the_dagger_cooldown_on_a_kill() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, DAGUE)
	var player := main.get_node("Player") as Player
	var enemy := _spawn(main, player.position + Vector2(30.0, 0.0), 1.0)

	# Act — a normal cadence would leave 1/2.8 = 0.357 s on the timer.
	weapons.step(0.05)
	weapons.step(0.05)

	# Assert
	_assert_int("the dagger killed the target", 1 if enemy.hp <= 0.0 else 0, 1)
	assert_float(weapons.cooldown_seconds(0)).override_failure_message(
		"execution sets the cooldown near its 0.18 s floor"
	).is_less(0.2)


func test_chain_jumps_to_a_nearby_enemy() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, BATON)
	var player := main.get_node("Player") as Player
	var first := _spawn(main, player.position + Vector2(40.0, 0.0), 500.0)
	var second := _spawn(main, player.position + Vector2(120.0, 0.0), 500.0)

	# Act
	weapons.step(0.1)
	weapons.step(0.1)

	# Assert
	assert_float(first.hp).override_failure_message("the staff hits its target").is_less(500.0)
	assert_float(second.hp).override_failure_message(
		"the chain jumps to the enemy 80 px behind the target"
	).is_less(500.0)


func test_whirl_hits_enemies_behind_the_target() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, FAUX)
	var player := main.get_node("Player") as Player
	var front := _spawn(main, player.position + Vector2(40.0, 0.0), 500.0)
	var behind := _spawn(main, player.position + Vector2(-45.0, 0.0), 500.0)

	# Act — the aiming target is the front enemy; the scythe must still reach
	# the one standing on the opposite side.
	weapons.step(0.15)
	weapons.step(0.15)

	# Assert
	assert_float(front.hp).override_failure_message("the scythe hits the target").is_less(500.0)
	assert_float(behind.hp).override_failure_message(
		"the 360° sweep hits the enemy behind the player"
	).is_less(500.0)


func test_lifesteal_heals_part_of_the_damage_dealt() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, LAME_VAMPIRE)
	var player := main.get_node("Player") as Player
	player.hp = 50.0
	_spawn(main, player.position + Vector2(30.0, 0.0), 500.0)

	# Act
	weapons.step(0.1)
	weapons.step(0.1)

	# Assert
	assert_float(player.hp).override_failure_message(
		"the vampire blade returns 25 percent of the damage"
	).is_greater(50.0)


func test_lifesteal_does_not_heal_on_an_elite() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, LAME_VAMPIRE)
	var player := main.get_node("Player") as Player
	player.hp = 50.0
	_spawn(main, player.position + Vector2(30.0, 0.0), 500.0, true)

	# Act
	weapons.step(0.1)
	weapons.step(0.1)

	# Assert — edge case E5: an elite takes the damage but returns no health.
	_assert_close("an elite returns no health", player.hp, 50.0)


func test_orbit_hits_an_enemy_once_per_turn() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, ORBE)
	var player := main.get_node("Player") as Player
	_spawn(main, player.position + Vector2(46.0, 0.0), 500.0)
	var hits: Array[int] = [0]
	weapons.hit_landed.connect(
		func(_is_crit: bool, _amount: float, _at: Vector2) -> void: hits[0] += 1
	)

	# Act — one revolution lasts 2π / 2.4 ≈ 2.62 s.
	for _i in 30:
		weapons.step(0.05)
	var hits_after_one_turn := hits[0]
	for _i in 30:
		weapons.step(0.05)
	var hits_after_two_turns := hits[0]

	# Assert
	_assert_int("one contact in the first revolution", hits_after_one_turn, 1)
	_assert_int("one more contact in the second revolution", hits_after_two_turns, 2)


func test_fuse_detonates_after_the_fuse_and_damages_the_blast() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapons := _equip_only(main, ENCENSOIR)
	var player := main.get_node("Player") as Player
	var enemy := _spawn(main, player.position + Vector2(100.0, 0.0), 500.0)

	# Act — 100 px at 300 px/s, then 0.9 s of fuse.
	weapons.step(0.1)
	var thrown := weapons._censer_bombs.size()
	for _i in 40:
		weapons.step(0.1)

	# Assert
	_assert_int("the censer was thrown", thrown, 1)
	assert_float(enemy.hp).override_failure_message(
		"the blast damages the enemy standing in the radius"
	).is_less(500.0)


func test_hammer_stagger_interrupts_a_winding_enemy_but_not_an_elite() -> void:
	# Arrange
	var normal: Enemy = auto_free(_slammer(false))
	var elite: Enemy = auto_free(_slammer(true))
	normal.position = Vector2.ZERO
	elite.position = Vector2.ZERO
	normal.step_special(Vector2.ZERO, 0.01)
	elite.step_special(Vector2.ZERO, 0.01)
	assert_bool(normal.is_telegraphing()).override_failure_message(
		"the normal enemy is winding up"
	).is_true()
	assert_bool(elite.is_telegraphing()).override_failure_message(
		"the elite is winding up"
	).is_true()

	# Act
	var normal_delayed := normal.interrupt_windup(0.6)
	var elite_delayed := elite.interrupt_windup(0.6)

	# Assert — edge case E14: elites keep their preparation.
	assert_bool(normal_delayed).override_failure_message(
		"a normal windup is delayed"
	).is_true()
	assert_bool(elite_delayed).override_failure_message(
		"an elite is immune to the interruption"
	).is_false()


func test_weapon_offer_names_the_mechanic_before_the_numbers() -> void:
	# Arrange
	var main := await _open_main(self)
	if main == null:
		return
	var weapon := load(BATON) as WeaponData
	assert_object(weapon).is_not_null()
	if weapon == null:
		return
	var offer := Offer.for_weapon(weapon)

	# Act
	main._decorate_offer(offer)

	# Assert — AC8: the pitch naming the mechanic comes first.
	assert_bool(offer.description.begins_with(weapon.description)).override_failure_message(
		"the offer starts with the mechanic pitch — got '%s'" % offer.description
	).is_true()


## Instantiates the main scene, silences the waves, pauses _process and clears
## the field, so the caller drives every step itself.
func _open_main(suite: Node) -> Node:
	var main := MainSceneFixture.instantiate(suite)
	assert_object(main).is_not_null()
	if main == null:
		return null
	await MainSceneFixture.await_ready(suite)
	MainSceneFixture.silence_waves(main)
	main.is_paused = true
	var manager := main.get_node_or_null("EnemyManager") as EnemyManager
	if manager != null:
		manager.remove_dead(Callable())
	return main


## Replaces the starting sword with [param path] and clears every cooldown, so
## the weapon under test fires on the next step.
func _equip_only(main: Node, path: String) -> WeaponSystem:
	var weapon := load(path) as WeaponData
	main._inventory.weapons.clear()
	main._inventory.add_weapon(weapon)
	var weapons := main.get_node("WeaponSystem") as WeaponSystem
	weapons.refresh()
	for index in weapons._cooldowns.size():
		weapons._cooldowns[index] = 0.0
	return weapons


## Spawns one stationary, harmless dummy at [param at].
func _spawn(main: Node, at: Vector2, hp: float, elite: bool = false) -> Enemy:
	var data := _dummy_enemy(hp)
	data.is_elite = elite
	var manager := main.get_node("EnemyManager") as EnemyManager
	return manager.spawn(data, at, main.get_node("Enemies") as Node2D)


## A still, harmless, high-health archetype used as a damage sponge.
func _dummy_enemy(hp: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = int(hp)
	data.xp_value = 1
	data.radius = 13.0
	data.move_speed = 0.0
	data.contact_damage = 0.0
	data.color = Color(1.0, 0.0, 0.0)
	return data


## A boss-like enemy with a slam, optionally an elite.
func _slammer(elite: bool) -> Enemy:
	var data := EnemyData.new()
	data.max_hp = 100
	data.slam_damage = 10.0
	data.slam_radius = 100.0
	data.slam_telegraph = 0.85
	data.is_elite = elite
	return Enemy.create(data)


## A minimal weapon with no crit, so the assertions stay deterministic.
func _test_weapon(mechanic: StringName, damage: float) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = "test_%s" % mechanic
	weapon.mechanic = mechanic
	weapon.damage = damage
	weapon.attacks_per_second = 1.0
	weapon.range_px = 200.0
	weapon.crit_chance = 0.0
	weapon.crit_multiplier = 2.0
	weapon.knockback = 0.0
	weapon.projectile_speed = 1000.0
	return weapon


func _seeded_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	return rng


## Asserts float equality within the suite's tolerance.
func _assert_close(label: String, actual: float, expected: float) -> void:
	var delta := absf(actual - expected)
	assert_float(delta).override_failure_message(
		"%s — got %.3f, expected %.3f" % [label, actual, expected]
	).is_less_equal(FLOAT_EPSILON)


## Asserts integer equality, keeping the label in the failure message.
func _assert_int(label: String, actual: int, expected: int) -> void:
	assert_int(actual).override_failure_message(
		"%s — got %d, expected %d" % [label, actual, expected]
	).is_equal(expected)
