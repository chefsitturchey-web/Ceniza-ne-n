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


def render_rumble(spec):
    """Rumor continuo: sin envolvente de caída, pensado para durar todo un estado.

    La tierra moviéndose es ruido muy filtrado hacia abajo con temblor lento.
    """
    rng = np.random.default_rng(spec.get("seed", 1))
    seconds = spec.get("seconds", 2.0)
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    freq = spec["start"] * np.power(2.0, spec.get("slide", 0.0) * t)
    freq = np.clip(freq, spec.get("min", 30.0), RATE * 0.45)
    phase = np.cumsum(2.0 * np.pi * freq / RATE)
    data = oscillator(phase, "noise", 0.5, rng)
    data *= 1.0 + spec.get("tremolo", 0.0) * np.sin(2.0 * np.pi * spec.get("tremolo_rate", 5.0) * t)
    data = lowpass(data, spec["lowpass"], spec.get("lowpass_sweep", 0.0), spec.get("resonance", 0.0))
    if spec.get("highpass", 0.0) > 0.0:
        data = highpass(data, spec["highpass"])
    drive = spec.get("drive", 0.0)
    if drive > 0.0:
        data = np.tanh(data * drive) / np.tanh(drive)
    data = highpass(data, 20.0)
    # Cierre corto: si la embestida dura todo el archivo, no debe cortarse en seco.
    fade = min(len(data), int(0.03 * RATE))
    data[-fade:] *= np.linspace(1.0, 0.0, fade)
    peak = np.max(np.abs(data)) + 1e-9
    return data * 10.0 ** (spec.get("peak_db", -8.0) / 20.0) / peak


