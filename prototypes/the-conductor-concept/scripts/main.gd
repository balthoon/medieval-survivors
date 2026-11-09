# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09
#
# Wiring only: reads input, calls the player/spawner/clock, owns Crescendo and
# the death check. No spell logic, no progression, no menus.

extends Node2D

const MAX_CRESCENDO := 10
const FORTE_DURATION := 3.0
const ON_BEAT_WINDOW := 0.110

@onready var player: ProtoPlayer = $Player
@onready var enemies_root: Node2D = $Enemies
@onready var spawner: ProtoSpawner = $Spawner
@onready var beat_clock: ProtoBeatClock = $BeatClock
@onready var hud: ProtoHUD = $HUD

## Seconds of survival. Drives the HUD timer and spawner density only.
var elapsed: float = 0.0
## Hits landed on the beat. Never reset by a miss - an off-beat cast is not a failure.
var crescendo: int = 0
## Remaining seconds of Forte; while > 0 every cast behaves as on-beat.
var forte_timer: float = 0.0
var dead: bool = false


func _ready() -> void:
	# flash_beat() takes no arguments, so adapt the beat index here.
	beat_clock.beat.connect(_on_beat)
	hud.show_alive()
	hud.update_state(crescendo, MAX_CRESCENDO, elapsed, false)
	hud.update_beat_phase(0.0)


func _on_beat(_beat_index: int) -> void:
	hud.flash_beat()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
		return
	if key.physical_keycode == KEY_SPACE:
		_try_cast()


func _process(delta: float) -> void:
	if dead:
		return

	elapsed += delta

	if forte_timer > 0.0:
		forte_timer -= delta
		if forte_timer <= 0.0:
			forte_timer = 0.0
			crescendo = 0

	player.move(_read_move_dir(), delta)

	_reap_dead()
	var enemies := _collect_enemies()
	for enemy in enemies:
		enemy.step_toward(player.global_position, delta)

	spawner.tick(elapsed, enemies_root, player.global_position)

	# Re-collect after spawning so newly spawned enemies are checked for contact.
	enemies = _collect_enemies()
	if _player_touches_enemy(enemies):
		_die()
		return

	hud.update_state(crescendo, MAX_CRESCENDO, elapsed, forte_timer > 0.0)
	hud.update_beat_phase(beat_clock.phase())


func _read_move_dir() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	return dir.normalized()


func _try_cast() -> void:
	if dead or not player.can_cast():
		return

	var forte_active := forte_timer > 0.0
	var on_beat := forte_active or beat_clock.is_on_beat(ON_BEAT_WINDOW)

	player.cast(on_beat, _collect_enemies())
	_reap_dead()

	if on_beat and not forte_active:
		crescendo = mini(crescendo + 1, MAX_CRESCENDO)
		if crescendo >= MAX_CRESCENDO:
			forte_timer = FORTE_DURATION

	hud.update_state(crescendo, MAX_CRESCENDO, elapsed, forte_timer > 0.0)


func _collect_enemies() -> Array[ProtoEnemy]:
	var out: Array[ProtoEnemy] = []
	for child in enemies_root.get_children():
		if child.is_queued_for_deletion():
			continue
		var enemy := child as ProtoEnemy
		if enemy != null:
			out.append(enemy)
	return out


func _reap_dead() -> void:
	for child in enemies_root.get_children():
		var enemy := child as ProtoEnemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if enemy.hp <= 0:
			enemy.queue_free()


func _player_touches_enemy(enemies: Array[ProtoEnemy]) -> bool:
	for enemy in enemies:
		var reach: float = enemy.RADIUS + ProtoPlayer.RADIUS
		if player.global_position.distance_to(enemy.global_position) <= reach:
			return true
	return false


func _die() -> void:
	dead = true
	hud.show_dead()
