"""Prepare native pose clips, sequentially respecting the configured MCP job limit.

Only temporary requests, signed links and downloads are stored under .godot/.
No account configuration or authentication is copied into the project.
"""
import json
import re
import subprocess
import sys
import time
import urllib.request
import urllib.error
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / '.godot/unit-art'
CHARACTER = 'bbe26193-5852-471a-a749-aa0138e7b1c9'
CLIPS = [
    ('caminar', 'walking-8-frames', None),
    ('reposo', 'breathing-idle', None),
    ('dano', 'taking-punch', None),
    ('caer', 'falling-back-death', None),
    ('cansancio', None, 'Exhausted standing idle loop, lowers the rifle, bends forward slightly, shoulders rise and fall with heavy breathing, wipes brow with one hand then returns to the starting pose. Feet remain planted. Preserve the same character.'),
    ('disparar', None, 'Standing in place facing right, carefully aims the rifle forward, fires a short burst with visible shoulder recoil, works the action and returns the rifle to ready. Feet remain planted, preserve the same rifle and character.'),
    ('reparar', None, 'Standing in place facing right, lowers the weapon, raises right hand above shoulder and makes three short hammering movements downward at waist height, then returns to the starting pose. Clear articulated elbow and wrist movement, feet planted, preserve character identity.'),
]


def request(name, arguments):
    source = WORK / 'job-request.json'
    result = WORK / 'job-response.json'
    source.write_text(json.dumps([{'name': name, 'arguments': arguments}]), encoding='utf-8')
    run = subprocess.run([sys.executable, str(ROOT / 'tools/integrations/pixellab_mcp.py'), str(source), str(result)],
                         cwd=ROOT, capture_output=True, timeout=90)
    if run.returncode:
        raise RuntimeError(run.stderr.decode('utf-8', errors='replace')[-800:])
    data = json.loads(result.read_text())[0]['response']
    return '\n'.join(c.get('text', '') for c in data.get('result', {}).get('content', []))


def download():
    config = json.loads((Path.home() / '.claude.json').read_text(encoding='utf-8'))['mcpServers']['pixellab']
    req = urllib.request.Request(f'https://api.pixellab.ai/mcp/characters/{CHARACTER}/download',
                                 headers=config.get('headers', {}))
    payload = urllib.request.urlopen(req, timeout=60).read()
    archive = WORK / 'native-clips.zip'
    archive.write_bytes(payload)
    with zipfile.ZipFile(archive) as source:
        for name in source.namelist():
            target = (WORK / 'native' / name).resolve()
            if not target.is_relative_to((WORK / 'native').resolve()):
                raise ValueError('Unsafe archive member')
        source.extractall(WORK / 'native')


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    receipt = WORK / 'clip-receipts.json'
    jobs = json.loads(receipt.read_text()) if receipt.exists() else {}
    existing = request('get_character', {'character_id': CHARACTER, 'include_preview': False})
    for name, template, action in CLIPS:
        if name in jobs:
            continue
        if re.search(r'(?m)^\s+' + re.escape(name) + r'\s.*\b\d+f\b', existing):
            jobs[name] = {'reused': True}
            receipt.write_text(json.dumps(jobs, indent=2), encoding='utf-8')
            print('Reusing completed clip:', name, flush=True)
            continue
        arguments = {'character_id': CHARACTER, 'directions': ['east'], 'animation_name': name}
        if template:
            arguments.update(mode='template', template_animation_id=template)
        else:
            arguments.update(mode='v3', action_description=action, frame_count=8, keep_first_frame=False)
        deadline = time.monotonic() + 900
        while True:
            text = request('animate_character', arguments)
            if 'job_ids:' in text:
                jobs[name] = {'arguments': arguments, 'receipt': text}
                receipt.write_text(json.dumps(jobs, indent=2), encoding='utf-8')
                print('Queued:', name, flush=True)
                break
            if not any(code in text for code in ['429', 'only 0 available']) or time.monotonic() > deadline:
                raise RuntimeError(text)
            print('Waiting for previous native clip:', name, flush=True)
            time.sleep(40)
    deadline = time.monotonic() + 900
    while True:
        status = request('get_character', {'character_id': CHARACTER, 'include_preview': False})
        (WORK / 'native-status.txt').write_text(status, encoding='utf-8')
        if re.search(r'reparar.*8f', status):
            try:
                download()
                print('Downloaded native clips', flush=True)
                return
            except urllib.error.HTTPError as error:
                if error.code != 423: raise
        if time.monotonic() > deadline:
            raise RuntimeError('Native clip timeout; receipts retained for safe resume')
        print('Waiting for final native clip', flush=True)
        time.sleep(40)


if __name__ == '__main__':
    main()
