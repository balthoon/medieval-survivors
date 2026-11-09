# The Conductor — Concept Prototype

**PROTOTYPE - NOT FOR PRODUCTION**

Throwaway build. One question, four to five minutes of play, then it is deleted or
archived. **Nothing here is production code** and nothing outside this directory may
import it.

## Hypothesis

> If the player casts on the beat, they will feel the attack *belongs* to the
> music — we will know if they keep aiming for the beat when nothing forces them
> to, restart after a death, and describe the act as satisfying within five
> minutes.

## Riskiest assumption

**C — boredom without builds.** The timing pleasure may not sustain a run without
builds or meta-progression.

Two gates sit in front of C and must be crossed first:

- **A — the gesture itself.** Is casting on the beat pleasant to do, before any
  counter or reward?
- **B — audio latency.** If the sound does not land where the flash says it does,
  the sensation is dead on arrival and C can never be answered.

## How to run

Point Godot at **this directory**, never at the repository root — the root has its
own `project.godot` from `/setup-engine`, and it is an empty project.

```bash
"C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64.exe" --path prototypes/the-conductor-concept
```

| Input | Action |
|---|---|
| ZQSD / arrow keys | move |
| Space | cast |
| R | restart after death |

Acast on the beat builds Crescendo (10 → Forte: every cast counts as on-beat for
three seconds). **An off-beat cast is not punished** — it works normally and simply
does not build Crescendo. That is deliberate: the prototype is testing whether the
beat *attracts* the player, not whether it coerces them.

## What is being tested

| Element | Value | Why |
|---|---|---|
| Tempo | 100 BPM, one beat every 0.6 s | Slow enough that a first-time player can find the beat by ear |
| Loop | 2 bars of 4/4 = 4.8 s, generated percussion | Music *is* the mechanic here — the one permitted exception to "no music" |
| On-beat window | ±0.110 s | Deliberately wide. This prototype must not fail because of latency, only because of boredom |
| Spell | one area burst, no aiming, no builds | Removes every lever except timing |
| Difficulty | rises by enemy **density only** | Never by stats — a spike in difficulty must never masquerade as a defect in the beat |
| Death | contact, no game-over screen | Restart is one key so the loop never stalls |

The wide window is the point. If the loop is fun at ±110 ms, later designs can
narrow it. If it is boring at ±110 ms, no amount of tightening will save it.

## Observation points

Written down **before** playing, so the result cannot be read backwards:

1. **At 2 minutes** — am I still aiming for the beat when nothing forces me?
2. **At 4 minutes** — has boredom arrived? At exactly what moment?
3. **Deaths and restarts** — did I die, and did I start again without hesitating?
   A restart is a vote; a quit is a verdict.
4. **Sound off** — does the game stay legible with only the on-screen beat bar?
   This is gate B, in the form a player actually experiences it.

## File map

```
project.godot            own Godot project, run/main_scene = main.tscn
main.tscn                the whole scene: arena, player, beat clock, spawner, HUD
scripts/beat_clock.gd    audio-driven beat clock and on-beat window
scripts/player.gd        movement and the single burst spell
scripts/enemy.gd         three enemy kinds, built in code
scripts/spawner.gd       density ramp
scripts/hud.gd           beat bar, Crescendo counter, timer, status line
tools/make_beat_wav.py   regenerates audio/beat_loop.wav from pure stdlib
audio/beat_loop.wav      the 4.8 s loop
```

The beat clock uses the standard Godot rhythm recipe —
`get_playback_position() + AudioServer.get_time_since_last_mix() -
AudioServer.get_output_latency()` — with loop-wrap correction. If the flash and the
sound ever disagree, that line is the first suspect, and the real fix is a
calibration screen, not a code change.

## Status

**in-progress** — built and verified clean (headless import, six `--check-only`
parse runs, boot smoke test and a 40-second windowed run with no errors).
Not yet played by a human.

Known gap: the automated runs are silent, so nobody has confirmed by ear that the
loop plays and loops seamlessly. That is the first thing to check.

## Findings

*(filled in when the prototype concludes — see Phase 6 debrief and the prototype
report under `production/`)*