def render_sfxr(ps):
    """Port fiel del motor de jsfxr (sfxr.js), para presets en su escala 0-1.

    Se usa cuando el sonido viene de la web: traducir esos parámetros a Hz y
    segundos cambia el resultado, así que se reproduce el algoritmo original.
    """
    sample_rate = int(ps.get("sample_rate", 44100))
    rng = np.random.default_rng(int(ps.get("seed", 1)))
    oversampling = 8
    shape = int(ps.get("wave_type", 0))

    fltw = ps["p_lpf_freq"] ** 3 * 0.1
    enable_lpf = ps["p_lpf_freq"] != 1
    fltw_d = 1 + ps["p_lpf_ramp"] * 0.0001
    fltdmp = min(5 / (1 + ps["p_lpf_resonance"] ** 2 * 20) * (0.01 + fltw), 0.8)
    flthp = ps["p_hpf_freq"] ** 2 * 0.1
    flthp_d = 1 + ps["p_hpf_ramp"] * 0.0003

    vibrato_speed = ps["p_vib_speed"] ** 2 * 0.01
    vibrato_amplitude = ps["p_vib_strength"] * 0.5

    env_length = [int(ps["p_env_attack"] ** 2 * 100000),
                  int(ps["p_env_sustain"] ** 2 * 100000),
                  int(ps["p_env_decay"] ** 2 * 100000)]
    punch = ps["p_env_punch"]

    flanger_offset = ps["p_pha_offset"] ** 2 * 1020 * (-1 if ps["p_pha_offset"] < 0 else 1)
    flanger_slide = ps["p_pha_ramp"] ** 2 * (-1 if ps["p_pha_ramp"] < 0 else 1)

    gain = np.exp(ps.get("sound_vol", 0.25)) - 1

    period = 100 / (ps["p_base_freq"] ** 2 + 0.001)
    period_max = 100 / (ps["p_freq_limit"] ** 2 + 0.001)
    cutoff = ps["p_freq_limit"] > 0
    period_mult = 1 - ps["p_freq_ramp"] ** 3 * 0.01
    period_mult_slide = -ps["p_freq_dramp"] ** 3 * 0.000001
    duty = 0.5 - ps["p_duty"] * 0.5
    duty_slide = -ps["p_duty_ramp"] * 0.00005
    arpeggio = 1 - ps["p_arp_mod"] ** 2 * 0.9 if ps["p_arp_mod"] >= 0 else 1 + ps["p_arp_mod"] ** 2 * 10
    arpeggio_time = int((1 - ps["p_arp_speed"]) ** 2 * 20000 + 32)
    if ps["p_arp_speed"] == 1:
        arpeggio_time = 0

    fltp = fltdp = fltphp = 0.0
    noise = rng.uniform(-1.0, 1.0, 32)
    stage = 0
    elapsed_env = 0
    vibrato_phase = 0.0
    phase = 0.0
    ipp = 0
    flanger = np.zeros(1024)
    summands = max(1, int(44100 / sample_rate))
    sample_sum = 0.0
    num_summed = 0
    output = []

    for step in range(sample_rate * 4):
        if arpeggio_time != 0 and step >= arpeggio_time:
            arpeggio_time = 0
            period *= arpeggio

        period_mult += period_mult_slide
        period *= period_mult
        if period > period_max:
            period = period_max
            if cutoff:
                break

        rfperiod = period
        if vibrato_amplitude > 0:
            vibrato_phase += vibrato_speed
            rfperiod = period * (1 + np.sin(vibrato_phase) * vibrato_amplitude)
        iperiod = max(int(rfperiod), oversampling)

        duty += duty_slide
        duty = min(max(duty, 0.0), 0.5)

        elapsed_env += 1
        if elapsed_env > env_length[stage]:
            elapsed_env = 0
            stage += 1
            if stage > 2:
                break
        envf = elapsed_env / env_length[stage] if env_length[stage] > 0 else 1.0
        if stage == 0:
            env_vol = envf
        elif stage == 1:
            env_vol = 1 + (1 - envf) * 2 * punch
        else:
            env_vol = 1 - envf

        flanger_offset += flanger_slide
        iphase = min(abs(int(flanger_offset)), 1023)

        if flthp_d != 0:
            flthp *= flthp_d
            flthp = min(max(flthp, 0.00001), 0.1)

        sample = 0.0
        for _ in range(oversampling):
            phase += 1
            if phase >= iperiod:
                phase %= iperiod
                if shape == 3:
                    noise = rng.uniform(-1.0, 1.0, 32)
            fp = phase / iperiod
            if shape == 0:
                sub = 0.5 if fp < duty else -0.5
            elif shape == 1:
                sub = -1 + 2 * fp / duty if fp < duty else 1 - 2 * (fp - duty) / (1 - duty)
            elif shape == 2:
                sub = np.sin(fp * 2 * np.pi)
            else:
                sub = noise[int(phase * 32 / iperiod) % 32]

            previous = fltp
            fltw *= fltw_d
            fltw = min(max(fltw, 0.0), 0.1)
            if enable_lpf:
                fltdp += (sub - fltp) * fltw
                fltdp -= fltdp * fltdmp
            else:
                fltp = sub
                fltdp = 0.0
            fltp += fltdp

            fltphp += fltp - previous
            fltphp -= fltphp * flthp
            sub = fltphp

            flanger[ipp & 1023] = sub
            sub += flanger[(ipp - iphase + 1024) & 1023]
            ipp = (ipp + 1) & 1023
            sample += sub * env_vol

        sample_sum += sample
        num_summed += 1
        if num_summed < summands:
            continue
        sample = sample_sum / summands
        sample_sum = 0.0
        num_summed = 0
        sample = sample / oversampling * gain
        # Cuantización a 8 bits como el original, guardada luego en 16.
        quantized = min(max(np.floor((sample + 1.0) * 128.0), 0.0), 255.0)
        output.append(quantized / 128.0 - 1.0)

    data = np.array(output, dtype=np.float64)
    peak = np.max(np.abs(data)) + 1e-9
    return data * 10.0 ** (ps.get("peak_db", -6.0) / 20.0) / peak


def fft_band(values, low, high, rate=RATE):
    """Banda con bordes suaves en el dominio de la frecuencia (rápido y estable)."""
    n = len(values)
    spectrum = np.fft.rfft(values)
    freqs = np.fft.rfftfreq(n, 1.0 / rate)
    edge = max(low * 0.6, 20.0)
    top = max(high * 0.35, 20.0)
    weight = np.clip((freqs - (low - edge)) / edge, 0.0, 1.0)
    weight *= np.clip(((high + top) - freqs) / top, 0.0, 1.0)
    return np.fft.irfft(spectrum * weight, n)


