"""Generate the slice's sound effects as small WAV files.

Every sound is synthesised from scratch with the Python standard library, so
the repository carries no binary source assets for audio. The script is fully
deterministic: each sound draws from a Random instance with a fixed seed, so
rerunning it always produces byte-identical files.

Output: assets/audio/sfx/*.wav -- 44100 Hz, mono, 16-bit PCM, normalised to
0.8 peak with a 5 ms fade in and fade out against clicks. The six combat sounds
stay under 0.30 s; the two boss sounds are longer (0.55 s and 0.75 s) because a
boss needs a tell, not a click.

Usage (from the repository root):

    python tools/make_sfx_wav.py
"""

import math
import os
import random
import struct
import wave

# Audio format shared by every generated file.
SAMPLE_RATE = 44100
SAMPLE_WIDTH_BYTES = 2
CHANNELS = 1

# Peak amplitude after normalisation, in 0..1 full scale.
PEAK = 0.8

# Linear fade at both ends, in seconds, to avoid clicks.
FADE_SECONDS = 0.005

# Output directory, resolved from this script so any working directory works.
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(_REPO_ROOT, "assets", "audio", "sfx")


def _length(duration):
    """Return the sample count for a duration in seconds."""
    return int(round(SAMPLE_RATE * duration))


def _normalise(samples):
    """Scale the buffer so its largest absolute sample sits at PEAK."""
    largest = 0.0
    for sample in samples:
        magnitude = abs(sample)
        if magnitude > largest:
            largest = magnitude
    if largest <= 0.0:
        return samples
    scale = PEAK / largest
    return [sample * scale for sample in samples]


