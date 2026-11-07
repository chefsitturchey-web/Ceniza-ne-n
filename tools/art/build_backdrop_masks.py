"""Genera las máscaras de animación de los fondos de distrito.

Cada máscara tiene el mismo tamaño que su capa (1024x576) y la lee
components/backdrop_motion.gdshader con filtrado nearest:
  R = tipo de efecto * 16  (ver TIPOS)
  G = semilla por elemento (o alto de la columna en cascadas)
  B = parámetro (distancia desde el borde superior en cascadas y paños)

Uso:  python tools/art/build_backdrop_masks.py [--preview carpeta]
Las coordenadas están medidas sobre las capas de assets/world/backgrounds/layers.
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LAYERS = ROOT / "assets/world/backgrounds/layers"
OUT = ROOT / "assets/world/backgrounds/masks"

FALL, WATER, WINDOW, NEON, FLAME, BEACON, FAN, CLOTH, LED, MOLTEN = range(1, 11)
TIPOS = {FALL: "cascada", WATER: "agua", WINDOW: "ventana", NEON: "neón", FLAME: "llama",
         BEACON: "baliza", FAN: "ventilador", CLOTH: "paño", LED: "tira led", MOLTEN: "metal fundido"}
PREVIEW_COLORS = {FALL: (120, 200, 255), WATER: (40, 90, 255), WINDOW: (255, 230, 90), NEON: (0, 255, 230),
                  FLAME: (255, 140, 0), BEACON: (255, 0, 60), FAN: (200, 0, 255), CLOTH: (0, 255, 80),
                  LED: (255, 60, 160), MOLTEN: (255, 90, 0)}


def classes(rgba: np.ndarray) -> dict[str, np.ndarray]:
    r, g, b, a = (rgba[..., i].astype(int) for i in range(4))
    solid = a > 0
    return {
        "cyan": solid & (g > 150) & (b > 150) & (r < 130) & (g - r > 60),
        "warm": solid & (r > 200) & (g > 110) & (b < 120) & (r - b > 110),
        "red": solid & (r > 170) & (g < 80) & (b < 90),
        "lum": (r * 0.3 + g * 0.59 + b * 0.11),
        "solid": solid,
    }


def components(mask: np.ndarray) -> list[list[tuple[int, int]]]:
    """Componentes 8-conexas; sin scipy para no añadir dependencias."""
    seen = np.zeros(mask.shape, bool)
    found: list[list[tuple[int, int]]] = []
    height, width = mask.shape
    for y, x in zip(*np.nonzero(mask)):
        if seen[y, x]:
            continue
        queue = deque([(y, x)])
        seen[y, x] = True
        pixels = []
        while queue:
            cy, cx = queue.popleft()
            pixels.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < height and 0 <= nx < width and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
        found.append(pixels)
    return found


class Mask:
    def __init__(self, shape: tuple[int, int]):
        self.data = np.zeros(shape + (4,), np.uint8)
        self.data[..., 3] = 255
        self.seed = 17

    def put(self, pixels, kind: int, seed: int | None = None, param=0) -> None:
        ys = np.array([p[0] for p in pixels])
        xs = np.array([p[1] for p in pixels])
        if len(ys) == 0:
            return
        self.seed = (self.seed * 73 + 41) % 251
        self.data[ys, xs, 0] = kind * 16
        self.data[ys, xs, 1] = self.seed if seed is None else seed
        self.data[ys, xs, 2] = param if np.isscalar(param) else np.clip(param, 0, 255)

    def lights(self, cls: np.ndarray, kind: int, big_kind: int | None = None, big: int = 60,
               region: tuple[int, int, int, int] | None = None) -> None:
        if region is not None:
            cls = cls & box(cls.shape, *region)
        for pixels in components(cls):
            self.put(pixels, big_kind if big_kind is not None and len(pixels) >= big else kind)

    def leds(self, cls: np.ndarray) -> None:
        """Tiras verticales: B recorre la tira para encender un pulso que baja."""
        for pixels in components(cls):
            ys = [p[0] for p in pixels]
            tall = max(ys) - min(ys)
            if tall >= 6:
                self.put(pixels, LED, param=np.array([(y - min(ys)) * 255 // max(1, tall) for y in ys]))
            else:
                self.put(pixels, BEACON)

    def fall(self, rect: tuple[int, int, int, int], keep: np.ndarray) -> None:
        """Columnas de agua: G = alto de la columna, B = distancia desde su borde superior."""
        x0, y0, x1, y1 = rect
        for x in range(x0, x1):
            rows = [y for y in range(y0, y1) if keep[y, x]]
            if len(rows) < 4:
                continue
            top, bottom = min(rows), max(rows)
            span = list(range(top, bottom + 1))
            height = min(255, len(span))
            self.data[span, x, 0] = FALL * 16
            self.data[span, x, 1] = height
            self.data[span, x, 2] = [min(255, y - top) for y in span]

    def area(self, rect, kind: int, keep: np.ndarray | None = None, top_param: bool = False, ramp: int = 0) -> None:
        """ramp > 0: B crece desde el borde superior (el agua apenas se mueve junto a los pilotes)."""
        x0, y0, x1, y1 = rect
        region = box(self.data.shape[:2], *rect)
        if keep is not None:
            region &= keep
        ys, xs = np.nonzero(region)
        param = np.clip(ys - y0, 0, 255) if top_param else 255
        if ramp:
            param = np.clip((ys - y0) * 255 // ramp, 40, 255)
        self.put(list(zip(ys, xs)), kind, param=param)

    def cloth(self, body: np.ndarray, top: int) -> None:
        """Paño: G=255 en la tela, G=0 en un margen de 3 téxeles donde la onda puede asomar."""
        free = self.data[..., 0] == 0
        margin = grow(body, 3) & ~body & free
        for region, seed in ((margin, 0), (body, 255)):
            ys, xs = np.nonzero(region)
            self.put(list(zip(ys, xs)), CLOTH, seed=seed, param=np.clip(ys - top, 0, 255))

    def fan(self, center: tuple[int, int], radius: int, index: int) -> None:
        cx, cy = center
        yy, xx = np.mgrid[0:self.data.shape[0], 0:self.data.shape[1]]
        disc = (xx - cx) ** 2 + (yy - cy) ** 2 <= radius * radius
        ys, xs = np.nonzero(disc)
        self.put(list(zip(ys, xs)), FAN, seed=index)


def grow(region: np.ndarray, steps: int) -> np.ndarray:
    grown = region.copy()
    for _ in range(steps):
        step = grown.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            step |= np.roll(grown, (dy, dx), (0, 1))
        grown = step
    return grown


def rows_filled(region: np.ndarray) -> np.ndarray:
    """Rellena cada fila entre su primer y último píxel: el paño se mueve entero, sin agujeros."""
    filled = region.copy()
    for y in np.nonzero(region.any(axis=1))[0]:
        xs = np.nonzero(region[y])[0]
        if len(xs) > 3:
            filled[y, xs.min():xs.max() + 1] = True
    return filled


def box(shape, x0, y0, x1, y1) -> np.ndarray:
    region = np.zeros(shape, bool)
    region[y0:y1, x0:x1] = True
    return region


def build(zone: str) -> tuple[Image.Image, Image.Image]:
    art = np.asarray(Image.open(LAYERS / f"{zone}.png").convert("RGBA"))
    c = classes(art)
    mask = Mask(art.shape[:2])
    lum = c["lum"]
    if zone == "periphery_alive_v2":
        # Ventanas cálidas de las fábricas y faroles de la pasarela.
        mask.lights(c["warm"], FLAME, WINDOW, big=10)
        mask.lights(c["cyan"], BEACON)
        # Desagües del dique: chorros que caen al canal.
        mask.fall((380, 470, 392, 503), lum > 95)
        mask.fall((955, 470, 968, 503), lum > 95)
        mask.area((0, 503, 1024, 576), WATER, ramp=24)
        # Gancho de la grúa: se balancea como un paño colgado de la punta.
        mask.cloth(c["solid"] & box(c["solid"].shape, 444, 128, 452, 154), 124)
        mask.fan((191, 319), 17, 0)
        mask.fan((852, 333), 17, 1)
    elif zone == "foundry":
        molten = c["warm"]
        mask.lights(molten, FLAME, MOLTEN, big=24)
        r, g, b = (art[..., i].astype(int) for i in range(3))
        mask.lights(c["solid"] & (g > 120) & (b > 120) & (b - r > 40), WINDOW)
        mask.lights(c["red"], BEACON)
        # Colada principal del alto horno.
        mask.fall((172, 341, 193, 423), lum > 60)
        mask.fall((254, 182, 263, 247), lum > 100)
        mask.fall((556, 282, 565, 334), lum > 100)
    elif zone == "flooded":
        # Muestreo PIL de los pilotes y las bombas: no son parte del agua.
        water = c["solid"].copy()
        for rect in [(0, 392, 58, 430), (81, 392, 133, 461), (139, 392, 179, 435),
                     (191, 392, 212, 429), (350, 392, 377, 436), (435, 392, 450, 417),
                     (611, 392, 677, 425), (689, 392, 718, 445), (776, 392, 1024, 445)]:
            water &= ~box(water.shape, *rect)
        mask.area((0, 392, 1024, 576), WATER, keep=water, ramp=48)
        mask.lights(c["cyan"], WINDOW, NEON, big=90, region=(0, 0, 1024, 392))
        mask.lights(c["red"], BEACON)
    elif zone == "citadel":
        mask.lights(c["warm"], FLAME, region=(0, 0, 1024, 470))
        mask.lights(c["cyan"], WINDOW)
        bright = (lum > 75) & c["solid"]
        for rect in [(295, 300, 324, 372), (350, 300, 378, 362), (281, 390, 313, 455), (316, 392, 328, 450)]:
            mask.fall(rect, bright)
        # Estandartes: tela azul marino y su ribete dorado, no el muro que los rodea.
        r, g, b = (art[..., i].astype(int) for i in range(3))
        navy = (b - r > 25) & (r < 40)
        gold = (r > 100) & (r - b > 50)
        cloth = navy | (gold & grow(navy, 3))
        for rect in [(613, 275, 646, 409), (878, 253, 919, 406)]:
            mask.cloth(rows_filled(cloth & box(cloth.shape, *rect)), rect[1])
        mask.area((0, 472, 1024, 528), WATER, keep=lum > 60)
    elif zone == "network":
        mask.lights(c["cyan"], WINDOW, NEON, big=40)
        mask.leds(c["red"])
        mask.lights(c["warm"], FLAME)
    image = Image.fromarray(mask.data, "RGBA")
    preview = (art[..., :3] * 0.3).astype(np.uint8)
    kinds = mask.data[..., 0] // 16
    for kind, color in PREVIEW_COLORS.items():
        preview[kinds == kind] = color
    return image, Image.fromarray(preview, "RGB")


def main() -> None:
    preview_dir = Path(sys.argv[sys.argv.index("--preview") + 1]) if "--preview" in sys.argv else None
    OUT.mkdir(parents=True, exist_ok=True)
    for zone in ["periphery_alive_v2", "foundry", "flooded", "citadel", "network"]:
        image, preview = build(zone)
        name = "periphery" if zone.startswith("periphery") else zone
        image.save(OUT / f"{name}.png")
        kinds = np.asarray(image)[..., 0] // 16
        print(name, {TIPOS[k]: int((kinds == k).sum()) for k in TIPOS if (kinds == k).any()})
        if preview_dir:
            preview_dir.mkdir(parents=True, exist_ok=True)
            preview.save(preview_dir / f"mask_{name}.png")


if __name__ == "__main__":
    main()