def render_ambience(spec):
    """Colchón de ambiente en bucle: ruido filtrado con respiración lenta.

    No hay melodía ni eventos: solo textura, para que no canse en sesiones
    largas. El bucle se cierra cruzando la cola con el arranque.
    """
    seconds = spec.get("seconds", 16.0)
    n = int(seconds * RATE)
    time = np.arange(n) / RATE
    rng = np.random.default_rng(spec.get("seed", 1))
    mix = np.zeros(n)
    for layer in spec["layers"]:
        if layer.get("crackle"):
            impulses = np.zeros(n)
            count = max(1, int(layer["crackle"] * seconds))
            positions = rng.integers(0, n, count)
            impulses[positions] = rng.uniform(-1.0, 1.0, count)
            signal = fft_band(impulses, layer["low"], layer["high"])
        else:
            signal = fft_band(rng.uniform(-1.0, 1.0, n), layer["low"], layer["high"])
        period = layer.get("lfo", 0.0)
        amplitude = 1.0
        if period > 0:
            amplitude = 0.55 + 0.45 * np.sin(2.0 * np.pi * time / period + layer.get("phase", 0.0))
        mix += signal * amplitude * layer["gain"]

    # Cierre del bucle: la cola se mezcla con el arranque y se descarta.
    fade = min(n // 3, int(0.6 * RATE))
    ramp = np.linspace(0.0, 1.0, fade)
    mix[:fade] = mix[:fade] * ramp + mix[-fade:] * (1.0 - ramp)
    mix = mix[:-fade]
    mix = highpass(mix, 25.0)
    peak = np.max(np.abs(mix)) + 1e-9
    return mix * 10.0 ** (spec.get("peak_db", -20.0) / 20.0) / peak


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
    # Corte de espada: preset "laser shoot" de jsfxr, tal cual se descargó.
    # Va en parámetros de sfxr (0-1) y se reproduce con su propio motor.
    "slash": dict(peak_db=-6.0, sfxr={
        "wave_type": 3,
        "p_env_attack": 0, "p_env_sustain": 0.067, "p_env_punch": 0, "p_env_decay": 0.514,
        "p_base_freq": 0.647, "p_freq_limit": 0.192, "p_freq_ramp": -0.067, "p_freq_dramp": -0.506,
        "p_vib_strength": 0, "p_vib_speed": 0,
        "p_arp_mod": -0.145, "p_arp_speed": 0,
        "p_duty": 0, "p_duty_ramp": -0.5036802108433026,
        "p_repeat_speed": 0,
        "p_pha_offset": 0.09, "p_pha_ramp": 0.027,
        "p_lpf_freq": 0.153, "p_lpf_ramp": 0.137, "p_lpf_resonance": 1,
        "p_hpf_freq": 1, "p_hpf_ramp": 1,
        "sound_vol": 0.25, "sample_rate": 44100, "sample_size": 8,
    }),
    # Láser: barrido descendente rápido y seco.
    "shot": dict(wave="square", duty=0.5, attack=0.0, sustain=0.008, decay=0.060, start=2400.0,
                 min=220.0, slide=-30.0, punch=0.10, highpass=400.0, seed=11),
    "hit": dict(wave="noise", attack=0.0, sustain=0.004, decay=0.055, start=900.0, min=80.0,
                slide=-22.0, punch=0.30, lowpass=1400.0, resonance=0.1, seed=13),
    "step": dict(wave="noise", attack=0.0, sustain=0.002, decay=0.018, start=500.0, min=180.0,
                 slide=-10.0, lowpass=900.0, seed=17),
    "dodge": dict(wave="square", duty=0.25, attack=0.005, sustain=0.030, decay=0.080, start=680.0, min=140.0,
                  slide=-6.0, punch=0.10, lowpass=2600.0, seed=19),
    # Embestida de jefe: rumor de tierra que dura todo el desplazamiento.
    # Sin envolvente: el juego lo arranca al cargar y lo corta al terminar.
    "dash": dict(seconds=2.2, start=240.0, min=40.0, slide=-1.2, lowpass=420.0, resonance=0.28,
                 highpass=70.0, tremolo=0.35, tremolo_rate=5.5, drive=2.2, peak_db=-8.0, seed=101),
    # La misma embestida para Santa Caldera: más grave, más pesada, más lenta.
    "dash_caldera": dict(seconds=2.2, start=170.0, min=28.0, slide=-1.6, lowpass=320.0, resonance=0.32,
                         highpass=55.0, tremolo=0.45, tremolo_rate=4.2, drive=3.0, peak_db=-7.0, seed=103),
    # Ola de sonar: ruido que se abre con un golpe de volumen y se apaga.
    "sonar": dict(wave="noise", attack=0.220, sustain=0.180, decay=0.500, start=900.0, min=120.0,
                  slide=-3.0, lowpass=1400.0, lowpass_sweep=800.0, resonance=0.15, highpass=150.0,
                  drive=1.8, peak_db=-8.0, seed=107),
    # Escudo que rebota: misma receta que el slash (ruido con filtro resonante),
    # algo más agudo y más largo para leerse como un rebote y no como un tajo.
    "shield": dict(peak_db=-10.0, sfxr={
        "wave_type": 3,
        "p_env_attack": 0, "p_env_sustain": 0.04, "p_env_punch": 0, "p_env_decay": 0.30,
        "p_base_freq": 0.85, "p_freq_limit": 0.35, "p_freq_ramp": -0.09, "p_freq_dramp": -0.35,
        "p_vib_strength": 0, "p_vib_speed": 0,
        "p_arp_mod": -0.145, "p_arp_speed": 0,
        "p_duty": 0, "p_duty_ramp": -0.5036802108433026,
        "p_repeat_speed": 0,
        "p_pha_offset": 0.05, "p_pha_ramp": 0.02,
        "p_lpf_freq": 0.22, "p_lpf_ramp": 0.137, "p_lpf_resonance": 1,
        "p_hpf_freq": 1, "p_hpf_ramp": 1,
        "sound_vol": 0.25, "sample_rate": 44100, "sample_size": 8,
    }),
    # Pulso de fuego: ráfaga con cuerpo y crepitar, más brillante que la caldera.
    "fire_pulse": dict(wave="noise", attack=0.004, sustain=0.050, decay=0.280, start=700.0, min=60.0,
                       slide=-3.5, punch=0.20, lowpass=2400.0, lowpass_sweep=-900.0, resonance=0.25,
                       highpass=120.0, drive=2.6, peak_db=-7.0, seed=113),
    # Telegrafiados: tres avisos cortos y bien distintos entre sí, para no
    # tapar el ataque con el klaxon largo de la alarma.
    "telegraph_claw": dict(wave="noise", attack=0.002, sustain=0.012, decay=0.100, start=2200.0,
                           min=300.0, slide=-14.0, lowpass=4500.0, lowpass_sweep=-3000.0,
                           highpass=700.0, drive=1.8, peak_db=-8.0, seed=127),
    "telegraph_charge": dict(wave="noise", attack=0.010, sustain=0.090, decay=0.220, start=500.0,
                             min=60.0, slide=-2.0, lowpass=900.0, lowpass_sweep=400.0,
                             highpass=60.0, drive=2.4, peak_db=-7.0, seed=131),
    "telegraph_volley": dict(wave="square", duty=0.25, attack=0.001, sustain=0.020, decay=0.120,
                             start=1600.0, min=400.0, slide=-6.0, noise_mix=0.30, highpass=900.0,
                             lowpass=5000.0, peak_db=-8.0, seed=137),
    # Muralla que se derrumba: más larga y grave que la muerte de un enemigo.
    "wall_destroy": dict(wave="noise", attack=0.004, sustain=0.060, decay=0.550, start=700.0, min=35.0,
                         slide=-2.5, punch=0.25, lowpass=1400.0, lowpass_sweep=-700.0, resonance=0.20,
                         highpass=70.0, drive=2.8, peak_db=-6.0, seed=139),
    # Disparo de artillero: golpe de mortero con caída.
    "artillery_shot": dict(wave="noise", attack=0.002, sustain=0.020, decay=0.200, start=900.0, min=80.0,
                           slide=-12.0, punch=0.15, lowpass=2000.0, lowpass_sweep=-1200.0, highpass=200.0,
                           drive=2.0, peak_db=-8.0, seed=149),
    # Saboteador golpeando una instalación: chapa metálica.
    "saboteur_hit": dict(wave="square", duty=0.125, attack=0.001, sustain=0.010, decay=0.120, start=1200.0,
                         min=300.0, slide=-8.0, noise_mix=0.40, highpass=600.0, lowpass=4000.0,
                         peak_db=-8.0, seed=151),
    # Energía de torreta: sube al encender, cae al apagar.
    "turret_on": dict(wave="square", duty=0.25, attack=0.002, sustain=0.050, decay=0.150, start=300.0,
                      min=290.0, slide=8.0, lowpass=2500.0, peak_db=-9.0, seed=157),
    "turret_off": dict(wave="square", duty=0.25, attack=0.002, sustain=0.040, decay=0.130, start=600.0,
                       min=200.0, slide=-8.0, lowpass=2500.0, peak_db=-9.0, seed=163),
    # Tren entrando a la estación: rumor largo, sin ataque.
    "train_arrive": dict(wave="noise", attack=0.120, sustain=0.400, decay=0.580, start=280.0, min=45.0,
                         slide=-0.8, lowpass=700.0, lowpass_sweep=300.0, highpass=50.0, drive=2.2,
                         peak_db=-8.0, seed=167),
    # Reclutar a alguien en el campamento.
    "recruit": dict(wave="sine", attack=0.002, sustain=0.030, decay=0.120, start=520.0, min=500.0,
                    slide=4.0, arp_mult=1.5, arp_speed=0.080, peak_db=-9.0, seed=173),
    # Comprar una herramienta en el taller.
    "purchase": dict(wave="square", duty=0.5, attack=0.0, sustain=0.020, decay=0.090, start=980.0,
                     min=960.0, arp_mult=1.5, arp_speed=0.045, highpass=300.0, peak_db=-8.0, seed=179),
    # Amanecer: campana suave que separa la noche del día.
    "phase_dawn": dict(wave="sine", attack=0.005, sustain=0.100, decay=0.600, start=660.0, min=650.0,
                       lowpass=3000.0, peak_db=-12.0, seed=181),
    # Dron de escolta disparando: ráfaga corta con caída.
    "sentinel_shot": dict(wave="noise", attack=0.002, sustain=0.015, decay=0.150, start=1400.0, min=200.0,
                          slide=-14.0, punch=0.15, lowpass=3200.0, lowpass_sweep=-1800.0, highpass=300.0,
                          drive=2.0, peak_db=-9.0, seed=223),
    # Dron abriéndose: mecánica que sube antes de fijar puntería.
    "sentinel_deploy": dict(wave="square", duty=0.25, attack=0.004, sustain=0.060, decay=0.180, start=260.0,
                            min=250.0, slide=6.0, arp_mult=1.4, arp_speed=0.090, lowpass=2600.0,
                            peak_db=-10.0, seed=227),
    # Impacto de marca en el suelo: grave, con escombros.
    "ground_impact": dict(wave="noise", attack=0.003, sustain=0.030, decay=0.420, start=420.0, min=35.0,
                          slide=-3.0, punch=0.25, lowpass=1100.0, lowpass_sweep=-500.0, resonance=0.15,
                          highpass=55.0, drive=2.6, peak_db=-7.0, seed=229),
    # Cobertura de arena que se rompe: caja o bidón, no muralla.
    "cover_break": dict(wave="noise", attack=0.002, sustain=0.020, decay=0.240, start=900.0, min=80.0,
                        slide=-8.0, punch=0.20, lowpass=2600.0, lowpass_sweep=-1500.0, highpass=180.0,
                        drive=2.2, peak_db=-8.0, seed=233),
    # Rata: chillido corto y agudo.
    "rat_squeak": dict(wave="square", duty=0.125, attack=0.001, sustain=0.008, decay=0.060, start=2400.0,
                       min=900.0, slide=-10.0, vibrato=0.8, vibrato_speed=22.0, highpass=900.0,
                       peak_db=-12.0, seed=239),
    # Rata royendo cable: dos mordiscos cortos, para repetir.
    "rat_chew": dict(wave="noise", attack=0.001, sustain=0.010, decay=0.070, start=1600.0, min=400.0,
                     slide=-6.0, lowpass=3200.0, highpass=700.0, drive=1.6, peak_db=-12.0, seed=241),
    # Trampa cerrándose: metal seco y muy corto.
    "trap_snap": dict(wave="square", duty=0.125, attack=0.0, sustain=0.004, decay=0.050, start=1800.0,
                      min=300.0, slide=-20.0, noise_mix=0.45, highpass=900.0, peak_db=-8.0, seed=251),
    # Pala enterrando: tierra, sorda y corta.
    "corpse_bury": dict(wave="noise", attack=0.008, sustain=0.040, decay=0.220, start=380.0, min=60.0,
                        slide=-4.0, lowpass=900.0, lowpass_sweep=-300.0, highpass=90.0, drive=1.6,
                        peak_db=-12.0, seed=257),
    # Despejar escombros: piedra que se corre.
    "debris_clear": dict(wave="noise", attack=0.004, sustain=0.050, decay=0.300, start=600.0, min=60.0,
                         slide=-5.0, punch=0.15, lowpass=1800.0, lowpass_sweep=-900.0, highpass=120.0,
                         drive=2.0, peak_db=-10.0, seed=263),
    # Recoger piezas: tintineo metálico, distinto de la chatarra.
    "parts_pickup": dict(wave="square", duty=0.125, attack=0.0, sustain=0.010, decay=0.100, start=1500.0,
                         min=1400.0, arp_mult=1.335, arp_speed=0.050, highpass=700.0, peak_db=-9.0, seed=269),
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


AMBIENCE = {
    # Periferia: viento sobre chapa y escombros.
    "amb_periferia": dict(seconds=16.0, peak_db=-20.0, seed=191, layers=[
        dict(low=200.0, high=900.0, gain=0.55, lfo=8.0),
        dict(low=900.0, high=2600.0, gain=0.18, lfo=5.3, phase=1.1),
        dict(low=40.0, high=120.0, gain=0.30, lfo=4.0, phase=2.3),
    ]),
    # Fundición: rugido de horno y crepitar de escoria.
    "amb_fundicion": dict(seconds=16.0, peak_db=-20.0, seed=193, layers=[
        dict(low=60.0, high=300.0, gain=0.55, lfo=4.0),
        dict(low=400.0, high=1200.0, gain=0.14, lfo=2.7, phase=0.8),
        dict(low=1500.0, high=5000.0, gain=0.05, crackle=6.0),
    ]),
    # Barrio inundado: agua quieta y goteos dispersos.
    "amb_inundado": dict(seconds=16.0, peak_db=-20.0, seed=197, layers=[
        dict(low=100.0, high=600.0, gain=0.45, lfo=5.3),
        dict(low=1500.0, high=4000.0, gain=0.10, lfo=3.2, phase=1.7),
        dict(low=900.0, high=2600.0, gain=0.07, crackle=1.5),
    ]),
    # Ciudadela: aire acondicionado, casi sin movimiento.
    "amb_ciudadela": dict(seconds=16.0, peak_db=-22.0, seed=199, layers=[
        dict(low=80.0, high=400.0, gain=0.42, lfo=16.0),
        dict(low=900.0, high=1800.0, gain=0.09, lfo=16.0, phase=2.0),
    ]),
    # Núcleo: zumbido eléctrico y pulsos de datos.
    "amb_red": dict(seconds=16.0, peak_db=-20.0, seed=211, layers=[
        dict(low=50.0, high=150.0, gain=0.30, lfo=8.0),
        dict(low=300.0, high=1200.0, gain=0.22, lfo=2.0),
        dict(low=3000.0, high=7000.0, gain=0.06, crackle=12.0),
    ]),
}

GROUPS = {
    "combate": ["slash", "shot", "hit", "step", "dodge", "alarm", "upgrade", "destroy", "dash", "dash_caldera",
                "sonar", "shield", "fire_pulse", "telegraph_claw", "telegraph_charge", "telegraph_volley",
                "wall_destroy", "artillery_shot", "saboteur_hit", "turret_on", "turret_off",
                "sentinel_shot", "sentinel_deploy", "ground_impact", "cover_break"],
    "economia": ["denied", "pickup", "build_order", "build_done", "repair", "recruit", "purchase",
                 "debris_clear", "parts_pickup"],
    "hitos": ["overload", "portal_destroyed", "boss_phase", "player_death", "respawn", "train_arrive", "phase_dawn"],
    "plagas": ["rat_squeak", "rat_chew", "trap_snap", "corpse_bury"],
    "interfaz": ["ui_click", "ui_hover", "ui_move", "ui_back"],
    "voz": ["dialogue"],
}


def main():
    for group, names in GROUPS.items():
        for name in names:
            spec = PRESETS[name]
            if "amb" in spec:
                data = render_ambience(dict(spec["amb"], peak_db=spec.get("peak_db", -20.0)))
            elif "sfxr" in spec:
                data = render_sfxr(dict(spec["sfxr"], peak_db=spec.get("peak_db", -6.0)))
            elif "seconds" in spec:
                data = render_rumble(spec)
            else:
                data = render(spec)
            path = save(group, name, data)
            print("%-9s %-21s %6.1f ms" % (group, name, len(data) / RATE * 1000.0))
    for name, spec in AMBIENCE.items():
        data = render_ambience(spec)
        save("ambiente", name, data)
        print("%-9s %-21s %6.1f ms" % ("ambiente", name, len(data) / RATE * 1000.0))
    unused = [name for name in PRESETS if name not in sum(GROUPS.values(), [])]
    if unused:
        print("SIN CARPETA: " + ", ".join(unused))


if __name__ == "__main__":
    main()
