"""Integra las animaciones cuadro por cuadro del Portador generadas con PixelLab.

Los cuadros de 132x132 en assets/characters/combat/sources/pixellab_portador/{idle,walk,run}
(indice 0 = pose de referencia, 1..8 = generados) se pegan en las celdas de 192 px de
portador.png para idle/walk este y oeste (espejado). Correr va a portador_correr.png
(fila 0 = este, fila 1 = oeste). Uso: python tools/art/integrar_portador_pixellab.py
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/characters/combat"
SRC = ART / "sources/pixellab_portador"
CELL, OFFSET = 192, (30, 26)  # el recorte de 132 px se tomo en (30, 26) de la celda; ancla (96, 146)
CLIPS = {"idle": [1, 2, 4, 5, 7, 8], "walk": [1, 2, 3, 4, 5, 6, 7, 8]}
RUN = [2, 3, 4, 5, 6, 7, 8]


def cell_image(path: Path, mirror: bool) -> Image.Image:
    frame = Image.open(path).convert("RGBA")
    cell = Image.new("RGBA", (CELL, CELL))
    cell.alpha_composite(frame, OFFSET)
    return cell.transpose(Image.FLIP_LEFT_RIGHT) if mirror else cell


def main() -> None:
    layout = json.loads((ART / "layout.json").read_text(encoding="utf-8"))
    sheet = Image.open(ART / "portador.png").convert("RGBA")
    for clip, picks in CLIPS.items():
        for direction, mirror in (("east", False), ("west", True)):
            for slot, index in zip(layout["animations"][f"{clip}_{direction}"]["frames"], picks):
                position = (slot % 8 * CELL, slot // 8 * CELL)
                sheet.paste(Image.new("RGBA", (CELL, CELL)), position)
                sheet.alpha_composite(cell_image(SRC / clip / f"{index}.png", mirror), position)
    sheet.save(ART / "portador.png")
    run = Image.new("RGBA", (CELL * 8, CELL * 2))
    for row, mirror in enumerate((False, True)):
        for column, index in enumerate(RUN):
            run.alpha_composite(cell_image(SRC / "run" / f"{index}.png", mirror), (column * CELL, row * CELL))
    run.save(ART / "portador_correr.png")
    print("portador.png y portador_correr.png actualizados")


if __name__ == "__main__":
    main()
