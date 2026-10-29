"""Read-only measurements, then native LibreSprite compositing and export."""
import json
import argparse
import hashlib
import subprocess
from collections import deque
from pathlib import Path
from PIL import Image
from ase_document import ROOT, blank

WORK = ROOT / 'build/art-depth'
LIBRESPRITE = 'D:/descargas/libresprite-development-windows-x86_64/libresprite.exe'
ZONES = ['periphery_alive_v2', 'foundry', 'flooded', 'citadel', 'network']
HULLS = [
    [[0,.26],[.06,.26],[.08,.07],[.12,.07],[.14,.27],[.20,.29],[.24,.39],[.31,.38],[.36,.13],[.39,.13],[.42,.37],[.47,.42],[.59,.36],[.62,.20],[.65,.20],[.68,.35],[.80,.34],[.83,.17],[.86,.17],[.91,.29],[1,.28]],
    [[0,.30],[.07,.30],[.08,.12],[.12,.12],[.15,.23],[.22,.12],[.26,.12],[.30,.33],[.37,.37],[.45,.34],[.48,.39],[.61,.37],[.64,.28],[.69,.28],[.72,.42],[.84,.36],[.88,.10],[.96,.07],[1,.18]],
    [[0,.05],[.11,.12],[.15,.33],[.17,.44],[.25,.48],[.34,.47],[.40,.29],[.47,.26],[.49,.41],[.55,.46],[.68,.51],[.72,.08],[.78,.06],[.81,.37],[.86,.34],[.91,.16],[.96,.18],[1,.42]],
    [[0,.08],[.10,.12],[.16,.23],[.22,.33],[.31,.36],[.44,.30],[.52,.42],[.57,.26],[.63,.16],[.69,.20],[.71,0],[.80,0],[.88,.08],[.96,.04],[1,0]],
    [[0,0],[.12,0],[.15,.17],[.21,.30],[.31,.30],[.39,.21],[.46,.09],[.55,.08],[.61,.25],[.68,.32],[.78,.29],[.84,.12],[.89,0],[1,0]],
]

