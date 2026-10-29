"""Measure painted key poses, then assemble animation documents IN LibreSprite.

Pillow is used for read-only alpha measurements. Only LibreSprite crops, samples,
corrects pixels and exports images. Network generation is a separate operation.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from collections import deque
from PIL import Image
from build_combat_sprites import ROOT, blank, STATES, DIRECTIONS, ACTORS

WORK = ROOT / '.godot/combat-v2'
OUT = ROOT / 'assets/combat/illustrated'
MIN_FRAMES = {'idle': 1, 'walk': 4, 'windup': 3, 'attack': 3, 'shoot': 3,
              'charge': 4, 'exposed': 1, 'hurt': 2, 'death': 3, 'dodge': 3}
POSES = {'idle': [0]*6, 'walk': [1, 1, 2, 0, 3, 3, 4, 0],
         'windup': [0, 0, 5, 5, 6, 6], 'attack': [7, 7, 8, 8, 8, 8, 0, 0],
         'shoot': [0, 5, 6, 7, 8, 0], 'charge': [1, 2, 3, 4, 1, 3],
         'exposed': [0]*6, 'hurt': [0, 9, 9, 0],
         'death': [9, 10, 10, 10, 11, 11, 11, 11],
         'dodge': [0, 9, 10, 9, 0, 0]}
TIMING = {'windup': [1, 1, 1, 1, 2, 2],
          'attack': [0.5, 0.5, 0.75, 0.75, 1, 1.5, 1.5, 1.5],
          'death': [0.6, 0.6, 0.8, 1, 1, 1, 1, 2]}


def action_components(alpha, columns):
    """Read-only connected contours prevent tall swords leaking between rows."""
    width, height = alpha.size
    pixels, seen = alpha.tobytes(), bytearray(width*height)
    parts = []
    for start, value in enumerate(pixels):
        if not value or seen[start]: continue
        queue = deque([start]); seen[start] = 1
        count, left, top, right, bottom = 0, width, height, 0, 0
        while queue:
            at = queue.popleft(); x, y = at % width, at // width
            count += 1;left=min(left,x);top=min(top,y);right=max(right,x+1);bottom=max(bottom,y+1)
            for oy in [-1,0,1]:
                for ox in [-1,0,1]:
                    xx, yy = x+ox, y+oy
                    if xx<0 or yy<0 or xx>=width or yy>=height: continue
                    nxt=yy*width+xx
                    if pixels[nxt] and not seen[nxt]: seen[nxt]=1;queue.append(nxt)
        if count > width*height/(columns*4)*.025:
            parts.append({'count':count,'box':[left,top,right,bottom],'seed':[start%width,start//width]})
    wanted=columns*4
    if len(parts)<wanted: return None
    chosen=sorted(parts,key=lambda p:p['count'],reverse=True)[:wanted]
    chosen.sort(key=lambda p:(p['box'][1]+p['box'][3])/2)
    rows,seeds=[],[]
    for row in range(4):
        group=sorted(chosen[row*columns:(row+1)*columns],key=lambda p:(p['box'][0]+p['box'][2])/2)
        rows.append([p['box'] for p in group]);seeds.append([p['seed'] for p in group])
    return {'width':width,'height':height,'rows':rows,'seeds':seeds,'registration':'connected contours'}


def measure(path, columns=12):
    """Do NOT modify image pixels. Measure transparent-separated rows and poses."""
    with Image.open(path) as image:
        if image.mode != 'RGBA':
            raise ValueError(f'{path.name}: expected genuine transparency')
        alpha = image.getchannel('A').point(lambda a: 255 if a >= 200 else 0)
        if alpha.getextrema()[0] != 0:
            raise ValueError(f'{path.name}: opaque background')
        if columns == 4:
            connected = action_components(alpha, columns)
            if connected is not None: return connected
        # Read the first figure's torso column to find real row gaps. Generated
        # sheets need not place all four baselines at exact fractions of height.
        centre, half = image.width/(columns*2), image.width/(columns*4)
        probe = alpha.crop((int(centre-half), 0, int(centre+half), image.height))
        probe_data = probe.tobytes()
        y_counts = [sum(probe_data[y*probe.width:(y+1)*probe.width])//255 for y in range(image.height)]
        row_cuts = [round(r*image.height/4) for r in range(5)]
        for threshold in [1, 3, 5, 8]:
            found, start = [], None
            for y, value in enumerate(y_counts+[0]):
                if value >= threshold and start is None: start = y
                if value < threshold and start is not None:
                    if y-start > image.height*.07: found.append((start, y))
                    start = None
            if len(found) == 4:
                row_cuts = [0]+[(found[i][1]+found[i+1][0])//2 for i in range(3)]+[image.height]
                break
        rows = []
        for row in range(4):
            y0, y1 = row_cuts[row:row+2]
            band = alpha.crop((0, y0, image.width, y1))
            projection = list(band.getprojection()[0]) + [0]
            runs, start = [], None
            for x, occupied in enumerate(projection):
                if occupied and start is None: start = x
                if not occupied and start is not None:
                    if x-start >= image.width * 0.018: runs.append((start, x))
                    start = None
            if len(runs) != columns:
                # A thin sword tip or aura can bridge two figures. Find their
                # dense silhouettes, then divide only in the transparent/FX valley.
                pixels = band.tobytes()
                counts = [sum(pixels[x::image.width])//255 for x in range(image.width)]
                for threshold in [3, 5, 8, 12, 16, 20, 26, 32, 40]:
                    dense, start = [], None
                    for x, value in enumerate(counts+[0]):
                        if value >= threshold and start is None: start = x
                        if value < threshold and start is not None:
                            if x-start >= image.width*.012: dense.append((start, x))
                            start = None
                    if len(dense) >= columns:
                        dense = sorted(sorted(dense, key=lambda span: sum(counts[span[0]:span[1]]), reverse=True)[:columns])
                        cuts = [0] + [(dense[i][1]+dense[i+1][0])//2 for i in range(columns-1)] + [image.width]
                        runs = list(zip(cuts, cuts[1:]))
                        break
                while len(runs) < columns:
                    left, right = max(runs, key=lambda span: span[1]-span[0])
                    margin = int(image.width/columns*.35)
                    if right-left < 2*margin: break
                    mid = (left+right)/2
                    split = min(range(left+margin, right-margin), key=lambda x: counts[x] + abs(x-mid)*.005)
                    runs.remove((left, right));runs.extend([(left, split), (split, right)]);runs.sort()
                if len(runs) != columns:
                    raise ValueError(f'{path.name}: row {row}: expected {columns} separate poses, found {len(runs)}; inspect source before exporting')
            cells = []
            for left, right in runs:
                b = band.crop((left, 0, right, band.height)).getbbox()
                cells.append([left+b[0], y0+b[1], left+b[2], y0+b[3]])
            rows.append(cells)
        return {'width': image.width, 'height': image.height, 'rows': rows}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--actors', nargs='+', choices=ACTORS, default=ACTORS)
    parser.add_argument('--libresprite', default='D:/descargas/libresprite-development-windows-x86_64/libresprite.exe')
    parser.add_argument('--overwrite-edits', action='store_true')
    args = parser.parse_args()
    WORK.mkdir(exist_ok=True, parents=True)
    (OUT/'sources').mkdir(exist_ok=True, parents=True)
    (OUT/'sources/.gdignore').write_text('')
    (OUT/'references/.gdignore').write_text('')
    old = json.loads((OUT/'provenance.json').read_text()) if (OUT/'provenance.json').exists() else {}
    hashes = old.get('sources_sha256', {})
    layout_path = OUT/'layout.json'
    layout = json.loads(layout_path.read_text()) if layout_path.exists() else {'columns': 8, 'animations': {}, 'actors': {}}
    clips = [(state+'_'+direction, count, fps, loop)
             for direction in DIRECTIONS for state, count, fps, loop in STATES]
    entries, cursor = [], 0
    for direction in DIRECTIONS:
        for state, count, fps, loop in STATES:
            key = state+'_'+direction
            layout['animations'][key] = {'frames': list(range(cursor, cursor+count)), 'fps': fps,
                                         'loop': loop, 'timing': TIMING.get(state, [1]*count),
                                         'min_unique_frames': MIN_FRAMES[state]}
            entries.extend({'state': state, 'direction': direction, 'pose': POSES[state][f],
                            'frame': f, 'count': count} for f in range(count))
            cursor += count
    for actor in args.actors:
        source = OUT/'sources'/f'{actor}.ase'
        if source.exists() and actor in hashes and not args.overwrite_edits:
            if hashlib.sha256(source.read_bytes()).hexdigest() != hashes[actor]:
                raise RuntimeError(f'{source.name}: manual edits preserved; export them or explicitly use --overwrite-edits')
        reference = OUT/'references'/f'{actor}.png'
        measurements = measure(reference)
        hero = actor.startswith('portador')
        size = 192 if hero else 320
        body_height = 70 if hero else (116 if actor == 'prefecto' else 144)
        anchor = [size//2, 146 if hero else (228 if actor == 'prefecto' else 196)]
        sheets = {'base': {'reference': reference.as_posix(), 'measurements': measurements, 'reference_pose': 0, 'height_factor': 1}}
        actor_entries = [dict(e) for e in entries]
        for action in ['attack', 'dodge']:
            extra = OUT/'references'/f'{actor}_{action}.png'
            if extra.exists():
                sheets[action] = {'reference': extra.as_posix(), 'measurements': measure(extra, 4),
                                  'reference_pose': 3, 'height_factor': 0.72 if action == 'dodge' else 1}
        for entry in actor_entries:
            frame, state = entry['frame'], entry['state']
            if 'attack' in sheets and state == 'windup' and frame >= 2:
                entry.update(sheet='attack', pose=0 if frame < 4 else 1)
            if 'attack' in sheets and state == 'attack':
                entry.update(sheet='attack' if frame < 6 else 'base', pose=(2 if frame < 2 else 3) if frame < 6 else 0)
            if 'dodge' in sheets and state == 'dodge':
                entry.update(sheet='dodge' if frame < 5 else 'base', pose=[0,1,2,2,3,0][frame])
        settings = {'actor': actor, 'sheets': sheets,
                    'size': size, 'height': body_height, 'anchor': anchor,
                    'work': WORK.as_posix(), 'output': OUT.as_posix(), 'entries': actor_entries}
        blank(WORK/f'{actor}-painted.ase', size, clips,
              layer_names=['Pose completa', 'Retoques', 'Luz y efectos'])
        script = WORK/f'assemble-{actor}.js'
        script.write_text('var BUILD = '+json.dumps(settings)+';\n'+
                          (ROOT/'tools/libresprite_illustrated_combat.js').read_text(encoding='utf-8'), encoding='utf-8')
        run = subprocess.run([args.libresprite, '--batch', '--script', str(script)],
                             cwd=ROOT, capture_output=True, timeout=600)
        log = (run.stdout+run.stderr).decode('utf-8', errors='replace')
        (WORK/f'{actor}-assembly.log').write_text(log, encoding='utf-8')
        if run.returncode or 'PAINTED_COMPLETE '+actor not in log:
            raise RuntimeError(f'Native assembly failed: {actor}; see .godot/combat-v2')
        bounds = re.search(r'PAINTED_BODY (\[[^\]]+\])', log)
        if not bounds: raise RuntimeError(f'Missing native measurements: {actor}')
        export = subprocess.run([args.libresprite, '--batch', str(source), '--sheet-type', 'rows',
                                 '--sheet-width', str(size*8), '--sheet', str(OUT/f'{actor}.png'),
                                 '--data', str(WORK/f'{actor}-export.json'), '--list-tags', '--format', 'json-array'],
                                capture_output=True, timeout=180)
        if export.returncode: raise RuntimeError(f'Native export failed: {actor}')
        exported = json.loads((WORK/f'{actor}-export.json').read_text())
        assert len(exported['frames']) == cursor and len(exported['meta']['frameTags']) == len(clips)
        layout['actors'][actor] = {'cell': size, 'anchor': anchor, 'render_scale': 0.65 if actor in ['recaudador', 'caldera', 'coro'] else 0.5,
                                   'camera': 'lateral' if actor == 'portador' else 'three_quarter',
                                   'texture': f'res://assets/combat/illustrated/{actor}.png',
                                   'source': f'res://assets/combat/illustrated/sources/{actor}.ase',
                                   'idle_body_bounds': json.loads(bounds[1]),
                                   'key_poses': 48+16*(len(sheets)-1), 'directions': DIRECTIONS,
                                   'pose_sheets': list(sheets),
                                   'locomotion': 'native_joint_mesh_8' if actor not in ['recaudador', 'caldera', 'coro'] else 'painted_chassis'}
        hashes[actor] = hashlib.sha256(source.read_bytes()).hexdigest()
        layout_path.write_text(json.dumps(layout, indent=2)+'\n')
        (OUT/'provenance.json').write_text(json.dumps({'tool': 'LibreSprite',
            'visual_base': 'OpenAI image_gen, manga identity references and original action key poses',
            'pipeline': 'Read-only alpha measurement; native LibreSprite registration, eight-pose textured hip/knee/foot meshes, counter-swing, breathing, effects and ASE/PNG export.',
            'source': 'tools/libresprite_illustrated_combat.js', 'sources_sha256': hashes,
            'external_raster_inputs': sorted('references/'+p.name for p in (OUT/'references').glob('*.png')),
            'timeline_frames_per_actor': cursor, 'unique_source_poses': {a:v['key_poses'] for a,v in layout['actors'].items()},
            'note': 'Timeline holds and secondary poses reuse artwork. 256 timeline frames are NOT 256 independently painted poses.'}, indent=2)+'\n')
        print(f'{actor}: {layout["actors"][actor]["key_poses"]} painted poses; {cursor} timeline frames; scale {layout["actors"][actor]["render_scale"]}', flush=True)


if __name__ == '__main__':
    main()
