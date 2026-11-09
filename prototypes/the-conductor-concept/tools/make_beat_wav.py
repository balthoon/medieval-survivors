# PROTOTYPE - NOT FOR PRODUCTION
# Question: does casting on the beat stay engaging for 4-5 minutes with no builds or meta-progression?
# Date: 2026-11-09
"""Generate a seamless 2-bar, 100 BPM click/kick loop as a 16-bit mono WAV.

Pure standard library: wave + struct + math.
Beats 1 and 3 of each bar get a low kick, beats 2 and 4 a higher tick,
and every eighth-note off-beat gets a soft subdivision tick.
Hits are rendered into a circular buffer so their tails wrap to the start,
which keeps the file seamless at the loop point. A RIFF "smpl" chunk is
appended so Godot's WAV importer detects and loops the whole file.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
BPM = 100.0
BEATS_PER_BAR = 4
BARS_PER_LOOP = 2
SEC_PER_BEAT = 60.0 / BPM
TOTAL_BEATS = BEATS_PER_BAR * BARS_PER_LOOP
DURATION = SEC_PER_BEAT * TOTAL_BEATS          # 4.8 s exactly
TOTAL_SAMPLES = int(round(DURATION * SAMPLE_RATE))

OUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "audio",
    "beat_loop.wav",
)


def _tail_fade(index, count, fade_samples=256):
    """Short linear fade so a hit reaches exactly zero at its end."""
    remaining = count - index
    if remaining >= fade_samples:
        return 1.0
    return remaining / float(fade_samples)


def add_kick(buf, start_sample, amp=0.95):
    """Low, punchy kick: sine with an exponential pitch sweep and fast decay."""
    count = int(0.42 * SAMPLE_RATE)
    for i in range(count):
        t = i / SAMPLE_RATE
        # Frequency sweeps ~158 Hz -> 48 Hz; integrate for a clean phase.
        phase = 2.0 * math.pi * (48.0 * t + 110.0 * (1.0 - math.exp(-26.0 * t)) / 26.0)
        body = math.sin(phase) * math.exp(-t * 9.0)
        click = math.sin(2.0 * math.pi * 1200.0 * t) * math.exp(-t * 240.0) * 0.22
        sample = amp * (body + click) * _tail_fade(i, count)
        buf[(start_sample + i) % TOTAL_SAMPLES] += sample


def add_tick(buf, start_sample, amp=0.60):
    """Higher tick for beats 2 and 4, with a little second harmonic for cut-through."""
    count = int(0.11 * SAMPLE_RATE)
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 42.0) * _tail_fade(i, count)
        sample = amp * env * (
            math.sin(2.0 * math.pi * 1318.5 * t)
            + 0.30 * math.sin(2.0 * math.pi * 2637.0 * t)
        )
        buf[(start_sample + i) % TOTAL_SAMPLES] += sample


def add_offbeat(buf, start_sample, amp=0.30):
    """Soft, very short subdivision tick on the off-beats."""
    count = int(0.055 * SAMPLE_RATE)
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 95.0) * _tail_fade(i, count, 64)
        sample = amp * env * math.sin(2.0 * math.pi * 2093.0 * t)
        buf[(start_sample + i) % TOTAL_SAMPLES] += sample


def build():
    buf = [0.0] * TOTAL_SAMPLES
    for bar in range(BARS_PER_LOOP):
        for beat in range(BEATS_PER_BAR):
            beat_index = bar * BEATS_PER_BAR + beat
            at = int(round(beat_index * SEC_PER_BEAT * SAMPLE_RATE))
            if beat in (0, 2):
                add_kick(buf, at)
            else:
                add_tick(buf, at)
            # Soft subdivision tick on the off-beat (beat + 1/2).
            off = int(round((beat_index + 0.5) * SEC_PER_BEAT * SAMPLE_RATE))
            add_offbeat(buf, off)
    # Normalise to a fixed peak so overlapping transients never clip.
    peak = max(abs(x) for x in buf) or 1.0
    scale = 0.89 / peak
    return [x * scale for x in buf]


def _append_smpl_loop(path, frame_count):
    """Append a RIFF "smpl" chunk describing a loop over the whole file."""
    period_ns = int(round(1_000_000_000.0 / SAMPLE_RATE))
    header = struct.pack("<9I", 0, 0, period_ns, 60, 0, 0, 0, 1, 0)
    loop = struct.pack("<6I", 0, 0, 0, frame_count - 1, 0, 0)
    payload = header + loop
    chunk = b"smpl" + struct.pack("<I", len(payload)) + payload
    with open(path, "r+b") as handle:
        handle.seek(0, 2)
        handle.write(chunk)
        file_size = handle.tell()
        handle.seek(4)
        handle.write(struct.pack("<I", file_size - 8))


def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    frames = bytearray()
    for start in range(0, len(samples), 4096):
        chunk = samples[start:start + 4096]
        ints = [
            max(-32768, min(32767, int(round(x * 32767.0))))
            for x in chunk
        ]
        frames += struct.pack("<%dh" % len(ints), *ints)
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(bytes(frames))
    _append_smpl_loop(path, len(samples))


def main():
    samples = build()
    write_wav(OUT_PATH, samples)
    with wave.open(OUT_PATH, "rb") as wav:
        frames = wav.getnframes()
        rate = wav.getframerate()
        duration = frames / float(rate)
        channels = wav.getnchannels()
        width = wav.getsampwidth()
    size = os.path.getsize(OUT_PATH)
    print("wrote    : %s" % OUT_PATH)
    print("bytes    : %d" % size)
    print("frames   : %d" % frames)
    print("duration : %.6f s (expected %.6f s)" % (duration, DURATION))
    print(
        "format   : %d Hz, %d-bit, %s"
        % (rate, width * 8, "mono" if channels == 1 else "stereo")
    )


if __name__ == "__main__":
    main()
