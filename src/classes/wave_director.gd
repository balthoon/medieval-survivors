## Drives the wave clock and spawn cadence.
##
## Pure logic: no node access, scene tree or global state. Callers connect to
## the signals and read the derived values, which makes the whole thing
## unit-testable with an injected [WaveData].
class_name WaveDirector
extends RefCounted

## Emitted when a wave begins (including wave 0 on the first tick).
signal wave_started(wave_index: int)
## Emitted when the current wave reaches its duration.
signal wave_ended(wave_index: int)
## Emitted each time the spawn timer fires during the current wave.
signal spawn_tick(wave_index: int)

## Index of the current wave, starting at 0.
var wave_index: int = 0
## Elapsed seconds inside the current wave.
var time_in_wave: float = 0.0
## Tuning data. Null until [method setup] is called.
var data: WaveData = null

var _spawn_timer: float = 0.0
var _started: bool = false

## Sets the tuning data and resets to wave 0.
func setup(wave_data: WaveData) -> void:
	data = wave_data
	wave_index = 0
	time_in_wave = 0.0
	_spawn_timer = 0.0
	_started = false

## Advances the wave clock. Emits spawn_tick when the spawn timer fires,
## and wave_ended / wave_started on the wave boundary.
func tick(delta: float) -> void:
	if data == null:
		return

	if not _started:
		_started = true
		wave_started.emit(wave_index)

	time_in_wave += delta
	_spawn_timer += delta

	var interval := spawn_interval()
	if interval > 0.0:
		while _spawn_timer >= interval:
			_spawn_timer -= interval
			spawn_tick.emit(wave_index)

	_advance_waves()

## Seconds between spawn events for the current wave. A boss wave stretches the
## interval so the horde does not bury the duel.
func spawn_interval() -> float:
	if data == null:
		return 0.0
	var interval := data.base_spawn_interval * pow(data.interval_decay_per_wave, float(wave_index))
	if is_boss_wave(wave_index):
		interval *= data.boss_spawn_interval_scale
	return maxf(interval, data.min_spawn_interval)


## True when the given wave carries a boss. Pure and total: any index is
## accepted, and a boss_every_waves of zero or less disables bosses everywhere.
func is_boss_wave(index: int = -1) -> bool:
	if data == null or data.boss_every_waves <= 0:
		return false
	var checked := wave_index if index < 0 else index
	if checked < 0:
		return false
	return (checked + 1) % data.boss_every_waves == 0


## Zero-based boss tier of a wave: 0 for the first boss wave, 1 for the second,
## and so on. Returns -1 when the wave carries no boss. The tier is what scales
## a boss's health and damage.
func boss_tier(index: int = -1) -> int:
	if not is_boss_wave(index):
		return -1
	var checked := wave_index if index < 0 else index
	return (checked + 1) / data.boss_every_waves - 1

## Maximum simultaneous enemies for the current wave.
func max_alive() -> int:
	if data == null:
		return 0
	return data.base_max_alive + data.alive_growth_per_wave * wave_index

## 0.0 .. 1.0 progress through the current wave.
func wave_progress() -> float:
	if data == null or data.duration <= 0.0:
		return 0.0
	return clampf(time_in_wave / data.duration, 0.0, 1.0)

## Seconds remaining in the current wave.
func time_left() -> float:
	if data == null:
		return 0.0
	return maxf(data.duration - time_in_wave, 0.0)

## Crosses as many wave boundaries as the elapsed time requires.
func _advance_waves() -> void:
	var duration := maxf(data.duration, 0.001)
	while time_in_wave >= duration:
		time_in_wave -= duration
		_spawn_timer = 0.0
		wave_ended.emit(wave_index)
		wave_index += 1
		wave_started.emit(wave_index)
