"""Sintetiza los efectos de sonido 8-bit del juego en WAV mono 44,1 kHz.

Mismo espíritu que sfxr/jsfxr, pero con parámetros en unidades físicas:
frecuencias en Hz, tiempos en segundos y barridos en octavas por segundo.
Los números no coinciden con los deslizadores de jsfxr; el resultado buscado sí.

Uso:  python tools/generar_efectos.py
Salida: assets/audio/sfx/8bit/*.wav
"""
import pathlib
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
DST = ROOT / "assets" / "audio" / "sfx" / "8bit"
RATE = 44100
TARGET_PEAK_DB = -6.0


def envelope(t, attack, sustain, decay, punch):
    """Ataque lineal, sostén plano con golpe y caída exponencial."""
    out = np.zeros_like(t)
    index = 0
    if attack > 0.0:
        samples = min(len(t), int(attack * RATE))
        out[:samples] = np.linspace(0.0, 1.0, samples, endpoint=False)
        index = samples
    else:
        out[0] = 1.0
    hold = min(len(t), index + int(sustain * RATE))
    out[index:hold] = 1.0
    index = hold
    tail = min(len(t), index + int(decay * RATE))
    if tail > index:
        span = (t[index:tail] - t[index]) / max(decay, 1e-6)
        out[index:tail] = np.exp(-4.6 * span)
    if punch > 0.0:
        span = np.clip(t / max(attack + sustain, 1e-6), 0.0, 1.0)
        out *= 1.0 + punch * (1.0 - span)
    return np.clip(out, 0.0, None)


def oscillator(phase, wave, duty, rng):
    """Genera la forma de onda a partir de la fase acumulada."""
    if wave == "noise":
        # Ruido muestreado y retenido al ritmo de la frecuencia: suena con altura.
        steps = np.floor(phase / (2.0 * np.pi)).astype(np.int64)
        values = rng.uniform(-1.0, 1.0, size=int(steps.max()) + 2)
        return values[steps]
    if wave == "square":
        cycle = np.mod(phase / (2.0 * np.pi), 1.0)
        return np.where(cycle < duty, 1.0, -1.0)
    if wave == "triangle":
        # Triángulo: mismo peso percibido que el seno pero con armónicos
        # impares, así un tono grave no se pierde en parlantes chicos.
        cycle = np.mod(phase / (2.0 * np.pi), 1.0)
        return 2.0 * np.abs(2.0 * (cycle - np.floor(cycle + 0.5))) - 1.0
    if wave == "saw":
        return 2.0 * np.mod(phase / (2.0 * np.pi), 1.0) - 1.0
    return np.sin(phase)


def lowpass(x, cutoff, sweep=0.0, resonance=0.0):
    """Filtro de variable de estado (Chamberlin); acepta corte variable."""
    out = np.zeros_like(x)
    low = 0.0
    band = 0.0
    damping = 1.0 - min(max(resonance, 0.0), 0.95) * 0.92
    for index in range(len(x)):
        # El filtro de variable de estado solo es estable por debajo de fs/6.
        current = max(80.0, min(cutoff + sweep * index / RATE, RATE * 0.15))
        f = 2.0 * np.sin(np.pi * min(current / RATE, 0.45))
        low += f * band
        high = x[index] - low - damping * band
        band += f * high
        out[index] = low
    return out


def highpass(x, cutoff, sweep=0.0):
    """Paso alto de un polo; con barrido mueve la banda y da el aire del tajo."""
    out = np.zeros_like(x)
    previous_in = 0.0
    previous_out = 0.0
    for index in range(len(x)):
        current = max(20.0, cutoff + sweep * index / RATE)
        rc = 1.0 / (2.0 * np.pi * current)
        alpha = rc / (rc + 1.0 / RATE)
        previous_out = alpha * (previous_out + x[index] - previous_in)
        previous_in = x[index]
        out[index] = previous_out
    return out


