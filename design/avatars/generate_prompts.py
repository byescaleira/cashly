import colorsys
import json
from pathlib import Path

PALETTE = {
    "cherry": "B23A48", "rust": "B5482F", "terracotta": "C8693F", "dustyRose": "C47C86", "salmon": "DB8B6E",
    "burntOrange": "C2602A", "tangerine": "E08A2E", "caramel": "B67D3E", "mustard": "C9962B", "sunflower": "DDB040",
    "avocado": "8A9A3A", "olive": "6B7D35", "moss": "5C7A4E", "sage": "8EA389", "mint": "5FA894",
    "teal": "2E7D74", "turquoise": "3A9AA0", "denim": "466A93", "sky": "6F9BC4", "indigo": "5A5F9E",
    "plum": "85506F", "lavender": "9C88B8", "eggplant": "6D4A72", "coffee": "8A6246", "sand": "BFA27A", "slate": "6E6A66",
}

NAMES = {
    "cherry": "cherry red", "rust": "rust red", "terracotta": "terracotta", "dustyRose": "dusty rose",
    "salmon": "salmon", "burntOrange": "burnt orange", "tangerine": "tangerine", "caramel": "caramel",
    "mustard": "mustard yellow", "sunflower": "sunflower yellow", "avocado": "avocado green", "olive": "olive green",
    "moss": "moss green", "sage": "sage green", "mint": "mint green", "teal": "teal", "turquoise": "turquoise",
    "denim": "denim blue", "sky": "sky blue", "indigo": "indigo", "plum": "plum", "lavender": "lavender",
    "eggplant": "eggplant purple", "coffee": "coffee brown", "sand": "sand beige", "slate": "slate gray",
}


