"""Uso: integrar2.py ZIP REPO ASSET_DIR TRES 'nombre:fps:loop[:origen],...'
Copia las animaciones (dirección east) del zip de PixelLab y genera un SpriteFrames."""
import io, os, re, sys, zipfile
from PIL import Image
PAD = 64  # lienzo común: los cuadros vienen en 48, 56 o 64 px, centrados en el pivote

ZIP, REPO, ASSET_DIR, TRES, SPEC = sys.argv[1:6]
anims_spec = []
for item in SPEC.split(","):
    parts = item.split(":")
    anims_spec.append((parts[0], float(parts[1]), parts[2] == "1", parts[3] if len(parts) > 3 else parts[0]))

z = zipfile.ZipFile(ZIP)
found = {}
for n in z.namelist():
    m = re.match(r"[^/]+/animations/([^/]+)/east/frame_(\d+)\.png$", n)
    if m:
        found.setdefault(m.group(1), []).append(n)

ext, anims = [], []
for name, fps, loop, source in anims_spec:
    if source not in found:
        sys.exit(f"falta la animación {source}")
    safe = name.replace("ñ", "n")
    folder = os.path.join(REPO, ASSET_DIR, safe)
    os.makedirs(folder, exist_ok=True)
    frames = []
    for i, n in enumerate(sorted(found[source])):
        im = Image.open(io.BytesIO(z.read(n))).convert("RGBA")
        canvas = Image.new("RGBA", (PAD, PAD), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((PAD - im.width) // 2, (PAD - im.height) // 2))
        canvas.save(os.path.join(folder, f"{safe}_{i:02d}.png"))
        if name == "reposo" and i == 0:
            print("posición sugerida del sprite: Vector2(0, %d)" % -(canvas.getbbox()[3] - PAD // 2))
        ext.append(f'[ext_resource type="Texture2D" path="res://{ASSET_DIR}/{safe}/{safe}_{i:02d}.png" id="{len(ext) + 1}"]')
        frames.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{len(ext)}")\n}}')
    anims.append(f'{{\n"frames": [{", ".join(frames)}],\n"loop": {"true" if loop else "false"},\n"name": &"{"daño" if name == "dano" else name}",\n"speed": {fps:.1f}\n}}')
    print(name, len(frames), "cuadros")

with open(os.path.join(REPO, TRES), "w", encoding="utf-8", newline="\n") as f:
    f.write(f'[gd_resource type="SpriteFrames" load_steps={len(ext) + 1} format=3]\n\n')
    f.write("\n".join(ext) + "\n\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
print("escrito", TRES)
