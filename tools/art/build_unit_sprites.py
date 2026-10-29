"""Assemble editable animation documents and export them with LibreSprite.

Python writes empty ASE containers and metadata only. All RGBA sampling,
pixel drawing, outfit edits and frame rendering run inside LibreSprite's JS API.
Native input clips are prepared with queue_unit_clips.py; no credentials are saved.
"""
import argparse
import json
import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / '.godot/unit-art'
OUTPUT = ROOT / 'assets/units/animated'
ROLES = ['ranger', 'guardian', 'technician', 'medic', 'builder', 'collector', 'civilian', 'artillero', 'saboteador']
DEFINITIONS = [('reposo', 4, 5, True), ('caminar', 8, 10, True), ('dano', 6, 16, False),
               ('caer', 7, 9, False), ('cansancio', 8, 7, True), ('disparar', 8, 20, False),
               ('reparar', 8, 12, True), ('cargar', 8, 10, True), ('levantarse', 7, 12, False),
               ('proteger', 8, 14, False)]


def string(value):
    raw = value.encode('utf-8')
    return struct.pack('<H', len(raw)) + raw


def chunk(kind, payload):
    return struct.pack('<IH', len(payload) + 6, kind) + payload


def empty_document(path, definitions):
    """Two editable layers, explicit durations and named timeline tags."""
    tags = struct.pack('<H8x', len(definitions))
    cursor = 0
    durations = []
    for name, count, fps, _loop in definitions:
        tags += struct.pack('<HHB8x3BB', cursor, cursor + count - 1, 0, 71, 218, 203, 0) + string(name)
        cursor += count
        durations.extend([round(1000 / fps)] * count)
    layers = b''.join(chunk(0x2004, struct.pack('<HHHHHHB3x', 3, 0, 0, 0, 0, 0, 255) + string(name))
                      for name in ['Cuerpo', 'Equipo'])
    transparent = zlib.compress(bytes(64 * 64 * 4))
    cels = b''.join(chunk(0x2005, struct.pack('<HhhBH7xHH', layer, 0, 0, 255, 2, 64, 64) + transparent)
                    for layer in range(2))
    frames = []
    for index, duration in enumerate(durations):
        payload = (layers + chunk(0x2018, tags) if index == 0 else b'') + cels
        frames.append(struct.pack('<IHHH2xI', 16 + len(payload), 0xF1FA, 5 if index == 0 else 2, duration, 0) + payload)
    header = bytearray(128)
    struct.pack_into('<IHHHHHIH', header, 0, 128 + sum(map(len, frames)), 0xA5E0, len(frames), 64, 64, 32, 1, 100)
    header[34:36] = bytes([1, 1])
    path.write_bytes(header + b''.join(frames))


def find_clips():
    source = WORK / 'native'
    metadata = json.loads((source / 'metadata.json').read_text())
    state = metadata['states'][0]
    # Metadata can evolve; filenames also preserve animation display names.
    files = list(source.rglob('*.png'))
    clips = {}
    for name, count, _fps, _loop in DEFINITIONS[:7]:
        aliases = [name, 'caminar' if name == 'caminar' else name]
        candidates = [p for p in files if 'east' in p.parts and 'south-east' not in p.parts and
                      any(alias in p.parts for alias in aliases)]
        if not candidates:
            raise ValueError(f'No native frames for {name}; inspect {source / "metadata.json"}')
        candidates.sort(key=lambda p: [int(x) if x.isdigit() else x for x in __import__('re').split(r'(\d+)', str(p))])
        if len(candidates) != count:
            raise ValueError(f'{name}: expected {count} frames, got {len(candidates)}')
        clips[name] = [p.as_posix() for p in candidates]
    clips['cargar'] = clips['caminar']
    clips['levantarse'] = list(reversed(clips['caer']))
    clips['proteger'] = clips['disparar']
    return clips, state


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--libresprite', default='D:/descargas/libresprite-development-windows-x86_64/libresprite.exe')
    parser.add_argument('--native', action='store_true', help='Import freshly downloaded MCP clips instead of the editable pose reference')
    args = parser.parse_args()
    WORK.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sources = OUTPUT / 'sources'
    sources.mkdir(exist_ok=True)
    (sources / '.gdignore').write_text('')
    canonical = (sources / 'pose_reference.ase').exists() and not args.native
    clips, state = ({}, {}) if canonical else find_clips()
    entries = []
    layout = {'cell': [64, 64], 'anchor': [32, 56], 'columns': 8, 'animations': {}}
    cursor = 0
    for name, count, fps, loop in DEFINITIONS:
        layout['animations'][name] = {'frames': list(range(cursor, cursor + count)), 'fps': fps, 'loop': loop}
        entries.extend({'state': name, 'index': index, 'count': count, 'file': file}
                       for index, file in enumerate(clips.get(name, [''] * count)))
        cursor += count
    layout['animations']['huir'] = dict(layout['animations']['caminar'], fps=14)
    for role in ROLES:
        empty_document(WORK / f'{role}-blank.ase', DEFINITIONS)
    if not canonical: empty_document(WORK / 'pose-reference-blank.ase', DEFINITIONS)
    settings = {'roles': ROLES, 'entries': entries, 'work': WORK.as_posix(), 'output': OUTPUT.as_posix(), 'canonical': canonical}
    script = WORK / 'build-unit-sprites.js'
    script.write_text('var BUILD = ' + json.dumps(settings) + ';\n' + (ROOT / 'tools/art/libresprite_units.js').read_text(), encoding='utf-8')
    run = subprocess.run([args.libresprite, '--batch', '--script', str(script)], cwd=ROOT,
                         capture_output=True, timeout=180)
    (WORK / 'libresprite-build.log').write_bytes(run.stdout + run.stderr)
    if run.returncode:
        raise RuntimeError('LibreSprite failed; see .godot/unit-art/libresprite-build.log')
    for role in ROLES:
        source = sources / f'{role}.ase'
        if not source.exists():
            raise RuntimeError(f'LibreSprite did not create {role}; inspect build log')
        run = subprocess.run([args.libresprite, '--batch', str(source), '--sheet-type', 'rows',
                              '--sheet-width', '512', '--sheet', str(OUTPUT / f'{role}.png'),
                              '--data', str(WORK / f'{role}-export.json'), '--format', 'json-array', '--list-tags'],
                             capture_output=True, timeout=45)
        if run.returncode:
            raise RuntimeError(f'Export failed: {role}')
        exported = json.loads((WORK / f'{role}-export.json').read_text())
        assert len(exported['frames']) == cursor, (role, len(exported['frames']))
        assert all(frame['frame']['w'] == 64 and frame['frame']['h'] == 64 for frame in exported['frames'])
        print('LibreSprite exported:', role, cursor, 'frames', flush=True)
    (OUTPUT / 'layout.json').write_text(json.dumps(layout, indent=2), encoding='utf-8')
    if not canonical:
        (OUTPUT / 'provenance.json').write_text(json.dumps({'character': state['character'], 'pipeline':
            'Native PixelLab pose clips; outfit pixel edits and two-layer ASE documents rendered by tools/art/libresprite_units.js inside LibreSprite; full-frame PNG sheets exported by LibreSprite.',
            'roles': ROLES, 'frames_per_role': cursor}, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