def muted(hex_value):
    r, g, b = (int(hex_value[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, min(l * 1.06, 0.92), s * 0.82)
    return "".join(f"{round(c * 255):02X}" for c in (r, g, b))


SECTIONS = [
    ("classics", "Clássicos", "Classics", [
        ("cat", "gato", "warm ginger orange", "cream white", "denim"),
        ("puppy", "cachorro", "golden tan", "chocolate brown", "sky"),
        ("rabbit", "coelho", "soft gray", "pale pink", "mint"),
        ("bear cub", "urso", "chestnut brown", "light beige", "sage"),
        ("panda", "panda", "off-white", "charcoal black", "avocado"),
        ("fox", "raposa", "bright orange", "cream white", "teal"),
        ("hamster", "hamster", "honey beige", "cream white", "lavender"),
        ("koala", "coala", "cool gray", "light pink", "olive"),
        ("penguin", "pinguim", "navy black", "white", "turquoise"),
        ("lion cub", "leão", "golden yellow", "rust orange", "plum"),
    ]),
    ("brazil", "Brasil", "Brazil", [
        ("capybara", "capivara", "warm brown", "dark brown", "mint"),
        ("toucan", "tucano", "jet black", "bright orange", "sky"),
        ("golden lion tamarin", "mico-leão-dourado", "golden orange", "dark brown", "moss"),
        ("armadillo", "tatu", "taupe gray", "light beige", "sunflower"),
        ("jaguar cub", "onça-pintada", "golden yellow", "dark brown", "teal"),
        ("hyacinth macaw", "arara-azul", "cobalt blue", "bright yellow", "terracotta"),
        ("sloth", "preguiça", "light brown", "cream beige", "sage"),
        ("pink river dolphin", "boto-cor-de-rosa", "bubblegum pink", "light gray", "denim"),
        ("giant anteater", "tamanduá-bandeira", "gray brown", "black", "mustard"),
        ("coati", "quati", "rusty brown", "cream white", "lavender"),
    ]),
    ("savers", "Poupadores", "Savers", [
        ("piglet", "porquinho", "pastel pink", "rose pink", "teal"),
        ("squirrel", "esquilo", "russet orange", "cream white", "olive"),
        ("beaver", "castor", "chocolate brown", "light tan", "sky"),
        ("bumblebee", "abelha", "sunny yellow", "black", "indigo"),
        ("ant", "formiga", "brick red", "dark maroon", "sand"),
        ("owl", "coruja", "warm brown", "cream beige", "eggplant"),
        ("camel", "camelo", "sandy tan", "light cream", "turquoise"),
        ("tortoise", "jabuti", "leaf green", "olive brown", "salmon"),
        ("kangaroo", "canguru", "reddish tan", "light beige", "denim"),
        ("magpie", "pega", "glossy black", "white", "mustard"),
    ]),
    ("ocean", "Oceano", "Ocean", [
        ("octopus", "polvo", "coral pink", "light peach", "denim"),
        ("whale", "baleia", "deep blue", "light gray", "sunflower"),
        ("dolphin", "golfinho", "steel blue", "pale gray", "salmon"),
        ("seal pup", "foca", "silver gray", "white", "teal"),
        ("pufferfish", "baiacu", "lemon yellow", "cream white", "sky"),
        ("crab", "caranguejo", "tomato red", "light orange", "mint"),
        ("jellyfish", "água-viva", "lilac purple", "pale pink", "indigo"),
        ("sea otter", "lontra-marinha", "brown", "cream beige", "turquoise"),
        ("clownfish", "peixe-palhaço", "bright orange", "white", "denim"),
        ("manta ray", "arraia", "dark slate blue", "white", "sand"),
    ]),
    ("farm", "Fazenda", "Farm", [
        ("cow", "vaca", "white", "black", "avocado"),
        ("chick", "pintinho", "sunny yellow", "orange", "sky"),
        ("sheep", "ovelha", "fluffy white", "charcoal gray", "sage"),
        ("goat", "cabra", "light gray", "taupe", "mustard"),
        ("duckling", "patinho", "pale yellow", "orange", "denim"),
        ("horse", "cavalo", "chestnut brown", "dark brown", "mint"),
        ("donkey", "burro", "dove gray", "white", "terracotta"),
        ("rooster", "galo", "rust red", "golden yellow", "teal"),
        ("turkey", "peru", "brown", "red", "sand"),
        ("llama", "lhama", "cream white", "light brown", "lavender"),
    ]),
    ("savanna", "Savana", "Savanna", [
        ("elephant", "elefante", "cool gray", "pale pink", "sunflower"),
        ("giraffe", "girafa", "golden yellow", "brown", "sky"),
        ("zebra", "zebra", "white", "black", "salmon"),
        ("hippo", "hipopótamo", "lavender gray", "pink", "teal"),
        ("rhino", "rinoceronte", "slate gray", "light gray", "mustard"),
        ("tiger cub", "tigre", "orange", "black", "moss"),
        ("monkey", "macaco", "brown", "peach beige", "turquoise"),
        ("flamingo", "flamingo", "flamingo pink", "black", "mint"),
        ("ostrich", "avestruz", "black", "light pink", "sky"),
        ("meerkat", "suricato", "sandy beige", "dark brown", "plum"),
    ]),
    ("cold", "Frio", "Cold", [
        ("polar bear cub", "urso-polar", "snow white", "light blue gray", "teal"),
        ("arctic fox", "raposa-do-ártico", "white", "pale gray", "indigo"),
        ("wolf pup", "lobo", "gray", "white", "sunflower"),
        ("raccoon", "guaxinim", "gray", "black", "sage"),
        ("moose", "alce", "dark brown", "tan", "sky"),
        ("fawn", "filhote de cervo", "warm tan", "white", "moss"),
        ("walrus", "morsa", "brown", "ivory white", "turquoise"),
        ("snowy owl", "coruja-das-neves", "white", "golden yellow", "denim"),
        ("reindeer", "rena", "brown", "cream", "cherry"),
        ("red panda", "panda-vermelho", "rust orange", "white", "teal"),
    ]),
    ("tiny", "Pequeninos", "Tiny Friends", [
        ("mouse", "ratinho", "light gray", "pink", "sunflower"),
        ("frog", "sapo", "lime green", "pale yellow", "plum"),
        ("snail", "caracol", "cream yellow", "terracotta orange", "sage"),
        ("butterfly", "borboleta", "violet purple", "sky blue", "sand"),
        ("caterpillar", "lagarta", "leaf green", "yellow", "terracotta"),
        ("ladybug", "joaninha", "red", "black", "mint"),
        ("axolotl", "axolote", "pastel pink", "magenta", "teal"),
        ("guinea pig", "porquinho-da-índia", "ginger", "white", "lavender"),
        ("hedgehog", "ouriço", "brown", "cream beige", "sky"),
        ("chameleon", "camaleão", "teal green", "yellow", "salmon"),
    ]),
    ("birds", "Aves", "Birds", [
        ("parrot", "papagaio", "green", "red", "sand"),
        ("hummingbird", "beija-flor", "emerald green", "magenta", "sky"),
        ("pelican", "pelicano", "white", "orange", "denim"),
        ("swan", "cisne", "white", "orange", "dustyRose"),
        ("peacock", "pavão", "royal blue", "teal green", "mustard"),
        ("canary", "canário", "lemon yellow", "orange", "indigo"),
        ("pigeon", "pombo", "blue gray", "lilac", "sunflower"),
        ("seagull", "gaivota", "white", "light gray", "turquoise"),
        ("kiwi bird", "kiwi", "brown", "beige", "avocado"),
        ("woodpecker", "pica-pau", "red", "black", "sage"),
    ]),
    ("fantasy", "Fantasia", "Fantasy", [
        ("baby dragon", "dragãozinho", "mint green", "cream yellow", "plum"),
        ("unicorn", "unicórnio", "white", "lilac", "sky"),
        ("friendly ghost", "fantasminha", "white", "light lavender", "indigo"),
        ("fluffy monster", "monstrinho", "turquoise", "white", "tangerine"),
        ("yeti", "yeti", "white", "light blue", "slate"),
        ("little alien", "alienzinho", "lime green", "dark green", "eggplant"),
        ("phoenix chick", "fênix", "flame orange", "golden yellow", "teal"),
        ("sea serpent", "serpente-do-mar", "teal blue", "pale yellow", "sand"),
        ("griffin chick", "grifo", "golden tan", "white", "denim"),
        ("baby kraken", "krakenzinho", "purple", "pink", "mint"),
    ]),
]

TEMPLATE = """Create one complete full-bleed 1:1 square image.
Background: fill the entire square with solid {bg_name} (#{bg_hex}). Keep {bg_name} visible in every open area and in the top corners.
Subject: place one extremely simplified, cute, endearing {subject} IP character on the background, reduced to one soft rounded continuous silhouette and one defining feature.
Complexity: use only 4–7 large basic shapes and at most two broad internal color regions. Use two simple eyes and add one tiny mouth only when it helps the expression. Remove every nonessential line, outline, anatomical detail, texture, and decoration. Keep the character readable at 32 × 32.
Color behavior: use exactly three semantic colors in the complete image: the two character colors {color1} and {color2}, plus the background color. Organize both character colors into broad purposeful masses and reuse them for facial marks.
Composition: keep the character upright, centered horizontally and rising from the bottom edge, shown from the chest up, with the head in the upper-middle of the square and fully inside a centered circle that touches the four edges. The character fills about 80–90% of the square and is cropped by the bottom edge. Preserve both paired identifying features.
Style: make simplification, cuteness, and lovable baby-like appeal the strongest qualities. Use large soft forms, compact proportions, thick rounded contours, and an ultra-clean graphic treatment. Prefer one clear shape over several explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only the character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text or watermark. Add no borders, frames, cards, or presentation masks. Include one character only, with no extra subjects or scenery. Use no fragile lines, sharp tips, unnecessary outlines, tiny details, or decorative marks. Add no photorealistic material, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow."""

root = Path(__file__).parent
manifest = []
lines = [
    "# Avatares do Cashly: prompts",
    "",
    "100 personagens em 10 seções, gerados com a skill `ip-as-logo` (s1dashu/ip-as-logo-skill) no Codex ou no ChatGPT.",
    "Composição adaptada para avatar circular: personagem centralizado, subindo pela base, cabeça dentro do círculo central.",
    "Fundo: cor da paleta `RetroColor` do app, levemente dessaturada.",
    "",
    "Salve cada imagem como PNG quadrado (1024 px ou maior) com o nome indicado em `design/avatars/generated/`.",
    "",
]
for key, title_pt, title_en, items in SECTIONS:
    lines += [f"## {title_pt} (`{key}`)", ""]
    for index, (subject, name_pt, color1, color2, bg) in enumerate(items, 1):
        file = f"{key}-{index:02d}-{subject.replace(' ', '-')}.png"
        bg_hex = muted(PALETTE[bg])
        prompt = TEMPLATE.format(
            subject=subject, color1=color1, color2=color2, bg_name=f"muted {NAMES[bg]}", bg_hex=bg_hex)
        manifest.append({
            "id": f"{key}-{index:02d}", "section": key, "sectionTitle": title_en, "subject": subject,
            "namePT": name_pt, "background": bg, "backgroundHex": bg_hex, "file": file, "prompt": prompt,
        })
        lines += [f"### {index:02d} · {name_pt} → `{file}`", "", "```text", prompt, "```", ""]

(root / "prompts.md").write_text("\n".join(lines))
(root / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
print(len(manifest), "prompts")