def flanger(x, offset_ms, sweep_ms, mix=0.5):
    """Copia retardada que se mueve; da cuerpo metálico sin alargar el sonido."""
    delay = (offset_ms + sweep_ms * np.arange(len(x)) / RATE) * RATE / 1000.0
    delay = np.clip(delay, 0.0, len(x) - 1.0).astype(np.int64)
    return x + mix * x[np.arange(len(x)) - delay]


def render(spec):
    """Construye un efecto a partir de su especificación."""
    rng = np.random.default_rng(spec.get("seed", 1))
    attack = spec.get("attack", 0.0)
    sustain = spec.get("sustain", 0.01)
    decay = spec.get("decay", 0.06)
    total = attack + sustain + decay
    t = np.arange(int(total * RATE)) / RATE

    freq = spec["start"] * np.power(2.0, spec.get("slide", 0.0) * t + 0.5 * spec.get("delta", 0.0) * t * t)
    if spec.get("vibrato", 0.0) > 0.0:
        freq *= np.power(2.0, spec["vibrato"] / 12.0 * np.sin(2.0 * np.pi * spec.get("vibrato_speed", 6.0) * t))
    if spec.get("arp_mult", 0.0) > 0.0:
        steps = (t // max(spec.get("arp_speed", 0.1), 1e-3)).astype(np.int64)
        freq *= np.where(steps % 2 == 1, spec["arp_mult"], 1.0)
    freq = np.clip(freq, spec.get("min", 30.0), RATE * 0.45)

    duty = np.clip(spec.get("duty", 0.5) + spec.get("duty_sweep", 0.0) * t, 0.02, 0.98)
    phase = np.cumsum(2.0 * np.pi * freq / RATE)
    wave_data = oscillator(phase, spec.get("wave", "square"), duty, rng)
    if spec.get("wave") == "square" and np.ndim(duty) > 0:
        cycle = np.mod(phase / (2.0 * np.pi), 1.0)
        wave_data = np.where(cycle < duty, 1.0, -1.0)

    wave_data *= envelope(t, attack, sustain, decay, spec.get("punch", 0.0))
    noise_mix = spec.get("noise_mix", 0.0)
    if noise_mix > 0.0:
        grain = rng.uniform(-1.0, 1.0, size=len(t))
        wave_data = (1.0 - noise_mix) * wave_data + noise_mix * grain * envelope(
            t, attack, sustain, decay, spec.get("punch", 0.0))

    if spec.get("flanger", 0.0) > 0.0:
        wave_data = flanger(wave_data, spec["flanger"], spec.get("flanger_sweep", 0.0))
    if spec.get("lowpass", 0.0) > 0.0:
        wave_data = lowpass(wave_data, spec["lowpass"], spec.get("lowpass_sweep", 0.0), spec.get("resonance", 0.0))
    if spec.get("highpass", 0.0) > 0.0:
        wave_data = highpass(wave_data, spec["highpass"], spec.get("highpass_sweep", 0.0))

    # Quita la continua (las ondas cuadradas asimétricas la generan) y cierra el
    # archivo con 1,5 ms de caída: sin eso se escucha un click al cortar.
    wave_data = highpass(wave_data, 20.0)
    fade = min(len(wave_data), int(0.0015 * RATE))
    wave_data[-fade:] *= np.linspace(1.0, 0.0, fade)

    # Compresión suave: el ruido tiene picos altos y poca energía media, así que
    # normalizar por pico lo deja inaudible al lado de un tono.
    drive = spec.get("drive", 0.0)
    if drive > 0.0:
        wave_data = np.tanh(wave_data * drive) / np.tanh(drive)

    peak = np.max(np.abs(wave_data)) + 1e-9
    wave_data *= 10.0 ** (spec.get("peak_db", TARGET_PEAK_DB) / 20.0) / peak
    return wave_data


def save(group, name, data):
    folder = DST / group
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / (name + ".wav")
    with wave.open(str(target), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((np.clip(data, -1.0, 1.0) * 32767.0).astype("<i2").tobytes())
    return target


PRESETS = {
    # --- Combate base ---
    # Corte de espada: banda de aire que baja de 4,8 kHz a 1 kHz, con algo de
    # resonancia para que el filo tenga filo metálico y no sea solo viento.
    "slash": dict(wave="noise", attack=0.002, sustain=0.012, decay=0.100, start=2800.0,
                  min=350.0, slide=-14.0, lowpass=4800.0, lowpass_sweep=-20000.0,
                  resonance=0.20, highpass=1600.0, highpass_sweep=-11000.0, drive=2.6, seed=7),
    # Láser: barrido descendente rápido y seco.
    "shot": dict(wave="square", duty=0.5, attack=0.0, sustain=0.008, decay=0.060, start=2400.0,
                 min=220.0, slide=-30.0, punch=0.10, highpass=400.0, seed=11),
    "hit": dict(wave="noise", attack=0.0, sustain=0.004, decay=0.055, start=900.0, min=80.0,
                slide=-22.0, punch=0.30, lowpass=1400.0, resonance=0.1, seed=13),
    "step": dict(wave="noise", attack=0.0, sustain=0.002, decay=0.018, start=500.0, min=180.0,
                 slide=-10.0, lowpass=900.0, seed=17),
    "dodge": dict(wave="square", duty=0.25, attack=0.005, sustain=0.030, decay=0.080, start=680.0, min=140.0,
                  slide=-6.0, punch=0.10, lowpass=2600.0, seed=19),
    # Embestida de jefe: ráfaga de aire que baja de tono mientras avanza.
    "dash": dict(wave="noise", attack=0.004, sustain=0.030, decay=0.220, start=900.0, min=120.0,
                 slide=-4.0, lowpass=2200.0, lowpass_sweep=-1200.0, highpass=220.0,
                 highpass_sweep=-150.0, drive=2.0, peak_db=-8.0, seed=101),
    # La misma embestida para Santa Caldera: más grave, más larga y con más cuerpo.
    "dash_caldera": dict(wave="noise", attack=0.004, sustain=0.045, decay=0.300, start=500.0,
                         min=60.0, slide=-2.5, punch=0.20, lowpass=1400.0, lowpass_sweep=-500.0,
                         highpass=90.0, drive=3.0, peak_db=-7.0, seed=103),
    # Klaxon de aviso: alterna dos alturas cada 140 ms sobre la misma nota base.
    "alarm": dict(wave="square", duty=0.5, attack=0.005, sustain=0.300, decay=0.145, start=620.0,
                  min=600.0, arp_mult=1.5, arp_speed=0.14, lowpass=2600.0, highpass=300.0,
                  peak_db=-8.0, seed=23),
    "upgrade": dict(wave="square", attack=0.0, sustain=0.150, decay=0.240, start=300.0, min=280.0,
                    slide=9.0, punch=0.20, arp_mult=1.4, arp_speed=0.12, duty=0.5, seed=29),
    "destroy": dict(wave="noise", attack=0.005, sustain=0.050, decay=0.420, start=400.0, min=40.0,
                    slide=-3.0, punch=0.15, lowpass=1600.0, lowpass_sweep=-600.0, resonance=0.15,
                    flanger=0.02, flanger_sweep=0.0, seed=31),

    # --- Economía y construcción ---
    "denied": dict(wave="noise", attack=0.0, sustain=0.010, decay=0.110, start=240.0, min=90.0,
                   slide=-3.0, lowpass=700.0, peak_db=-8.0, seed=37),
    "pickup": dict(wave="square", duty=0.5, attack=0.0, sustain=0.020, decay=0.100, start=900.0, min=880.0,
                   arp_mult=1.5, arp_speed=0.045, highpass=250.0, seed=41),
    "build_order": dict(wave="square", duty=0.25, attack=0.0, sustain=0.004, decay=0.035, start=620.0,
                        min=600.0, highpass=300.0, peak_db=-9.0, seed=43),
    "build_done": dict(wave="square", duty=0.5, attack=0.0, sustain=0.045, decay=0.160, start=420.0, min=400.0,
                       slide=8.0, arp_mult=1.26, arp_speed=0.060, peak_db=-8.0, seed=47),
    "repair": dict(wave="square", duty=0.125, attack=0.0, sustain=0.006, decay=0.055, start=1650.0, min=1500.0,
                   slide=-5.0, highpass=500.0, peak_db=-9.0, seed=53),

    # --- Hitos ---
    "overload": dict(wave="square", duty=0.5, attack=0.0, sustain=0.120, decay=0.260, start=300.0, min=290.0,
                     slide=12.0, punch=0.20, noise_mix=0.25, peak_db=-7.0, seed=59),
    "portal_destroyed": dict(wave="noise", attack=0.005, sustain=0.060, decay=0.550, start=340.0, min=35.0,
                             slide=-2.5, punch=0.20, lowpass=1500.0, lowpass_sweep=-800.0, resonance=0.15,
                             seed=61),
    "boss_phase": dict(wave="square", duty=0.5, attack=0.0, sustain=0.100, decay=0.300, start=260.0, min=250.0,
                       slide=9.0, arp_mult=1.5, arp_speed=0.080, noise_mix=0.45, lowpass=2200.0,
                       peak_db=-6.0, seed=67),
    "player_death": dict(wave="noise", attack=0.0, sustain=0.030, decay=0.300, start=220.0, min=40.0,
                         slide=-3.0, punch=0.20, lowpass=520.0, peak_db=-6.0, seed=71),
    "respawn": dict(wave="sine", attack=0.004, sustain=0.060, decay=0.180, start=520.0, min=510.0,
                    slide=6.0, peak_db=-10.0, seed=73),

    # --- Interfaz: burbujas cortas (subida rápida y caída seca) ---
    "ui_click": dict(wave="sine", attack=0.001, sustain=0.006, decay=0.050, start=620.0, min=600.0,
                     slide=5.0, lowpass=3500.0, peak_db=-8.0, seed=79),
    "ui_hover": dict(wave="sine", attack=0.001, sustain=0.003, decay=0.028, start=900.0, min=880.0,
                     slide=3.0, lowpass=4000.0, peak_db=-20.0, seed=83),
    # Navegación con teclado: láser corto y tecnológico, no una burbuja.
    "ui_move": dict(wave="square", duty=0.125, attack=0.0, sustain=0.004, decay=0.038, start=1900.0,
                    min=300.0, slide=-28.0, highpass=500.0, peak_db=-10.0, seed=91),
    "ui_back": dict(wave="sine", attack=0.001, sustain=0.004, decay=0.045, start=560.0, min=540.0,
                    slide=-5.0, lowpass=3000.0, peak_db=-11.0, seed=89),

    # --- Voz de la novela visual (se desafina por personaje en el juego) ---
    "dialogue": dict(wave="square", duty=0.5, attack=0.0, sustain=0.010, decay=0.032, start=520.0, min=510.0,
                     lowpass=3200.0, highpass=220.0, peak_db=-10.0, seed=97),
}


GROUPS = {
    "combate": ["slash", "shot", "hit", "step", "dodge", "alarm", "upgrade", "destroy", "dash", "dash_caldera"],
    "economia": ["denied", "pickup", "build_order", "build_done", "repair"],
    "hitos": ["overload", "portal_destroyed", "boss_phase", "player_death", "respawn"],
    "interfaz": ["ui_click", "ui_hover", "ui_move", "ui_back"],
    "voz": ["dialogue"],
}


def main():
    for group, names in GROUPS.items():
        for name in names:
            data = render(PRESETS[name])
            path = save(group, name, data)
            print("%-9s %-21s %6.1f ms" % (group, name, len(data) / RATE * 1000.0))
    unused = [name for name in PRESETS if name not in sum(GROUPS.values(), [])]
    if unused:
        print("SIN CARPETA: " + ", ".join(unused))


if __name__ == "__main__":
    main()
