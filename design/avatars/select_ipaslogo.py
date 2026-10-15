import collections
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent
CATALOG = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "ipaslogo-catalog.json"
DOWNLOADS = ROOT / "downloaded"

STOP = {
    "left", "right", "cheerful", "soft", "tiny", "warm", "smile", "sleepy", "bright", "eyed", "big", "small",
    "little", "baby", "bold", "happy", "cute", "round", "chubby", "calm", "gentle", "sweet", "peek", "cream",
    "twilight", "young", "friendly", "mini", "shy", "sunny", "cozy", "the", "a",
}

SECTIONS = [
    ("cats", "Cats", 22, 12, ["cat", "kitten", "lion", "tiger", "leopard", "cheetah", "lynx", "panther", "jaguar",
                             "cougar", "puma", "ocelot", "serval"]),
    ("dogs", "Dogs", 22, 12, ["dog", "puppy", "corgi", "shiba", "husky", "pug", "retriever", "beagle", "poodle",
                             "terrier", "dachshund", "bulldog", "collie", "shepherd", "spaniel", "akita",
                             "chihuahua", "samoyed", "dalmatian", "sheepdog"]),
    ("forest", "Forest", 22, 3, ["bear", "deer", "fawn", "fox", "raccoon", "squirrel", "hedgehog", "wolf", "badger",
                                "moose", "beaver", "chipmunk", "skunk", "elk", "reindeer", "porcupine", "boar",
                                "bison", "ibex"]),
    ("farm", "Farm", 22, 3, ["pig", "piglet", "cow", "calf", "sheep", "lamb", "goat", "ram", "horse", "pony",
                            "donkey", "chicken", "hen", "rooster", "alpaca", "llama", "turkey", "bull", "yak"]),
    ("ocean", "Ocean", 24, 2, ["seal", "octopus", "whale", "dolphin", "fish", "turtle", "tortoise", "crab", "otter",
                              "axolotl", "nautilus", "shark", "jellyfish", "walrus", "squid", "lobster", "shrimp",
                              "starfish", "manatee", "orca", "ray", "manta", "puffer", "pufferfish", "clownfish",
                              "seahorse", "narwhal", "koi", "coral"]),
    ("birds", "Birds", 22, 2, ["owl", "parrot", "bird", "chick", "duck", "duckling", "penguin", "toucan", "flamingo",
                              "eagle", "hawk", "sparrow", "pigeon", "swan", "goose", "crow", "raven", "robin",
                              "finch", "canary", "peacock", "pelican", "puffin", "hummingbird", "kiwi",
                              "woodpecker", "cockatoo", "macaw", "stork", "heron", "seagull", "gull", "ostrich",
                              "emu", "jay"]),
    ("jungle", "Jungle", 24, 2, ["monkey", "gorilla", "orangutan", "chimp", "lemur", "sloth", "panda", "koala",
                                "kangaroo", "giraffe", "elephant", "zebra", "hippo", "hippopotamus", "rhino",
                                "rhinoceros", "meerkat", "capybara", "tapir", "anteater", "armadillo", "camel",
                                "gibbon", "okapi", "wombat", "hyena", "pangolin", "crocodile", "alligator",
                                "glider"]),
    ("tiny", "Tiny Friends", 22, 2, ["hamster", "mouse", "rat", "gerbil", "guinea", "rabbit", "bunny", "hare", "frog",
                                    "toad", "bee", "ladybug", "snail", "butterfly", "caterpillar", "ant", "beetle",
                                    "chinchilla", "ferret", "mole", "bat", "gecko", "lizard", "chameleon", "snake",
                                    "spider", "dragonfly", "worm", "newt", "salamander", "firefly"]),
    ("fantasy", "Fantasy", 20, 3, ["dragon", "unicorn", "thunderbird", "phoenix", "griffin", "gryphon", "yeti",
                                  "kraken", "pegasus", "kirin", "qilin", "sphinx", "hydra", "basilisk", "chimera",
                                  "mermaid", "kitsune", "nessie", "sasquatch", "monster", "ghost", "alien", "spirit",
                                  "robot", "fairy", "troll", "goblin", "imp", "golem", "wisp"]),
]


def words(name):
    return re.findall(r"[a-z]+", name.lower())


def normalized(name):
    return " ".join(w for w in words(name) if w not in STOP)


items = json.loads(CATALOG.read_text())
pool = collections.defaultdict(list)
seen = set()
for item in sorted(items, key=lambda i: (len(words(i["name"])), i["id"])):
    if item["category"] not in ("animals", "other", "nature"):
        continue
    name = normalized(item["name"])
    if not name or name in seen:
        continue
    for key, _, _, _, keywords in SECTIONS:
        hit = next((w for w in name.split() if w in keywords or (w.endswith("s") and w[:-1] in keywords)), None)
        if hit:
            pool[key].append({**item, "base": hit})
            seen.add(name)
            break

manifest = []
for key, title, target, cap, _ in SECTIONS:
    used = collections.Counter()
    chosen = []
    for item in pool[key]:
        if used[item["base"]] >= cap:
            continue
        used[item["base"]] += 1
        chosen.append(item)
        if len(chosen) == target:
            break
    for index, item in enumerate(chosen, 1):
        manifest.append({
            "id": f"{key}-{index:02d}", "section": key, "sectionTitle": title, "name": item["name"],
            "source": "ipaslogo.com", "sourceID": item["id"], "slug": item["slug"],
            "url": "https://cdn.ipaslogo.com/display-512/" + item["storage_key"].split("/")[-1].replace(".png", ".webp"),
            "file": f"{key}-{index:02d}.webp",
        })
    print(key, len(chosen))

DOWNLOADS.mkdir(exist_ok=True)
for entry in manifest:
    target = DOWNLOADS / entry["file"]
    if not target.exists():
        subprocess.run(["curl", "-sfL", "-o", str(target), entry["url"]], check=True)
(ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
print(len(manifest), "avatares")
