## Wave pacing: duration, spawn cadence decay and the simultaneous enemy cap.
##
## Values live in .tres resources under res://data/waves/.
class_name WaveData
extends Resource

## Length of one wave in seconds.
@export var duration: float = 20.0
## Seconds between spawn events on wave 0.
@export var base_spawn_interval: float = 1.4
## Multiplier applied to the spawn interval for each wave.
@export var interval_decay_per_wave: float = 0.88
## Lower bound for the spawn interval in seconds.
@export var min_spawn_interval: float = 0.22
## Maximum simultaneous enemies on wave 0.
@export var base_max_alive: int = 18
## Extra simultaneous enemies allowed per wave.
@export var alive_growth_per_wave: int = 6
## One wave in this many is a boss wave, counting from wave 0. Zero disables
## bosses entirely, which is how a test or a prototype turns them off.
@export var boss_every_waves: int = 5
## Multiplier applied to the spawn interval during a boss wave. Above one, so the
## horde thins out while the player duels: the boss, not the crowd, must be the
## thing the player is fighting.
@export var boss_spawn_interval_scale: float = 1.6
