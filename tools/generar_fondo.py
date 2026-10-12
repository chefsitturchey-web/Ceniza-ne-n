"""Genera las capas de fondo de Ceniza Neón: pixel art lateral plano, repetible en horizontal."""
import random, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
W = 640


def hexc(h, a=255):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def wrap_rect(d, x0, y0, x1, y1, fill):
    """Rectángulo que continúa por el otro borde para que la capa se repita sin costura."""
    for off in (-W, 0, W):
        d.rectangle((x0 + off, y0, x1 + off, y1), fill=fill)


def far_layer(seed=7, H=260):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body, edge, win = hexc("101a2b"), hexc("152236"), hexc("243650")
    x = 0
    while x < W:
        w = rnd.randint(26, 70)
        h = rnd.randint(110, 240)
        top = H - h
        wrap_rect(d, x, top, x + w - 1, H - 1, body)
        wrap_rect(d, x, top, x + 1, H - 1, edge)  # luz de arriba a la izquierda
        if rnd.random() < 0.5:  # antena o grúa
            ax = x + rnd.randint(4, w - 5)
            wrap_rect(d, ax, top - rnd.randint(10, 30), ax, top, body)
        if rnd.random() < 0.25:  # brazo de grúa
            wrap_rect(d, x + w // 2, top - 22, x + w // 2 + 1, top, body)
            wrap_rect(d, x + w // 2 - 18, top - 22, x + w // 2 + 26, top - 21, body)
        for wy in range(top + 6, H - 8, 7):  # ventanas apagadas, muy pocas
            for wx in range(x + 4, x + w - 4, 6):
                if rnd.random() < 0.08:
                    wrap_rect(d, wx, wy, wx + 1, wy + 2, win)
        x += w + rnd.randint(0, 10)
    return im


def mid_layer(seed=21, H=200):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body, edge, dark = hexc("182639"), hexc("22344b"), hexc("0f1828")
    win, lit, warn = hexc("304356"), hexc("477687"), hexc("ffce75")
    # vía elevada rota que cruza la capa
    rail_y = H - 118
    gap0 = rnd.randint(200, 380)
    for x0, x1 in ((0, gap0), (gap0 + 46, W - 1)):
        d.rectangle((x0, rail_y, x1, rail_y + 6), fill=body)
        d.line((x0, rail_y, x1, rail_y), fill=edge)
        for px in range(x0 + 20, x1 - 10, 64):
            d.rectangle((px, rail_y + 7, px + 5, H - 1), fill=dark)
    d.polygon([(gap0, rail_y), (gap0 + 9, rail_y + 14), (gap0, rail_y + 6)], fill=body)  # extremo colgante
    x = 0
    while x < W:
        w = rnd.randint(34, 90)
        h = rnd.randint(50, 150)
        top = H - h
        wrap_rect(d, x, top, x + w - 1, H - 1, body)
        wrap_rect(d, x, top, x + w - 1, top + 1, edge)
        if rnd.random() < 0.4:  # techo roto escalonado
            step = rnd.randint(6, 16)
            wrap_rect(d, x + w - step, top, x + w - 1, top + step, (0, 0, 0, 0))
        if rnd.random() < 0.35:  # tubería
            py = top + rnd.randint(10, max(11, h - 20))
            wrap_rect(d, x - 6, py, x + w + 6, py + 2, dark)
        for wy in range(top + 8, H - 10, 9):
            for wx in range(x + 5, x + w - 6, 8):
                r = rnd.random()
                if r < 0.015:
                    wrap_rect(d, wx, wy, wx + 2, wy + 3, warn)
                elif r < 0.07:
                    wrap_rect(d, wx, wy, wx + 2, wy + 3, lit)
                elif r < 0.22:
                    wrap_rect(d, wx, wy, wx + 2, wy + 3, win)
        x += w + rnd.randint(4, 22)
    return im


far_layer().save(f"{OUT}/background_far.png")
mid_layer().save(f"{OUT}/background_mid.png")
print("capas generadas")
