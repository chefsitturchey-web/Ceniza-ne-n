"""Integra los cuadros del Artillero generados con PixelLab (64x64, perfil hacia la derecha).

Fuentes en assets/characters/enemies/sources/pixellab_artillero/{base2.png,walk,attack,death}
(indice 0 = pose de referencia, 1..8 = generados). Escribe assets/characters/enemies/artillero/<anim>/
y entities/enemies/artillero_frames.tres. El daño se compone por codigo desde la base
(destello blanco, tinte rojo y retroceso de 1-2 px). Uso: python tools/art/integrar_artillero_pixellab.py
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets/characters/enemies/sources/pixellab_artillero"
OUT = ROOT / "assets/characters/enemies/artillero"
BASE = Image.open(SRC / "base2.png").convert("RGBA")


def load(folder: str, index: int) -> Image.Image:
    return Image.open(SRC / folder / f"{index}.png").convert("RGBA")


def shifted(img: Image.Image, dx: int, dy: int = 0) -> Image.Image:
    out = Image.new("RGBA", img.size)
    out.alpha_composite(img, (dx, dy))
    return out


def tint(img: Image.Image, colour: tuple, amount: float) -> Image.Image:
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = tuple(int(c + (t - c) * amount) for c, t in zip((r, g, b), colour)) + (a,)
    return out


def breathe(img: Image.Image) -> Image.Image:
    out = img.crop((0, 40, 64, 64))
    canvas = Image.new("RGBA", img.size)
    canvas.alpha_composite(out, (0, 40))
    canvas.alpha_composite(img.crop((0, 0, 64, 40)), (0, 1))
    return canvas


# nombre: (cuadros, [duracion por cuadro], velocidad, bucle)
ANIMS = {
    "reposo": ([BASE, breathe(BASE), breathe(BASE), BASE], [1, 1, 1, 1], 6.0, True),
    "caminar": ([load("walk", i) for i in range(1, 9)], [1] * 8, 8.0, True),
    # Arma lista y se mantiene; el fogonazo llega al final de la preparacion (0.9 s).
    "ataque": ([load("attack", i) for i in (0, 1, 2, 3, 4)], [3, 14, 1, 1, 1], 10.0, False),
    "daño": ([tint(BASE, (255, 255, 255), 1.0), tint(shifted(BASE, -2), (230, 50, 40), 0.55),
              tint(shifted(BASE, -1), (230, 50, 40), 0.35), shifted(BASE, -1), BASE, BASE], [1] * 6, 10.0, False),
    "destruccion": ([load("death", i) for i in range(0, 9)], [1] * 9, 10.0, False),
}
FOLDER = {"daño": "dano"}


def main() -> None:
    ext, anims, next_id = [], [], 1
    for name, (frames, durations, speed, loop) in ANIMS.items():
        folder = FOLDER.get(name, name)
        (OUT / folder).mkdir(parents=True, exist_ok=True)
        entries = []
        for i, frame in enumerate(frames):
            rel = f"{folder}/{folder}_{i:02d}.png"
            frame.save(OUT / rel)
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/characters/enemies/artillero/{rel}" id="{next_id}"]')
            entries.append('{\n"duration": %.1f,\n"texture": ExtResource("%d")\n}' % (durations[i], next_id))
            next_id += 1
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                     % (", ".join(entries), "true" if loop else "false", name, speed))
    text = "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n%s\n\n[resource]\nanimations = [%s]\n" % (
        next_id, "\n".join(ext), ", ".join(anims))
    (ROOT / "entities/enemies/artillero_frames.tres").write_text(text, encoding="utf-8")
    print("Artillero integrado:", next_id - 1, "cuadros")


if __name__ == "__main__":
    main()
