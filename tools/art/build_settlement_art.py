"""Native LibreSprite sampling and pixel work, reusing the approved industrial family."""
import json
import subprocess
from pathlib import Path
from ase_document import ROOT, blank


def main():
    work = ROOT / 'build/art-settlements'
    work.mkdir(parents=True, exist_ok=True)
    output = ROOT / 'assets/world/settlements'
    sources = output / 'sources'
    sources.mkdir(parents=True, exist_ok=True)
    (sources / '.gdignore').write_text('')
    entries = []
    for name, width, height, count in [('ruins', 128, 144, 10), ('supports', 96, 96, 6), ('components', 24, 24, 3)]:
        source = sources / f'{name}.ase'
        if source.exists():
            raise RuntimeError(f'Preserving editable source: {source}')
        template = work / f'{name}-blank.ase'
        blank(template, width, [('variants', count, 1, False)], height=height)
        entries.append(dict(name=name, width=width, height=height, count=count, template=template.as_posix(),
                            ase=source.as_posix(), png=(output / f'{name}.png').as_posix()))
    bounds = json.loads((ROOT / 'data/art_bounds.gd').read_text(encoding='utf-8').split('const REGIONS: Dictionary =', 1)[1])
    build = dict(entries=entries, source=(ROOT / 'assets/world/structures/industrial_atlas_v2.png').as_posix(),
                 regions=bounds['res://assets/world/structures/industrial_atlas_v2.png'])
    utility = (ROOT / 'tools/art/libresprite_frontier.js').read_text().split('function rat(', 1)[0]
    script = work / 'draw.js'
    script.write_text('var BUILD = ' + json.dumps(build) + ';\n' + utility + (ROOT / 'tools/art/libresprite_settlements.js').read_text(), encoding='utf-8')
    libre = 'D:/descargas/libresprite-development-windows-x86_64/libresprite.exe'
    run = subprocess.run([libre, '--batch', '--script', str(script)], capture_output=True, timeout=120)
    transcript = (run.stdout + run.stderr).decode('utf-8', errors='replace')
    (work / 'native-art.log').write_text(transcript, encoding='utf-8')
    if 'SETTLEMENT_ART_COMPLETE' not in transcript:
        raise RuntimeError(transcript)
    for entry in entries:
        result = subprocess.run([libre, '--batch', entry['ase'], '--sheet-type', 'rows', '--sheet-width', str(entry['width'] * entry['count']), '--sheet', entry['png']], capture_output=True, timeout=60)
        if result.returncode:
            raise RuntimeError(result.stderr.decode(errors='replace'))
        print(entry['name'] + ': native ASE + PNG', flush=True)


if __name__ == '__main__':
    main()
