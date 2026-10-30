"""Author new pixel assets inside LibreSprite; Python creates blank documents only."""
import argparse
import json
import subprocess
from pathlib import Path
from ase_document import ROOT, blank


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--libresprite', default='D:/descargas/libresprite-development-windows-x86_64/libresprite.exe')
    parser.add_argument('--only', help='Create one new asset while preserving existing editable sources')
    args = parser.parse_args()
    work = ROOT / 'build/art-frontier'
    work.mkdir(parents=True, exist_ok=True)
    assets = [('rat', 32, 24, 8, 'assets/characters/pests'),
              ('trap', 32, 24, 3, 'assets/world/salvage'),
              ('battery', 32, 32, 1, 'assets/world/salvage'),
              ('antenna', 32, 48, 1, 'assets/world/salvage'),
              ('bag', 16, 16, 1, 'assets/ui/icons/frontier'),
              ('parts', 16, 16, 1, 'assets/world/salvage')]
    entries = []
    for name, width, height, count, folder in assets:
        if args.only and args.only != name:
            continue
        output = ROOT / folder
        sources = output / 'sources'
        sources.mkdir(parents=True, exist_ok=True)
        (sources / '.gdignore').write_text('')
        source = sources / f'{name}.ase'
        if source.exists():
            raise RuntimeError(f'Preserving existing editable source: {source}')
        template = work / f'{name}-blank.ase'
        blank(template, width, [('walk' if name == 'rat' else 'art', count, 12, True)], height=height)
        entries.append(dict(name=name, width=width, height=height, count=count,
                            template=template.as_posix(), ase=source.as_posix(),
                            png=(output / f'{name}.png').as_posix()))
    script = work / 'draw.js'
    script.write_text('var ENTRIES = ' + json.dumps(entries) + ';\n' + (ROOT / 'tools/art/libresprite_frontier.js').read_text(), encoding='utf-8')
    run = subprocess.run([args.libresprite, '--batch', '--script', str(script)], capture_output=True, timeout=120)
    transcript = (run.stdout + run.stderr).decode('utf-8', errors='replace')
    (work / 'native-art.log').write_text(transcript, encoding='utf-8')
    if 'FRONTIER_ART_COMPLETE' not in transcript:
        raise RuntimeError(transcript)
    for entry in entries:
        run = subprocess.run([args.libresprite, '--batch', entry['ase'], '--sheet-type', 'rows',
                              '--sheet-width', str(entry['width'] * entry['count']), '--sheet', entry['png']], capture_output=True, timeout=60)
        if run.returncode:
            raise RuntimeError(run.stderr.decode(errors='replace'))
        print(entry['name'] + ': editable ASE + PNG', flush=True)


if __name__ == '__main__':
    main()
