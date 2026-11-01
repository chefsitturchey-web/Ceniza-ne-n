"""Integra las animaciones cuadro por cuadro del Portador generadas con PixelLab.

Los cuadros de 132x132 en assets/characters/combat/sources/pixellab_portador/{idle,walk,run}
(indice 0 = pose de referencia, 1..8 = generados) se pegan en las celdas de 192 px de
portador.png para reposo, marcha, ataque, esquiva y daño este y oeste (espejado). Correr va a portador_correr.png
(fila 0 = este, fila 1 = oeste). Uso: python tools/art/integrar_portador_pixellab.py
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/characters/combat"
SRC = ART / "sources/pixellab_portador"
CELL, OFFSET = 192, (30, 26)  # el recorte de 132 px se tomo en (30, 26) de la celda; ancla (96, 146)
# clip del layout: (carpeta fuente, cuadros, centrar en x, quitar destellos rojos)
CLIPS = {
    "idle": ("idle", [1, 2, 4, 5, 7, 8], False, False),
    "walk": ("walk", [1, 2, 3, 4, 5, 6, 7, 8], False, False),
    "windup": ("attack", [1, 2, 2, 3, 3, 4], False, False),
    "attack": ("attack", [5, 5, 6, 6, 7, 7, 8, 8], False, False),
    # El juego ya desplaza al Portador al esquivar o recibir golpe: el cuerpo se queda centrado.
    "dodge": ("dodge", [2, 3, 4, 5, 6, 8], True, False),
    "hurt": ("hurt", [1, 2, 3, 4], True, True),
}
BODY_CENTRE_X = 57
RUN = [2, 3, 4, 5, 6, 7, 8]


def strip_effects(frame: Image.Image) -> Image.Image:
    """Quita destellos rojos pintados por PixelLab y conserva solo la silueta conectada mas grande."""
    w, h = frame.size
    px = frame.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and r > 50 and r > g * 1.8 and r > b * 1.8:
                px[x, y] = (0, 0, 0, 0)
    seen, best = set(), set()
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or px[x, y][3] < 40:
                continue
            group, stack = set(), [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                group.add((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3] >= 40:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if len(group) > len(best):
                best = group
    for y in range(h):
        for x in range(w):
            if (x, y) not in best:
                px[x, y] = (0, 0, 0, 0)
    return frame


def cell_image(path: Path, mirror: bool, centre: bool = False, strip_red: bool = False) -> Image.Image:
    frame = Image.open(path).convert("RGBA")
    if strip_red:
        frame = strip_effects(frame)
    shift = 0
    if centre:
        box = frame.getchannel("A").point(lambda a: 255 if a > 127 else 0).getbbox()
        shift = BODY_CENTRE_X - (box[0] + box[2]) // 2
    cell = Image.new("RGBA", (CELL, CELL))
    cell.alpha_composite(frame, (OFFSET[0] + shift, OFFSET[1]))
    return cell.transpose(Image.FLIP_LEFT_RIGHT) if mirror else cell


def main() -> None:
    layout = json.loads((ART / "layout.json").read_text(encoding="utf-8"))
    sheet = Image.open(ART / "portador.png").convert("RGBA")
    for clip, (folder, picks, centre, strip_red) in CLIPS.items():
        for direction, mirror in (("east", False), ("west", True)):
            for slot, index in zip(layout["animations"][f"{clip}_{direction}"]["frames"], picks):
                position = (slot % 8 * CELL, slot // 8 * CELL)
                sheet.paste(Image.new("RGBA", (CELL, CELL)), position)
                sheet.alpha_composite(cell_image(SRC / folder / f"{index}.png", mirror, centre, strip_red), position)
    sheet.save(ART / "portador.png")
    run = Image.new("RGBA", (CELL * 8, CELL * 2))
    for row, mirror in enumerate((False, True)):
        for column, index in enumerate(RUN):
            run.alpha_composite(cell_image(SRC / "run" / f"{index}.png", mirror), (column * CELL, row * CELL))
    run.save(ART / "portador_correr.png")
    print("portador.png y portador_correr.png actualizados")


if __name__ == "__main__":
    main()
