"""Open a visible LibreSprite board and reveal its native pixel work in stages.

This is a GUI preview through LibreSprite's API, not a claim of mouse drawing.
Every run creates a new working document; it does not replace edited sources.
"""
import json
import subprocess
from datetime import datetime
from build_combat_sprites import ROOT, blank


def main():
    work = ROOT / '.godot/live-art'
    work.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = work / f'perspectiva_y_portador_{stamp}.ase'
    blank(filename, 640, [('modelo', 1, 6, True)], height=320)
    settings = {'file': filename.as_posix(), 'portrait': (ROOT / 'assets/story/portraits_manga_v2.png').as_posix(),
                'guardian': (ROOT / 'assets/units/animated/guardian.png').as_posix()}
    sources = '\n'.join((ROOT / 'tools' / name).read_text(encoding='utf-8')
                        for name in ['libresprite_combat.js', 'libresprite_projection.js'])
    driver = (ROOT / 'tools/libresprite_live_board.js').read_text(encoding='utf-8')
    script = work / f'live_{stamp}.js'
    script.write_text('var LIVE = ' + json.dumps(settings) + ';\n' + sources + '\n' + driver, encoding='utf-8')
    log = open(work / f'live_{stamp}.log', 'wb')
    process = subprocess.Popen(['D:/descargas/libresprite-development-windows-x86_64/libresprite.exe', '--script', str(script)],
                               cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    print('LibreSprite visible PID:', process.pid)
    print('Working document:', filename)


if __name__ == '__main__':
    main()
