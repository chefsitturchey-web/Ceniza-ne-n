"""Dos stems originales sincronizados, 100 BPM, 16 compases, Ogg estéreo.

Requiere numpy y ffmpeg. Los WAV intermedios quedan en .godot, fuera de Git.
La composición es una base de trabajo reemplazable por la producción musical final.
"""
from pathlib import Path
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
BPM = 100
BEAT = 60 / BPM
SECONDS = 16 * 4 * BEAT
N = round(SECONDS * RATE)
RNG = np.random.default_rng(271828)


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def place(track, signal, start, pan=0.0):
    """Wrap de colas: conserva reverberación en el punto de loop."""
    indices = (round(start * RATE) + np.arange(len(signal))) % N
    track[indices, 0] += signal * np.sqrt((1 - pan) / 2)
    track[indices, 1] += signal * np.sqrt((1 + pan) / 2)


def tone(note, duration, kind="pad"):
    t = np.arange(round(duration * RATE)) / RATE
    f = hz(note)
    if kind == "pad":
        signal = (np.sin(2 * np.pi * f * t) + .28 * np.sin(2 * np.pi * f * 2.002 * t)
                  + .12 * np.sin(2 * np.pi * f * 3 * t))
        envelope = np.minimum(t / .35, 1) * np.minimum((duration - t) / .65, 1)
    elif kind == "bell":
        signal = np.sin(2 * np.pi * f * t) + .2 * np.sin(2 * np.pi * f * 3 * t)
        envelope = (1 - np.exp(-t * 100)) * np.exp(-t * 3.5)
    else:
        signal = np.sin(2 * np.pi * f * t) + .2 * np.sin(2 * np.pi * f * 2 * t)
        envelope = (1 - np.exp(-t * 180)) * np.exp(-t * 7)
    return signal * envelope


def reverb(track):
    result = track.copy()
    for seconds, gain in [(.3, .18), (.6, .12), (.9, .07)]:
        result += np.roll(track[:, ::-1], round(seconds * RATE), axis=0) * gain
    return result


def export(name, track):
    track = reverb(track)
    peak = np.max(np.abs(track))
    track *= .63 / max(peak, .001)  # -4 dBFS par stem; buses con margen adicional.
    temp = ROOT / ".godot/audio-source" / f"{name}.wav"
    target = ROOT / "assets/audio/music" / f"{name}.ogg"
    temp.parent.mkdir(parents=True, exist_ok=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(temp), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((np.clip(track, -1, 1) * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(temp),
                    "-c:a", "libvorbis", "-q:a", "6", "-metadata", "LOOPSTART=0",
                    "-metadata", f"LOOPEND={N}", str(target)], check=True)
    print(f"{target.relative_to(ROOT)}: {SECONDS:.1f}s; peak {np.max(np.abs(track)):.3f}")


def main():
    ambient = np.zeros((N, 2), dtype=np.float64)
    siege = np.zeros_like(ambient)
    # Re menor, Sib, Fa, Do: la misma armonía en ambos stems.
    chords = [(50, 57, 65), (46, 53, 62), (41, 53, 60), (48, 55, 64)]
    for bar in range(16):
        chord = chords[(bar // 2) % 4]
        start = bar * 4 * BEAT
        for i, note in enumerate(chord):
            place(ambient, tone(note, 4 * BEAT + .7) * .11, start, (i - 1) * .55)
        for beat in range(4):
            offset = start + beat * BEAT
            if beat in (0, 2):
                t = np.arange(round(.3 * RATE)) / RATE
                kick = np.sin(2 * np.pi * (48 * t + 6 * (1 - np.exp(-t * 24)))) * np.exp(-t * 17)
                place(siege, kick * .46, offset)
            if beat in (1, 3):
                t = np.arange(round(.16 * RATE)) / RATE
                noise = RNG.normal(0, 1, len(t))
                noise = np.convolve(noise, np.ones(5) / 5, mode="same")
                place(siege, noise * np.exp(-t * 32) * .25, offset, -.15)
            place(siege, tone(chord[0] - 12, .25, "bass") * .3, offset)
            for half in range(2):
                t = np.arange(round(.05 * RATE)) / RATE
                noise = RNG.normal(0, 1, len(t))
                noise = np.diff(noise, prepend=noise[0])
                place(siege, noise * np.exp(-t * 95) * .025, offset + half * BEAT / 2, .3)
        if bar % 2 == 0:
            for step, note in enumerate([chord[2] + 12, chord[1] + 12, chord[2] + 7]):
                place(ambient, tone(note, 1.6, "bell") * .065, start + step * BEAT * 1.5, .45 - step * .4)
    export("ruinas", ambient)
    export("asedio", siege)


if __name__ == "__main__":
    main()
