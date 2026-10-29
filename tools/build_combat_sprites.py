"""Create empty ASE timelines; LibreSprite draws and exports every RGBA pixel.

No image libraries, generated raster input or network services are used here.
"""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / '.godot/combat-art'
OUT = ROOT / 'assets/combat/native'
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


def blank(path, size, clips, height=None):
    height = size if height is None else height
    tags = struct.pack('<H8x', len(clips))
    cursor, durations = 0, []
    for name, count, fps, _loop in clips:
        tags += struct.pack('<HHB8x3BB', cursor, cursor + count - 1, 0, 71, 218, 203, 0) + string(name)
        cursor += count
        durations.extend([round(1000 / fps)] * count)
    layers = b''.join(chunk(0x2004, struct.pack('<HHHHHHB3x', 3, 0, 0, 0, 0, 0, 255) + string(name))
                      for name in ['Cuerpo y apoyo', 'Armas y mecanismos', 'Efectos dibujados'])
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--libresprite', default='D:/descargas/libresprite-development-windows-x86_64/libresprite.exe')
    parser.add_argument('--actors', nargs='+', choices=ACTORS, default=ACTORS)
    parser.add_argument('--overwrite-edits', action='store_true', help='Explicitly replace ASE files edited after the last build')
    args = parser.parse_args()
    WORK.mkdir(parents=True, exist_ok=True)
    (OUT / 'sources').mkdir(parents=True, exist_ok=True)
    (OUT / 'sources/.gdignore').write_text('')
    provenance_path = OUT / 'provenance.json'
    prior = json.loads(provenance_path.read_text(encoding='utf-8')) if provenance_path.exists() else {}
    source_hashes = prior.get('sources_sha256', {})
    for actor in args.actors:
        source = OUT / 'sources' / f'{actor}.ase'
        if not args.overwrite_edits and source.exists() and actor in source_hashes:
            if hashlib.sha256(source.read_bytes()).hexdigest() != source_hashes[actor]:
                raise RuntimeError(f'{source.name} has manual changes. Export it from LibreSprite, or use --overwrite-edits intentionally.')
    clips = [(state + '_' + direction, count, fps, loop)
             for direction in DIRECTIONS for state, count, fps, loop in STATES]
    entries = [{'state': state, 'direction': direction, 'frame': index, 'count': count}
               for direction in DIRECTIONS for state, count, _fps, _loop in STATES for index in range(count)]
    layout = {'columns': 8, 'animations': {}, 'actors': {}}
    cursor = 0
    for name, count, fps, loop in clips:
        layout['animations'][name] = {'frames': list(range(cursor, cursor + count)), 'fps': fps, 'loop': loop}
        cursor += count
    for actor in ACTORS:
        hero = actor.startswith('portador')
        layout['actors'][actor] = {'cell': 96 if hero else (160 if actor == 'prefecto' else 128),
                                  'anchor': ([48, 73] if actor == 'portador' else [48, 48]) if hero else ([80, 80] if actor == 'prefecto' else [64, 64]),
                                  'camera': 'lateral' if actor == 'portador' else 'cenital'}
    for actor in args.actors:
        size = layout['actors'][actor]['cell']
        blank(WORK / f'{actor}-blank.ase', size, clips)
    settings = {'actors': args.actors, 'entries': entries, 'work': WORK.as_posix(), 'output': OUT.as_posix()}
    script = WORK / 'render-combat.js'
    script.write_text('var BUILD = ' + json.dumps(settings) + ';\n' + (ROOT / 'tools/libresprite_combat.js').read_text(encoding='utf-8') + '\n' + (ROOT / 'tools/libresprite_projection.js').read_text(encoding='utf-8'), encoding='utf-8')
    process = subprocess.run([args.libresprite, '--batch', '--script', str(script)], cwd=ROOT, capture_output=True, timeout=600)
    (WORK / 'render.log').write_bytes(process.stdout + process.stderr)
    transcript = (process.stdout + process.stderr).decode('utf-8', errors='replace')
    if process.returncode or any('Native pixels completed: ' + actor not in transcript for actor in args.actors):
        raise RuntimeError('LibreSprite failed; see .godot/combat-art/render.log')
    prior_layout = json.loads((OUT / 'layout.json').read_text()) if (OUT / 'layout.json').exists() else {}
    for actor in ACTORS:
        match = re.search(r'Native body bounds: ' + actor + r' (\[[^\]]+\])', transcript)
        if match:
            layout['actors'][actor]['idle_body_bounds'] = json.loads(match[1])
        elif actor in args.actors:
            raise RuntimeError(f'Missing native body measurement: {actor}')
        elif actor in prior_layout.get('actors', {}):
            bounds = prior_layout['actors'][actor].get('idle_body_bounds')
            if bounds:
                layout['actors'][actor]['idle_body_bounds'] = bounds
    for actor in args.actors:
        source = OUT / 'sources' / f'{actor}.ase'
        if not source.exists():
            raise RuntimeError(f'LibreSprite did not save {actor}; inspect render.log')
        size = layout['actors'][actor]['cell']
        result = subprocess.run([args.libresprite, '--batch', str(source), '--sheet-type', 'rows',
                                 '--sheet-width', str(size * 8), '--sheet', str(OUT / f'{actor}.png'),
                                 '--data', str(WORK / f'{actor}.json'), '--format', 'json-array', '--list-tags'],
                                capture_output=True, timeout=90)
        if result.returncode:
            raise RuntimeError(f'Export failed: {actor}')
        data = json.loads((WORK / f'{actor}.json').read_text())
        assert len(data['frames']) == cursor
        assert len(data['meta']['frameTags']) == len(clips)
        print(f'LibreSprite: {actor}, {size}x{size}, {cursor} frames, {len(clips)} clips', flush=True)
        source_hashes[actor] = hashlib.sha256(source.read_bytes()).hexdigest()
    (OUT / 'layout.json').write_text(json.dumps(layout, indent=2) + '\n', encoding='utf-8')
    provenance_path.write_text(json.dumps({'tool': 'LibreSprite', 'source': 'tools/libresprite_projection.js',
        'helpers': 'tools/libresprite_combat.js',
        'visual_reference': 'assets/story/portraits_manga_v2.png: Portador, bottom-right portrait; visual study only.',
        'method': 'Camera-specific pixel drawing and articulated poses in native LibreSprite JavaScript; empty ASE containers only are created by Python.',
        'layers': ['body', 'weapons and mechanisms', 'pixel effects'], 'actors': ACTORS,
        'frames_per_actor': cursor, 'external_raster_inputs': [], 'sources_sha256': source_hashes}, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
