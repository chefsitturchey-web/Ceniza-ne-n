"""Reconstruye las hojas de El Prefecto y Madre Cero cuadro por cuadro, sin deformar mallas.

Cada celda de 320 px de prefecto.png y madre.png se compone con poses pintadas reales:
- references/<actor>.png (12 poses x 4 vistas) y references/prefecto_attack.png (4 x 4),
  reducidas una sola vez a la altura del cuerpo y con alfa binaria (pixel nitido).
- Animaciones cuadro por cuadro de PixelLab en sources/pixellab_<actor>/<clip>/
  (indice 0 = pose de entrada, 1..8 = generados) recortadas en CROP de la celda.
Las vistas sin clip generado reutilizan poses pintadas con pausas honestas; el oeste
generado es el este espejado. Nunca se rota ni se estira la imagen.

Uso:
  python tools/art/integrar_jefes_pixellab.py --entradas   # escribe las poses 0.png para PixelLab
  python tools/art/integrar_jefes_pixellab.py              # integra todo en las hojas
"""
import argparse
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/characters/combat"
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_illustrated_combat import measure  # noqa: E402

CELL = 320
# Celda final: el arte se reduce una vez a la escala real de pantalla (camara de la arena a 0.75)
# y se dibuja a RENDER_SCALE, de modo que cada texel ocupa exactamente un pixel del SubViewport.
FINAL_CELL = 144
CAMERA_ZOOM = 0.75
DIRECTIONS = ["south", "east", "north", "west"]
ACTORS = {
    # altura del cuerpo en reposo (px de celda), ancla de los pies, recorte usado con PixelLab
    "prefecto": {"height": 116, "anchor": (160, 228), "crop": (48, 40, 224)},
    "madre": {"height": 144, "anchor": (160, 196), "crop": (48, 4, 224)},
}
# Poses de la hoja base: 0 reposo, 1-4 paso, 5-6 preparacion, 7 golpe, 8 recuperacion,
# 9 dolor, 10 rodilla, 11 caido. "a0".."a3" son poses de prefecto_attack.png.
# Reposo y aturdimiento respiran bajando 1 px la pose entera en los cuadros 2-4 (sin deformar).
PLAN = {
    "prefecto": {
        "idle": [0, 0, 0, 0, 0, 0], "walk": [1, 1, 2, 2, 3, 3, 4, 4],
        "windup": [0, "a0", "a0", "a1", "a1", "a1"], "attack": ["a2", "a2", "a2", "a3", "a3", "a3", 8, 0],
        "shoot": [0, 5, 6, 7, 8, 0], "charge": [1, 2, 3, 4, 1, 3], "exposed": [8, 8, 8, 8, 8, 8],
        "hurt": [0, 9, 9, 0], "death": [9, 9, 10, 10, 10, 11, 11, 11], "dodge": [0, 9, 10, 9, 0, 0],
    },
    "madre": {
        "idle": [0, 0, 0, 0, 0, 0], "walk": [1, 1, 2, 2, 3, 3, 4, 4],
        "windup": [0, 0, 5, 5, 6, 6], "attack": [7, 7, 7, 8, 8, 8, 0, 0],
        "shoot": [0, 5, 6, 7, 8, 0], "charge": [1, 2, 3, 4, 1, 3], "exposed": [9, 9, 9, 9, 9, 9],
        "hurt": [0, 9, 9, 0], "death": [9, 9, 10, 10, 10, 11, 11, 11], "dodge": [0, 9, 10, 9, 0, 0],
    },
}
# Clips generados con PixelLab: (actor, carpeta) -> {clip: cuadros}. "<carpeta>" usa la vista de la
# carpeta y, si es este, tambien el oeste espejado.
GENERATED = {
    "prefecto": {
        "idle_south": {"idle": [1, 2, 3, 4, 5, 6]},
        "attack_east": {"windup": [0, 1, 2, 3, 4, 4], "attack": [5, 5, 6, 6, 7, 8, 8, 8]},
        # La estela del tajo (cuadro 2) cierra la preparación: el impacto empieza con el filo abajo.
        "attack_south": {"windup": ["p:0", "p:a0", 0, 1, 1, 2], "attack": [3, 3, 4, 4, 5, 6, 8, 8]},
        "death_east": {"death": [1, 2, 3, 4, 5, 6, 7, 8]},
    },
    "madre": {
        "idle_south": {"idle": [1, 2, 3, 4, 5, 6]},
        "attack_east": {"windup": [0, 1, 2, 3, 4, 4], "attack": [8, 8, 8, 8, 5, 6, 7, 7]},
        "death_east": {"death": [1, 2, 3, 4, 5, 6, 7, 8]},
    },
}
# Pose inicial (y final opcional) de cada clip generado, enviadas a PixelLab.
INPUTS = {
    "prefecto": {"idle_south": ("south", 0, 0), "attack_east": ("east", "a1", "a2"),
                 "attack_south": ("south", "a1", "a2"), "death_east": ("east", 9, 11)},
    "madre": {"idle_south": ("south", 0, 0), "attack_east": ("east", 5, 7), "death_east": ("east", 9, 11)},
}


def crisp(image: Image.Image) -> Image.Image:
    """Alfa binaria: bordes de pixel limpios sobre cualquier fondo."""
    alpha = image.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    image.putalpha(alpha)
    return image


