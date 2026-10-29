"""Convierte los MP3 entregados por el generador externo a OGG para Godot.

Recorta solo el silencio de ataque del encoder (entre 5 y 50 ms) y escribe el
.import con el bucle ya configurado. No cambia velocidad, tono, mezcla ni nivel.

Requiere numpy, soundfile y ffmpeg en el PATH (o imageio-ffmpeg instalado).
"""
import hashlib
import os
import pathlib
import shutil
import subprocess
import sys

import numpy as np
import soundfile as sf

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "musica"
DST = ROOT / "assets" / "audio" / "music"
FLOOR = 10 ** (-55 / 20.0)
MAX_LEAD_TRIM = 0.05

# (origen en musica/, destino en assets/audio/music/, bucle)
TRACKS = [
    ("Menu.mp3", "menu.ogg", True),
    ("principio.mp3", "colonia_dia.ogg", True),
    ("colonia_asedio.mp3", "colonia_noche.ogg", True),
    ("aviso.mp3", "aviso.ogg", True),
    ("zona_fundicion.mp3", "zona_fundicion.ogg", True),
    ("zona_fundicion-2.mp3", "zona_fundicion_b.ogg", True),
    ("zona_inundado.mp3", "zona_inundado.ogg", True),
    ("zona_ciudadela.mp3", "zona_ciudadela.ogg", True),
    ("zona_red.mp3", "zona_red.ogg", True),
    ("zona_red-2.mp3", "zona_red_b.ogg", True),
    ("jefe_recaudador.mp3", "jefe_recaudador.ogg", True),
    ("jefe_caldera.mp3", "jefe_caldera.ogg", True),
    ("jefe_caldera-2.mp3", "jefe_caldera_b.ogg", True),
    ("jefe_prefecto.mp3", "jefe_prefecto.ogg", True),
    ("jefe_prefecto-2.mp3", "jefe_prefecto_b.ogg", True),
    ("jefe_madrecero.mp3", "jefe_madrecero.ogg", True),
    ("boos_figth.mp3", "jefe_alt_1.ogg", True),
    ("boos_figth-2.mp3", "jefe_alt_2.ogg", True),
    ("boos_figth-3.mp3", "jefe_alt_3.ogg", True),
    ("win.mp3", "victoria.ogg", False),
    ("lost.mp3", "derrota.ogg", False),
]


def ffmpeg_path():
    found = shutil.which("ffmpeg")
    if found:
        return found
    try:
        import imageio_ffmpeg

        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        return ""


def lead_silence(path):
    """Duracion del silencio inicial, en segundos."""
    data, rate = sf.read(str(path), always_2d=True, dtype="float32")
    loudest = np.abs(data).max(axis=1)
    active = np.where(loudest > FLOOR)[0]
    if active.size == 0:
        return 0.0, len(data) / rate
    return float(active[0]) / rate, len(data) / rate


def write_import(name, loop):
    source = "res://assets/audio/music/" + name
    digest = hashlib.md5(source.encode()).hexdigest()
    dest = "res://.godot/imported/%s-%s.oggvorbisstr" % (name, digest)
    text = (
        '[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\n'
        'path="%s"\n\n[deps]\n\nsource_file="%s"\ndest_files=["%s"]\n\n'
        "[params]\n\nloop=%s\nloop_offset=0\nbpm=0\nbeat_count=0\nbar_beats=0\n"
        % (dest, source, dest, "true" if loop else "false")
    )
    (DST / (name + ".import")).write_text(text, encoding="utf-8")


def main():
    binary = ffmpeg_path()
    if not binary:
        raise SystemExit("Falta ffmpeg en el PATH.")
    DST.mkdir(parents=True, exist_ok=True)
    missing = []
    for source, target, loop in TRACKS:
        origin = SRC / source
        if not origin.exists():
            missing.append(source)
            continue
        lead, total = lead_silence(origin)
        arguments = [binary, "-hide_banner", "-loglevel", "error", "-y"]
        if 0.005 < lead < MAX_LEAD_TRIM:
            arguments += ["-ss", "%.4f" % lead]
        arguments += ["-i", str(origin), "-c:a", "libvorbis", "-q:a", "6", str(DST / target)]
        subprocess.run(arguments, check=True)
        write_import(target, loop)
        print("%-26s %6.2fs  recorte %.3fs  loop=%s" % (source, total, lead if 0.005 < lead < MAX_LEAD_TRIM else 0.0, loop))
    if missing:
        print("FALTAN: " + ", ".join(missing))


if __name__ == "__main__":
    main()
