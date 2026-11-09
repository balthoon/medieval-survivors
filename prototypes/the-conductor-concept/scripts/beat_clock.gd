# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09

class_name ProtoBeatClock extends Node

const BPM := 100.0
const BEATS_PER_BAR := 4
const BARS_PER_LOOP := 2

signal beat(beat_index: int)

var song_time: float = 0.0
var beat_index: int = -1

var _music: AudioStreamPlayer
var _last_t: float = -1.0e12


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://audio/beat_loop.wav") as AudioStreamWAV
	# The loop is baked into the WAV (smpl chunk). If the importer ignored it,
	# enable looping on the stream resource -- never on the player.
	if stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		# Derive the frame count from the stream length, not data.size(): the
		# imported WAV is QOA-compressed, so data.size() is bytes, not frames.
		stream.loop_end = int(stream.get_length() * stream.mix_rate) - 1
	_music.stream = stream
	_music.bus = &"Master"
	add_child(_music)
	# Headless uses the dummy audio driver: nothing is audible, and a playback
	# still active when the tree quits is reported as a leaked ObjectDB instance.
	# Real runs keep the music.
	if DisplayServer.get_name() != "headless":
		_music.play()


func _process(_delta: float) -> void:
	if not _music.playing:
		return
	var t := _music.get_playback_position() + AudioServer.get_time_since_last_mix()
	t -= AudioServer.get_output_latency()
	if t < 0.0:
		t = 0.0  # latency compensation can land the first frames before zero
	if t < _last_t:
		t += _music.stream.get_length()  # loop wrapped
	_last_t = t
	song_time = t
	var b := int(song_time / beat_interval())
	if b != beat_index:
		beat_index = b
		beat.emit(beat_index)


## Position through the current beat, 0.0 .. 1.0.
func phase() -> float:
	return fmod(song_time, beat_interval()) / beat_interval()


## True when the song is within +/- window seconds of a beat.
func is_on_beat(window: float) -> bool:
	var d := phase()
	return min(d, 1.0 - d) * beat_interval() <= window


## Seconds per beat at the loop's tempo.
func beat_interval() -> float:
	return 60.0 / BPM
