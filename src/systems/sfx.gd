## Plays the slice's sound effects from a fixed pool of players on a "SFX" bus.
##
## The bus is created on demand in [method _ready], with a limiter so stacked
## hits cannot clip. All twelve [AudioStreamPlayer]s are built once at startup
## and reused for every play; nothing is instantiated during gameplay.
## The six streams are loaded from [code]res://assets/audio/sfx/[/code] and
## stay silent when a file is missing, so the game still runs without audio.
class_name Sfx
extends Node

## Number of pooled players created at startup. Never grown at runtime.
const POOL_SIZE := 12
## Minimum milliseconds between two plays of the same sound id, per id.
const MIN_INTERVAL_MS := 45
## Maximum random pitch spread of a play, as a ratio around 1.0.
const PITCH_JITTER := 0.08
## Audio bus every pooled player is routed to.
const BUS_NAME := "SFX"

## Sound id -> WAV path. The ids are the public vocabulary of [method play].
const _SOUND_PATHS := {
	"hit_light": "res://assets/audio/sfx/hit_light.wav",
	"hit_heavy": "res://assets/audio/sfx/hit_heavy.wav",
	"hit_crit": "res://assets/audio/sfx/hit_crit.wav",
	"enemy_death": "res://assets/audio/sfx/enemy_death.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
	"boss_roar": "res://assets/audio/sfx/boss_roar.wav",
	"boss_slam": "res://assets/audio/sfx/boss_slam.wav",
}

## Sound id -> loaded stream. A missing file stores null and stays silent.
var _streams: Dictionary = {}
## Pooled players, all children of this node, bus = BUS_NAME.
var _players: Array[AudioStreamPlayer] = []
## Random source for the per-play pitch jitter.
var _rng := RandomNumberGenerator.new()
## Sound id -> last Time.get_ticks_msec() at which it played.
var _last_played: Dictionary = {}
## True while the bus is muted through [method set_muted].
var _muted: bool = false


## Creates the SFX bus, loads every stream, builds the player pool, and starts
## muted on a headless run so a server build makes no audio calls.
func _ready() -> void:
	_rng.randomize()
	_ensure_bus()
	for id in _SOUND_PATHS:
		var path: String = _SOUND_PATHS[id]
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			push_warning("Sfx: missing stream for '%s' at %s" % [id, path])
		_streams[id] = stream
	for _index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAME
		add_child(player)
		_players.append(player)
	# The headless display server has no audio device worth feeding.
	if DisplayServer.get_name() == "headless":
		set_muted(true)


## Plays one sound id, with an optional volume offset in dB.
##
## Unknown ids, missing streams and a muted bus are ignored. Two plays of the
## same id closer than [constant MIN_INTERVAL_MS] are dropped, and a play with
## every pooled player busy is dropped too.
func play(id: String, volume_db: float = 0.0) -> void:
	if _muted:
		return
	var stream: AudioStream = _streams.get(id, null)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var last: int = int(_last_played.get(id, -MIN_INTERVAL_MS - 1))
	if now - last < MIN_INTERVAL_MS:
		return
	for player in _players:
		if player.playing:
			continue
		_last_played[id] = now
		player.stream = stream
		player.pitch_scale = 1.0 + _rng.randf_range(-PITCH_JITTER, PITCH_JITTER)
		player.volume_db = volume_db
		player.play()
		return


## Mutes or unmutes the SFX bus. Muting also stops every pooled player, so a
## sound already in flight goes quiet immediately.
func set_muted(muted: bool) -> void:
	_muted = muted
	var bus := AudioServer.get_bus_index(BUS_NAME)
	if bus != -1:
		AudioServer.set_bus_mute(bus, muted)
	if not muted:
		return
	for player in _players:
		player.stop()


## Flips the mute state and returns the new one.
func toggle_muted() -> bool:
	set_muted(not _muted)
	return _muted


## Creates the "SFX" bus with a limiter when the project does not define it.
func _ensure_bus() -> void:
	var bus := AudioServer.get_bus_index(BUS_NAME)
	if bus != -1:
		return
	AudioServer.add_bus()
	bus = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus, BUS_NAME)
	AudioServer.set_bus_send(bus, "Master")
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(bus, limiter)