def foot_x(image: Image.Image) -> float:
    """Centro horizontal de los pies: media del alfa en el 20 % inferior de la silueta."""
    box = image.getbbox()
    band = image.getchannel("A").crop((0, box[3] - max(4, (box[3] - box[1]) // 5), image.width, box[3]))
    xs = [x for x, v in enumerate(band.getprojection()[0]) if v]
    return (min(xs) + max(xs)) / 2 if xs else (box[0] + box[2]) / 2


class Poses:
    def __init__(self, actor: str) -> None:
        self.actor = actor
        self.info = ACTORS[actor]
        self.sheets = {"base": (ART / "references" / f"{actor}.png", 12)}
        attack = ART / "references" / f"{actor}_attack.png"
        if attack.exists():
            self.sheets["attack"] = (attack, 4)
        self.cache: dict = {}
        self.measure = {name: measure(path, columns) for name, (path, columns) in self.sheets.items()}
        self.images = {name: Image.open(path).convert("RGBA") for name, (path, _c) in self.sheets.items()}

    def scale(self, sheet: str, row: int) -> float:
        # Escala unica por vista: la pose de reposo de cada hoja mide lo mismo que el cuerpo del juego.
        box = self.measure[sheet]["rows"][row][0]
        return self.info["height"] / (box[3] - box[1])

    def cell(self, direction: str, pose) -> Image.Image:
        key = (direction, pose)
        if key in self.cache:
            return self.cache[key]
        sheet, index = ("attack", int(pose[1])) if isinstance(pose, str) else ("base", pose)
        row = DIRECTIONS.index(direction)
        box = self.measure[sheet]["rows"][row][index]
        figure = self.images[sheet].crop(tuple(box))
        factor = self.scale(sheet, row)
        size = (max(1, round(figure.width * factor)), max(1, round(figure.height * factor)))
        figure = crisp(figure.resize(size, Image.LANCZOS))
        out = Image.new("RGBA", (CELL, CELL))
        ax, ay = self.info["anchor"]
        out.alpha_composite(figure, (round(ax - foot_x(figure)), ay - figure.height))
        self.cache[key] = out
        return out


def pose_frames(poses: Poses, clip: str, direction: str) -> list:
    picks = PLAN[poses.actor][clip]
    frames = []
    for slot, pose in enumerate(picks):
        image = poses.cell(direction, pose)
        if clip in ("idle", "exposed") and 2 <= slot <= 4:
            shifted = Image.new("RGBA", (CELL, CELL))
            shifted.alpha_composite(image, (0, 1))
            image = shifted
        frames.append(image)
    return frames


def generated_cell(actor: str, folder: str, index: int, mirror: bool) -> Image.Image:
    x, y, _size = ACTORS[actor]["crop"]
    frame = crisp(Image.open(ART / "sources" / f"pixellab_{actor}" / folder / f"{index}.png").convert("RGBA"))
    cell = Image.new("RGBA", (CELL, CELL))
    cell.alpha_composite(frame, (x, y))
    return cell.transpose(Image.FLIP_LEFT_RIGHT) if mirror else cell


def write_inputs() -> None:
    for actor, clips in INPUTS.items():
        poses = Poses(actor)
        x, y, size = ACTORS[actor]["crop"]
        for folder, (direction, first, last) in clips.items():
            target = ART / "sources" / f"pixellab_{actor}" / folder
            target.mkdir(parents=True, exist_ok=True)
            poses.cell(direction, first).crop((x, y, x + size, y + size)).save(target / "0.png")
            poses.cell(direction, last).crop((x, y, x + size, y + size)).save(target / "final.png")
            print("entrada", actor, folder)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--entradas", action="store_true")
    args = parser.parse_args()
    if args.entradas:
        write_inputs()
        return
    layout = json.loads((ART / "layout.json").read_text(encoding="utf-8"))
    for actor in ACTORS:
        poses = Poses(actor)
        sheet = Image.new("RGBA", (CELL * 8, CELL * 32))
        generated = 0
        for direction in DIRECTIONS:
            for clip in PLAN[actor]:
                frames = pose_frames(poses, clip, direction)
                for folder, clips in GENERATED[actor].items():
                    source_direction = folder.split("_")[1]
                    if clip not in clips or not (ART / "sources" / f"pixellab_{actor}" / folder / "8.png").exists():
                        continue
                    if direction == source_direction or (source_direction == "east" and direction == "west"):
                        # "p:<pose>" intercala una pose pintada de la misma vista.
                        frames = [poses.cell(direction, i[2:] if i[2:].startswith("a") else int(i[2:])) if isinstance(i, str)
                                  else generated_cell(actor, folder, i, direction == "west") for i in clips[clip]]
                        generated += 1
                for slot, image in zip(layout["animations"][f"{clip}_{direction}"]["frames"], frames):
                    sheet.alpha_composite(image, (slot % 8 * CELL, slot // 8 * CELL))
        final = Image.new("RGBA", (FINAL_CELL * 8, FINAL_CELL * 32))
        for index in range(256):
            cell = sheet.crop((index % 8 * CELL, index // 8 * CELL, index % 8 * CELL + CELL, index // 8 * CELL + CELL))
            final.alpha_composite(crisp(cell.resize((FINAL_CELL, FINAL_CELL), Image.LANCZOS)), (index % 8 * FINAL_CELL, index // 8 * FINAL_CELL))
        final.save(ART / f"{actor}.png")
        ratio = FINAL_CELL / CELL
        info = layout["actors"][actor]
        info["cell"] = FINAL_CELL
        info["anchor"] = [round(v * ratio) for v in ACTORS[actor]["anchor"]]
        info["render_scale"] = round(1 / CAMERA_ZOOM, 4)
        info["idle_body_bounds"] = list(final.crop((0, 0, FINAL_CELL, FINAL_CELL)).getbbox())
        info["locomotion"] = "painted_keys_pixellab"
        print(f"{actor}.png actualizado; {generated} clips generados por PixelLab")
    (ART / "layout.json").write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
