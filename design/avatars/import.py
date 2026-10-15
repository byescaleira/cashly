import json
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).parent
repo = root.parents[1]
catalog = repo / "CashlyKit/Sources/CashlyResource/Assets/Media.xcassets/Avatars"
size = int(sys.argv[1]) if len(sys.argv) > 1 else 512
manifest = json.loads((root / "manifest.json").read_text())
generated = root / "generated"

missing = [item["file"] for item in manifest if not (generated / item["file"]).exists()]
if missing:
    print(f"{len(missing)} imagens faltando em {generated}:")
    for file in missing:
        print(" -", file)
    sys.exit(1)

shutil.rmtree(catalog, ignore_errors=True)
catalog.mkdir(parents=True)
(catalog / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
for item in manifest:
    folder = catalog / f"avatar-{item['id']}.imageset"
    folder.mkdir()
    target = folder / f"avatar-{item['id']}.png"
    subprocess.run(
        ["sips", "-s", "format", "png", "-Z", str(size), str(generated / item["file"]), "--out", str(target)],
        check=True, capture_output=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": target.name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2))
total = sum(p.stat().st_size for p in catalog.rglob("*.png"))
print(f"{len(manifest)} avatares importados em {catalog} ({total / 1_048_576:.1f} MB, {size} px)")