def components(path):
    with Image.open(path) as image:
        width, height = image.size
        alpha = image.getchannel('A').tobytes()
    seen = bytearray(width * height)
    parts = []
    for start, value in enumerate(alpha):
        if value < 160 or seen[start]: continue
        queue = deque([start]); seen[start] = 1
        box = [width, height, 0, 0]; count = 0
        while queue:
            at = queue.popleft(); x, y = at % width, at // width; count += 1
            box = [min(box[0],x), min(box[1],y), max(box[2],x+1), max(box[3],y+1)]
            for xx, yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                nxt = yy * width + xx
                if xx<0 or xx>=width or yy<0 or yy>=height or seen[nxt] or alpha[nxt]<160: continue
                seen[nxt]=1; queue.append(nxt)
        if count > 20000: parts.append({'box':box,'seed':[start%width,start//width]})
    parts.sort(key=lambda part:part['box'][1])
    if len(parts) != 6: raise ValueError('Expected six isolated ornamental frames')
    return parts

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--libresprite',default=LIBRESPRITE)
    parser.add_argument('--overwrite-edits',action='store_true')
    args=parser.parse_args()
    WORK.mkdir(parents=True, exist_ok=True)
    ui = ROOT/'assets/ui/frames'; backgrounds=ROOT/'assets/world/backgrounds'
    entries=[]
    slots=[(82,122),(249,292),(412,451),(583,623),(759,799),(925,960)]
    for index, part in enumerate(components(ui/'references/ornate_kit.png')):
        name=['recaudador','caldera','coro','prefecto','madre','portador'][index]
        entries.append({'kind':'frame','name':name,'input':(ui/'references/ornate_kit.png').as_posix(),
                        'size':[400,42] if index==5 else [996,88], 'part':part,'slot':slots[index],
                        'ase':(ui/'sources'/f'{name}.ase').as_posix(),'png':(ui/f'{name}.png').as_posix()})
    for index, name in enumerate(ZONES):
        alpha_input = name != 'periphery_alive_v2'
        filename = f'{name}_plate.png' if alpha_input else f'{name}.png'
        entries.append({'kind':'background','name':name,'input':(backgrounds/'references'/filename).as_posix(), 'alpha_input':alpha_input,
                        'size':[1024,576],'hull':HULLS[index],
                        'ase':(backgrounds/'sources'/f'{name}.ase').as_posix(),'png':(backgrounds/'layers'/f'{name}.png').as_posix()})
    entries.append({'kind':'skyline','name':'far_skyline','input':(backgrounds/'references/far_skyline.png').as_posix(),
                    'size':[1024,342],'ase':(backgrounds/'sources/far_skyline.ase').as_posix(),
                    'png':(backgrounds/'layers/far_skyline.png').as_posix()})
    for folder in [ui/'sources',ui/'references',backgrounds/'sources',backgrounds/'references']:
        folder.mkdir(parents=True,exist_ok=True); (folder/'.gdignore').write_text('')
    driver=(ROOT/'tools/art/libresprite_environment.js').read_text(encoding='utf-8')
    provenance_path=backgrounds/'layers/provenance.json'
    prior=json.loads(provenance_path.read_text()) if provenance_path.exists() else {}
    hashes=prior.get('sources_sha256',{})
    for entry in entries:
        source=Path(entry['ase']);key=source.relative_to(ROOT).as_posix()
        if source.exists() and key in hashes and not args.overwrite_edits:
            if hashlib.sha256(source.read_bytes()).hexdigest()!=hashes[key]: raise RuntimeError(key+': manual edits preserved')
        target=WORK/(entry['name']+'-'+entry['kind']+'.ase')
        blank(target,entry['size'][0],[('art',1,1,False)],height=entry['size'][1])
        entry['template']=target.as_posix()
        script=WORK/(entry['name']+'-'+entry['kind']+'.js')
        script.write_text('var BUILD = '+json.dumps(entry)+';\n'+driver,encoding='utf-8')
        run=subprocess.run([args.libresprite,'--batch','--script',str(script)],capture_output=True,timeout=180)
        transcript=(run.stdout+run.stderr).decode('utf-8',errors='replace')
        (WORK/(entry['name']+'-'+entry['kind']+'.log')).write_text(transcript,encoding='utf-8')
        if 'ENVIRONMENT_COMPLETE' not in transcript: raise RuntimeError(entry['name']+': native assembly failed')
        run=subprocess.run([args.libresprite,'--batch',entry['ase'],'--save-as',entry['png']],capture_output=True,timeout=120)
        if run.returncode: raise RuntimeError(entry['name']+': PNG export failed')
        hashes[key]=hashlib.sha256(source.read_bytes()).hexdigest()
        print(entry['kind']+': '+entry['name'],flush=True)
    (ui/'layout.json').write_text(json.dumps({'boss_window':[80,44,836,18],'player_window':[32,14,336,14],
        'boss_size':[996,88],'player_size':[400,42],'scale':0.5},indent=2)+'\n')
    (backgrounds/'layers/layout.json').write_text(json.dumps({'depth_scales':[0.10,0.34,0.62],
        'zones':ZONES,'source':'tools/art/libresprite_environment.js','factory_sky_seed_envelopes':HULLS[0]},indent=2)+'\n')
    provenance_path.write_text(json.dumps({'tool':'LibreSprite', 'raster_inputs':'OpenAI image_gen: original ornamental atlas, distant skyline and four transparent architecture edits; existing periphery artwork.',
        'sources_sha256':hashes,'processing':'Native RGBA masks, registered frame apertures, alpha plate sampling and ASE/PNG export.',
        'inputs':[Path(e['input']).relative_to(ROOT).as_posix() for e in entries]},indent=2)+'\n')

if __name__=='__main__': main()
