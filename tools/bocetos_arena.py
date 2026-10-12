"""Bocetos cenitales (vista desde arriba) para la arena del Recaudador: piso, borde y obstáculos."""
import random
from PIL import Image, ImageDraw

C = {k: '#' + v for k, v in dict(sh='0B1322', d='182639', m='304356', l='8299A8', cy='47DACB', am='FFCE75',
                                   pk='DD6482', ru='E89E54', dk='101A2B', g2='22344B').items()}
rnd = random.Random(4)

# baldosa de piso industrial 32x32 (repetible): placas de metal con remaches y juntas
im = Image.new('RGBA', (32, 32), C['d']); d = ImageDraw.Draw(im)
d.rectangle((0, 0, 15, 15), fill=C['g2']); d.rectangle((16, 16, 31, 31), fill=C['g2'])
for x in (0, 16):
    d.line((x, 0, x, 31), fill=C['sh'])
for y in (0, 16):
    d.line((0, y, 31, y), fill=C['sh'])
for x, y in ((2, 2), (13, 2), (2, 13), (13, 13), (18, 18), (29, 18), (18, 29), (29, 29)):
    d.point((x, y), fill=C['l'])
for _ in range(6):
    x, y = rnd.randint(1, 30), rnd.randint(1, 30); d.point((x, y), fill=C['m'])
im.save('floor.png')

# borde de la plataforma con franja de peligro (32x12, repetible en horizontal)
im = Image.new('RGBA', (32, 12), C['m']); d = ImageDraw.Draw(im)
for x in range(-12, 32, 8):
    d.polygon([(x, 11), (x + 4, 11), (x + 8, 3), (x + 4, 3)], fill=C['am'])
d.rectangle((0, 0, 31, 2), fill=C['l']); d.line((0, 11, 31, 11), fill=C['sh'])
im.save('edge.png')

# obstáculos vistos desde arriba: caja, barril, pilar roto
im = Image.new('RGBA', (20, 20), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.rectangle((1, 1, 18, 18), fill=C['m'], outline=C['sh']); d.line((1, 1, 18, 18), fill=C['d']); d.line((18, 1, 1, 18), fill=C['d'])
d.rectangle((1, 1, 18, 3), fill=C['l'])
im.save('crate_top.png')
im = Image.new('RGBA', (16, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.ellipse((1, 1, 14, 14), fill=C['ru'], outline=C['sh']); d.ellipse((4, 4, 11, 11), fill=C['am'], outline=C['sh'])
im.save('barrel_top.png')
im = Image.new('RGBA', (28, 28), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.polygon([(4, 2), (24, 3), (26, 22), (14, 26), (2, 20)], fill=C['m'], outline=C['sh'])
d.polygon([(8, 6), (20, 7), (21, 18), (9, 19)], fill=C['l'], outline=C['sh'])
im.save('pillar_top.png')
print('ok')
