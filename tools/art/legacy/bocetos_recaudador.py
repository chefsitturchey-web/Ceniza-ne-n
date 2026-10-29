"""Bocetos cenitales del jefe El Recaudador, por piezas (marioneta): chasis, orugas, escudo, garras y núcleo.
Todas las piezas miran hacia abajo de la imagen (sur) y se rotan en el juego."""
import sys
from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
C = {k: '#' + v for k, v in dict(sh='0B1322', d='182639', m='304356', l='8299A8', cy='47DACB', am='FFCE75',
                                   pk='DD6482', ru='E89E54', dk='101A2B').items()}


def new(w, h):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


# chasis: caja blindada octogonal con placas y ranura de cobro
im, d = new(64, 64)
d.polygon([(16, 4), (48, 4), (60, 16), (60, 48), (48, 60), (16, 60), (4, 48), (4, 16)], fill=C['m'], outline=C['sh'])
d.polygon([(20, 10), (44, 10), (54, 20), (54, 44), (44, 54), (20, 54), (10, 44), (10, 20)], fill=C['d'], outline=C['sh'])
d.rectangle((24, 24, 40, 40), fill=C['dk'], outline=C['sh'])
d.rectangle((22, 46, 42, 49), fill=C['am'])  # ranura de cobro iluminada
for x, y in ((14, 14), (50, 14), (14, 50), (50, 50), (32, 7)):
    d.point((x, y), fill=C['l'])
d.line((10, 30, 54, 30), fill=C['ru'])
im.save(f'{OUT}/body.png')

# oruga (izquierda y derecha usan la misma)
im, d = new(12, 60)
d.rectangle((0, 0, 11, 59), fill=C['dk'], outline=C['sh'])
for y in range(2, 58, 5):
    d.line((1, y, 10, y), fill=C['m'])
im.save(f'{OUT}/tread.png')

# escudo frontal curvo
im, d = new(56, 14)
d.polygon([(2, 2), (54, 2), (50, 12), (6, 12)], fill=C['l'], outline=C['sh'])
d.line((6, 5, 50, 5), fill=C['m']); d.line((8, 9, 48, 9), fill=C['m'])
for x in (12, 28, 44):
    d.point((x, 7), fill=C['sh'])
im.save(f'{OUT}/shield.png')

# garra (brazo de cobro)
im, d = new(16, 28)
d.rectangle((5, 0, 10, 16), fill=C['m'], outline=C['sh'])
d.polygon([(1, 16), (15, 16), (13, 27), (9, 22), (7, 22), (3, 27)], fill=C['l'], outline=C['sh'])
im.save(f'{OUT}/claw.png')

# núcleo expuesto
im, d = new(18, 18)
d.ellipse((0, 0, 17, 17), fill=C['sh']); d.ellipse((2, 2, 15, 15), fill=C['ru']); d.ellipse((5, 5, 12, 12), fill=C['am'])
d.point((7, 6), fill='#FFFFFF')
im.save(f'{OUT}/core.png')
print('piezas listas')