def _apply_fades(samples):
    """Apply a short linear fade in and fade out to the buffer."""
    fade = min(int(round(SAMPLE_RATE * FADE_SECONDS)), len(samples) // 2)
    for index in range(fade):
        gain = index / fade
        samples[index] *= gain
        samples[-1 - index] *= gain
    return samples


def _write_wav(name, samples):
    """Convert a float buffer to 16-bit PCM and write it under OUTPUT_DIR."""
    frames = []
    for sample in samples:
        clamped = max(-1.0, min(1.0, sample))
        frames.append(int(round(clamped * 32767.0)))
    payload = struct.pack("<%dh" % len(frames), *frames)
    path = os.path.join(OUTPUT_DIR, name)
    with wave.open(path, "wb") as wav_file:
        wav_file.setnchannels(CHANNELS)
        wav_file.setsampwidth(SAMPLE_WIDTH_BYTES)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(payload)


def _hit_light(rng):
    """0.10 s -- bright noise burst over a 180 Hz body, fast decay."""
    samples = []
    previous_noise = 0.0
    for index in range(_length(0.10)):
        t = index / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        # Difference between successive noise samples: a crude high-pass that
        # keeps the burst bright instead of dull.
        bright = noise - previous_noise
        previous_noise = noise
        burst = bright * 0.55 * math.exp(-t / 0.018)
        body = math.sin(2.0 * math.pi * 180.0 * t) * 0.8 * math.exp(-t / 0.030)
        samples.append(burst + body)
    return samples


def _hit_heavy(rng):
    """0.28 s -- 70 Hz thump with a pitch drop and noise, slow decay."""
    samples = []
    phase = 0.0
    previous_noise = 0.0
    for index in range(_length(0.28)):
        t = index / SAMPLE_RATE
        # Starts around 130 Hz and settles on 70 Hz: the drop adds weight.
        frequency = 70.0 + 60.0 * math.exp(-t / 0.060)
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        thump = math.sin(phase) * math.exp(-t / 0.120)
        noise = rng.uniform(-1.0, 1.0)
        rumble = (noise - previous_noise * 0.5) * 0.35 * math.exp(-t / 0.050)
        previous_noise = noise
        samples.append(thump + rumble)
    return samples


def _hit_crit(rng):
    """0.22 s -- metallic double ping around 1320 Hz and 1980 Hz."""
    samples = []
    # (start seconds, gain) for the two pings of the double hit.
    pings = ((0.0, 1.0), (0.07, 0.75))
    for index in range(_length(0.22)):
        t = index / SAMPLE_RATE
        value = 0.0
        for start, gain in pings:
            local = t - start
            if local < 0.0:
                continue
            envelope = math.exp(-local / 0.030) * gain
            value += math.sin(2.0 * math.pi * 1320.0 * local) * envelope
            value += math.sin(2.0 * math.pi * 1980.0 * local) * envelope * 0.8
            # A quiet octave above the first partial reads as metallic.
            value += math.sin(2.0 * math.pi * 2640.0 * local) * envelope * 0.25
            value += rng.uniform(-1.0, 1.0) * 0.3 * math.exp(-local / 0.004) * gain
        samples.append(value)
    return samples


def _enemy_death(rng):
    """0.24 s -- descending tone 440 -> 110 Hz with a noise fade."""
    duration = 0.24
    samples = []
    phase = 0.0
    for index in range(_length(duration)):
        t = index / SAMPLE_RATE
        frequency = 440.0 * (110.0 / 440.0) ** (t / duration)
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        fade = 1.0 - t / duration
        tone = math.sin(phase) * 0.8 * fade
        noise = rng.uniform(-1.0, 1.0) * 0.35 * fade * fade
        samples.append(tone + noise)
    return samples


def _player_hurt(rng):
    """0.20 s -- low 110 Hz square-ish body plus noise."""
    samples = []
    for index in range(_length(0.20)):
        t = index / SAMPLE_RATE
        sine = math.sin(2.0 * math.pi * 110.0 * t)
        # tanh turns the sine square-ish while rounding off the harsh edges.
        body = math.tanh(4.0 * sine) * 0.7 * math.exp(-t / 0.080)
        noise = rng.uniform(-1.0, 1.0) * 0.5 * math.exp(-t / 0.030)
        samples.append(body + noise)
    return samples


def _level_up(rng):
    """0.30 s -- ascending sine notes 523, 659 and 784 Hz, soft envelopes."""
    duration = 0.30
    notes = (523.0, 659.0, 784.0)
    segment = duration / len(notes)
    attack = 0.012
    samples = [0.0] * _length(duration)
    for note_index, frequency in enumerate(notes):
        start = note_index * segment
        # Each note rings a little past its slot so the arpeggio sounds joined.
        note_length = segment + 0.04
        start_sample = int(round(start * SAMPLE_RATE))
        for offset in range(_length(note_length)):
            position = start_sample + offset
            if position >= len(samples):
                break
            local = offset / SAMPLE_RATE
            if local < attack:
                envelope = local / attack
            else:
                envelope = math.exp(-(local - attack) / 0.060)
            samples[position] += (
                math.sin(2.0 * math.pi * frequency * local) * envelope * 0.55
            )
    return samples


def _boss_roar(rng):
    """0.75 s -- a low growl announcing the boss: 70 Hz saw sinking to 46 Hz,
    plus a slow noise breath and a sub octave. Slow attack, so it swells."""
    duration = 0.75
    samples = []
    phase = 0.0
    previous_noise = 0.0
    for index in range(_length(duration)):
        t = index / SAMPLE_RATE
        frequency = 70.0 * (46.0 / 70.0) ** (t / duration)
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        # A saw reads as a growl where a sine would read as a hum. Two detuned
        # copies beat against each other and add the roughness.
        saw = ((phase / math.pi) % 2.0) - 1.0
        detuned = ((phase * 1.013 / math.pi) % 2.0) - 1.0
        sub = math.sin(phase * 0.5) * 0.45
        noise = rng.uniform(-1.0, 1.0)
        breath = (noise - previous_noise * 0.7) * 0.22
        previous_noise = noise
        # 0.10 s swell then a long decay: the roar arrives rather than clicks.
        if t < 0.10:
            envelope = t / 0.10
        else:
            envelope = math.exp(-(t - 0.10) / 0.24)
        samples.append((saw * 0.55 + detuned * 0.35 + sub + breath) * envelope)
    return samples


def _boss_slam(rng):
    """0.55 s -- the ground slam: a 90 -> 34 Hz drop, a sub thump and a wide
    noise burst that decays slower than the tone, so it reads as weight."""
    duration = 0.55
    samples = []
    phase = 0.0
    for index in range(_length(duration)):
        t = index / SAMPLE_RATE
        frequency = 34.0 + 56.0 * math.exp(-t / 0.045)
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        thump = math.sin(phase) * math.exp(-t / 0.16)
        sub = math.sin(phase * 0.5) * 0.5 * math.exp(-t / 0.22)
        # Two noise layers: a sharp crack and a longer rubble tail.
        crack = rng.uniform(-1.0, 1.0) * 0.55 * math.exp(-t / 0.020)
        rubble = rng.uniform(-1.0, 1.0) * 0.22 * math.exp(-t / 0.130)
        samples.append(thump + sub + crack + rubble)
    return samples


# File name -> generator. Order fixes the deterministic seed of each sound.
_BUILDERS = (
    ("hit_light.wav", _hit_light),
    ("hit_heavy.wav", _hit_heavy),
    ("hit_crit.wav", _hit_crit),
    ("enemy_death.wav", _enemy_death),
    ("player_hurt.wav", _player_hurt),
    ("level_up.wav", _level_up),
    ("boss_roar.wav", _boss_roar),
    ("boss_slam.wav", _boss_slam),
)


def main():
    """Build every sound effect into OUTPUT_DIR."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for index, (name, builder) in enumerate(_BUILDERS):
        # Fixed seed per sound file: rerunning the script is byte-identical.
        rng = random.Random(0x5EED + index)
        # Fade first, then normalise: the written file peaks at exactly PEAK
        # and still starts and ends at zero.
        samples = _normalise(_apply_fades(builder(rng)))
        _write_wav(name, samples)
        print("%-18s %5.2f s  %d samples" % (name, len(samples) / SAMPLE_RATE, len(samples)))
    print("Wrote %d files to %s" % (len(_BUILDERS), OUTPUT_DIR))


if __name__ == "__main__":
    main()
