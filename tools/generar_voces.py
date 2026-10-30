"""Voces de diálogo: un blip corto por letra, con timbre fijo por personaje.

Reutiliza el formato de preset de tools/generar_efectos.py (Hz, segundos,
octavas/s) y su cadena de limpieza: paso alto a 20 Hz, cola de 1,5 ms y
normalización de pico. No se escucha nada aquí: solo se mide.

Uso:  python tools/generar_voces.py
Salida: assets/audio/sfx/8bit/voz/voz_<personaje>_<emocion>_v<1..5>.wav
"""
import pathlib
import sys
import wave

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import generar_efectos as fx

MIN_SECONDS = 0.042
MAX_SECONDS = 0.090
VARIANT_SEMITONES = [-2, -1, 0, 1, 2]

# Timbre fijo por personaje: onda, duty, filtros y altura base (Hz).
# La emoción no toca ninguno de estos valores.
CHARACTERS = {
    # Cuadrada fina y aguda: lectura clara y alegre.
    "protagonista": dict(wave="square", duty=0.125, start=880.0, attack=0.002, sustain=0.004,
                         decay=0.040, lowpass=6000.0, highpass=300.0),
    # Cuadrada ancha y grave con algo de grano para que suene áspera.
    "rival": dict(wave="square", duty=0.35, start=330.0, attack=0.003, sustain=0.005,
                  decay=0.055, lowpass=2600.0, highpass=180.0),
    # Grave y suave: cuadrada muy filtrada. Un seno puro a esta altura se
    # pierde en parlantes chicos por falta de armónicos.
    "anciano": dict(wave="square", duty=0.5, start=260.0, attack=0.005, sustain=0.006,
                    decay=0.060, lowpass=1600.0, resonance=0.15, highpass=120.0),
    # Cuadrada altísima y muy breve: parece un gorjeo.
    "criatura": dict(wave="square", duty=0.5, start=1800.0, attack=0.001, sustain=0.002,
                     decay=0.038, lowpass=9000.0, highpass=600.0),
    # Sierra con resonancia marcada: timbre metálico de sintetizador barato.
    "robot": dict(wave="saw", duty=0.5, start=420.0, attack=0.002, sustain=0.005,
                  decay=0.048, lowpass=1800.0, resonance=0.45, highpass=200.0),
}

# La emoción solo mueve altura, largo, barrido y aspereza: el timbre no cambia.
EMOTIONS = {
    "neutral": dict(pitch=1.00, length=1.00, slide=0.0, rough=0.00, punch=0.05),
    "feliz": dict(pitch=1.25, length=0.85, slide=0.5, rough=0.00, punch=0.05),
    "triste": dict(pitch=0.80, length=1.25, slide=-0.6, rough=0.00, punch=0.03),
    "enojado": dict(pitch=0.95, length=0.80, slide=-0.3, rough=0.12, punch=0.10),
}


def build(character: str, emotion: str, semitones: int) -> dict:
    """Preset concreto: timbre del personaje + ajustes de la emoción + variante."""
    timbre = CHARACTERS[character]
    mood = EMOTIONS[emotion]
    attack = timbre["attack"]
    sustain = timbre["sustain"]
    total = min(MAX_SECONDS, max(MIN_SECONDS, attack + sustain + timbre["decay"] * mood["length"]))
    start = timbre["start"] * mood["pitch"] * 2.0 ** (semitones / 12.0)
    spec = dict(timbre)
    spec.update(
        start=start,
        # Permite la caída del barrido sin bajar de la octava inferior.
        min=start * 0.85,
        decay=total - attack - sustain,
        slide=mood["slide"],
        punch=mood["punch"],
        noise_mix=mood["rough"],
        # Determinista: el mismo preset produce siempre el mismo archivo.
        seed=abs(hash((character, emotion, semitones))) % 100000,
    )
    return spec


def export_all() -> list[pathlib.Path]:
    """Escribe los 100 blips y devuelve sus rutas."""
    written: list[pathlib.Path] = []
    for character in CHARACTERS:
        for emotion in EMOTIONS:
            for index, semitones in enumerate(VARIANT_SEMITONES, start=1):
                name = "voz_%s_%s_v%d" % (character, emotion, index)
                data = fx.render(build(character, emotion, semitones))
                written.append(fx.save("voz", name, data))
    return written


def measure(path: pathlib.Path) -> dict:
    """Lee el WAV del disco y devuelve sus métricas."""
    with wave.open(str(path)) as reader:
        channels = reader.getnchannels()
        width = reader.getsampwidth()
        rate = reader.getframerate()
        frames = reader.getnframes()
        raw = reader.readframes(frames)
    samples = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
    peak = np.abs(samples).max()
    spectrum = np.abs(np.fft.rfft(samples))
    frequencies = np.fft.rfftfreq(len(samples), 1.0 / rate)
    return {
        "ms": frames / rate * 1000.0,
        "peak_db": 20.0 * np.log10(max(peak, 1e-9)),
        "rms_db": 20.0 * np.log10(max(np.sqrt((samples ** 2).mean()), 1e-9)),
        "dc": float(samples.mean()),
        "clipped": int((np.abs(samples) >= 32767.0 / 32768.0).sum()),
        "centroid": float((spectrum * frequencies).sum() / (spectrum.sum() + 1e-12)),
        "format_ok": (channels, width, rate) == (1, 2, 44100),
    }


def verify(paths: list[pathlib.Path]) -> int:
    """Comprueba formato, duración y clipping. Devuelve el número de fallos."""
    failures: list[str] = []
    print("%-38s %7s %7s %7s %8s %8s" % ("archivo", "ms", "pico", "rms", "continua", "centro"))
    for path in paths:
        info = measure(path)
        print("%-38s %7.2f %7.1f %7.1f %8.4f %8.0f" % (
            path.name, info["ms"], info["peak_db"], info["rms_db"], info["dc"], info["centroid"]))
        if not info["format_ok"]:
            failures.append("%s: formato distinto de mono 16 bits 44,1 kHz" % path.name)
        if info["ms"] < 40.0 or info["ms"] > MAX_SECONDS * 1000.0:
            failures.append("%s: dura %.2f ms, fuera del rango 40-90 ms" % (path.name, info["ms"]))
        if info["clipped"] > 0:
            failures.append("%s: %d muestras saturadas" % (path.name, info["clipped"]))
        if abs(info["dc"]) > 0.01:
            failures.append("%s: continua de %.4f" % (path.name, info["dc"]))
    if failures:
        print("\nFALLOS (%d):" % len(failures))
        for failure in failures:
            print("  - " + failure)
    else:
        print("\nOK: %d blips dentro de rango, sin clipping ni continua." % len(paths))
    return len(failures)


def main() -> int:
    paths = export_all()
    print("Tabla base por personaje (emoción neutral, sin variante):")
    print("%-14s %-7s %8s %6s %8s" % ("personaje", "onda", "start", "duty", "decay"))
    for name, timbre in CHARACTERS.items():
        print("%-14s %-7s %8.0f %6.2f %8.3f" % (
            name, timbre["wave"], timbre["start"], timbre["duty"], timbre["decay"]))
    print()
    return 1 if verify(paths) > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())


