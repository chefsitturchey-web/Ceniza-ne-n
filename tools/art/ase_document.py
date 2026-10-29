"""Create empty ASE timelines and shared clip definitions for LibreSprite.

No image libraries, generated raster input or network services are used here.
"""
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ACTORS = ['portador', 'portador_cenital', 'recaudador', 'caldera', 'coro', 'prefecto', 'madre']
STATES = [('idle', 6, 6, True), ('walk', 8, 12, True), ('windup', 6, 12, False),
          ('attack', 8, 24, False), ('shoot', 6, 14, False), ('charge', 6, 16, True),
          ('exposed', 6, 8, True), ('hurt', 4, 16, False), ('death', 8, 10, False),
          ('dodge', 6, 24, False)]
DIRECTIONS = ['south', 'east', 'north', 'west']


def string(value):
    raw = value.encode('utf-8')
    return struct.pack('<H', len(raw)) + raw


def chunk(kind, content):
    return struct.pack('<IH', len(content) + 6, kind) + content


def blank(path, size, clips, height=None, layer_names=None):
    height = size if height is None else height
    tags = struct.pack('<H8x', len(clips))
    cursor, durations = 0, []
    for name, count, fps, _loop in clips:
        tags += struct.pack('<HHB8x3BB', cursor, cursor + count - 1, 0, 71, 218, 203, 0) + string(name)
        cursor += count
        durations.extend([round(1000 / fps)] * count)
    layers = b''.join(chunk(0x2004, struct.pack('<HHHHHHB3x', 3, 0, 0, 0, 0, 0, 255) + string(name))
                      for name in (layer_names or ['Cuerpo y apoyo', 'Armas y mecanismos', 'Efectos dibujados']))
    empty = zlib.compress(bytes(size * height * 4))
    cels = b''.join(chunk(0x2005, struct.pack('<HhhBH7xHH', i, 0, 0, 255, 2, size, height) + empty) for i in range(3))
    frames = []
    for index, duration in enumerate(durations):
        payload = (layers + chunk(0x2018, tags) if index == 0 else b'') + cels
        frames.append(struct.pack('<IHHH2xI', 16 + len(payload), 0xF1FA, 7 if index == 0 else 3, duration, 0) + payload)
    header = bytearray(128)
    struct.pack_into('<IHHHHHIH', header, 0, 128 + sum(map(len, frames)), 0xA5E0, len(frames), size, height, 32, 1, 100)
    header[34:36] = bytes([1, 1])
    path.write_bytes(header + b''.join(frames))
