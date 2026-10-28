"""Recorta el paquete CC0 de Kenney para que las acciones no dejen colas de 5 s.

Uso: python tools/preparar_sonidos.py [ruta/al/sci-fi_sounds.zip]
Fuente: https://opengameart.org/content/sci-fi-sounds
Requiere FFmpeg. Extrae y procesa solo los siete clips utilizados.
"""
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIPS = {
    "slash": ("forceField_000.ogg", .28),
    "shot": ("laserSmall_000.ogg", .24),
    "hit": ("impactMetal_000.ogg", .42),
    "dodge": ("thrusterFire_000.ogg", .22),
    "alarm": ("computerNoise_000.ogg", .65),
    "upgrade": ("computerNoise_003.ogg", .7),
    "destroy": ("explosionCrunch_000.ogg", .78),
}


def main():
    archive = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / ".godot/audio-source/kenney.zip"
    if not archive.is_file():
        raise SystemExit("Descarga Sci-Fi Sounds de Kenney y pasa la ruta del ZIP como argumento.")
    temp = ROOT / ".godot/audio-source/selected"
    target = ROOT / "assets/audio/sfx"
    temp.mkdir(parents=True, exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as source:
        for cue, (filename, duration) in CLIPS.items():
            entry = next(name for name in source.namelist() if Path(name).name == filename)
            clip = temp / filename
            clip.write_bytes(source.read(entry))
            fade = min(.06, duration / 4)
            filters = f"afade=t=in:st=0:d=0.003,afade=t=out:st={duration - fade}:d={fade}"
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(clip),
                            "-t", str(duration), "-af", filters, "-ar", "44100", "-ac", "1",
                            "-c:a", "libvorbis", "-q:a", "6", str(target / f"{cue}.ogg")], check=True)
            print(f"{cue}: {filename}, máximo {duration}s")


if __name__ == "__main__":
    main()
