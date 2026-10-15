import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent
CATALOG = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "ipaslogo-catalog.json"
DOWNLOADS = ROOT / "downloaded"
TARGET = 20

NAMES = [
    "Lion Warm Smile", "Golden Retriever Puppy", "Peacock", "Golden Fox", "Sunflower Lion Cub",
    "Honey Brown Bear", "Swan", "Emperor Penguin", "Golden Hamster", "Coral Crown Turtle",
    "Lion Bright Eyed", "Golden Squirrel", "Amber Beetle Knight", "Sun Bear", "Jewel Beetle",
    "Cavalier King Charles Spaniel Dog", "Honey Comet Bear", "Amber Golem", "Lion Gentle Smile",
    "Knight", "Mushroom Knight", "Honey Badger", "Lion Calm", "Golden Retriever",
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
