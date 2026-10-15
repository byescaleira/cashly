import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent
CATALOG = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "ipaslogo-catalog.json"
DOWNLOADS = ROOT / "downloaded"
TARGET = 20

NAMES = [
    "Sunflower Lion Cub",
    "Golden Fox",
    "Golden Retriever Puppy",
    "Happy Hamster",
    "Tiger Soft Peek",
    "Shiba Inu",
    "Baby Giraffe",
    "Golden Squirrel",
    "Yellow Chick",
    "Pomeranian Dog",
    "Amber Golem",
    "Corgi",
    "Duckling",
    "A8 Team Bee",
    "Sun Bear",
    "Bat Eared Fox",
    "Camel",
    "Yellow Boxfish",
    "Honey Comet Bear",
    "Labrador Retriever",
]

items = json.loads(CATALOG.read_text())
manifest = [entry for entry in json.loads((ROOT / "manifest.json").read_text())
            if entry["section"] != "gold"]
used = {entry["sourceID"] for entry in manifest}
chosen = []
for name in NAMES:
    match = next((item for item in items if item["name"] == name and item["id"] not in used), None)
    if match:
        chosen.append(match)
        used.add(match["id"])
    if len(chosen) == TARGET:
        break

for index, item in enumerate(chosen, 1):
    manifest.append({
        "id": f"gold-{index:02d}", "section": "gold", "sectionTitle": "Gold", "name": item["name"],
        "source": "ipaslogo.com", "sourceID": item["id"], "slug": item["slug"],
        "url": "https://cdn.ipaslogo.com/display-512/" + item["storage_key"].split("/")[-1].replace(".png", ".webp"),
        "file": f"gold-{index:02d}.webp",
    })

DOWNLOADS.mkdir(exist_ok=True)
for entry in manifest:
    target = DOWNLOADS / entry["file"]
    if entry["section"] == "gold" and not target.exists():
        subprocess.run(["curl", "-sfL", "-o", str(target), entry["url"]], check=True)
(ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
print("gold", len(chosen))
