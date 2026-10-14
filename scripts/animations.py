#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile

W, H, FPS, END = 320, 180, 60, 150
CX, CY = W / 2, H / 2
ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "animations")
SWIFT = os.path.join(ROOT, "..", "CashlyKit/Sources/CashlyResource/CashlyResourceAnimation.swift")
PREVIEW = os.path.join(ROOT, "animations-preview.html")
SYMBOL_SOURCE = os.path.join(ROOT, "symbols.swift")
SYMBOL_MAP = os.path.join(ROOT, "symbols-map.json")

# EASE is a fluid ease-in-out with a soft landing; SNAP leaves quickly.
EASE = ((0.2, 1.0), (0.4, 0.0))
SNAP = ((0.1, 1.0), (0.6, 0.0))

PALETTE = {
    "olive": (0x5F, 0x7A, 0x2E), "mustard": (0xB8, 0x84, 0x1C), "rust": (0xA6, 0x3D, 0x2C),
    "orange": (0xC2, 0x60, 0x2A), "teal": (0x2A, 0x70, 0x69), "denim": (0x3D, 0x5F, 0x86),
    "plum": (0x74, 0x41, 0x5F), "brown": (0x7E, 0x55, 0x36), "tint": (0xC2, 0x60, 0x2A),
    "ink": (0x1C, 0x1C, 0x1E), "paper": (0xFF, 0xFF, 0xFF), "cream": (0xF0, 0xE6, 0xD2),
}

GLYPHS = {}
MISSING = set()


# --- SF Symbol outlines ---------------------------------------------------------------------


def symbols_binary():
    binary = os.path.join(tempfile.gettempdir(), "cashly-symbols")
    if not os.path.exists(binary) or os.path.getmtime(binary) < os.path.getmtime(SYMBOL_SOURCE):
        subprocess.run(["swiftc", "-O", "-o", binary, SYMBOL_SOURCE], check=True)
    return binary


def load_glyphs(weight, names):
    with tempfile.NamedTemporaryFile(suffix=".json") as handle:
        subprocess.run([symbols_binary(), weight, SYMBOL_MAP, handle.name, *sorted(names)], check=True)
        with open(handle.name) as output:
            GLYPHS.setdefault(weight, {}).update(json.load(output))


def scaled_path(part, factor):
    def points(values):
        return [[round(x * factor, 2), round(y * factor, 2)] for x, y in values]
    return {"c": part["c"], "v": points(part["v"]), "i": points(part["i"]), "o": points(part["o"])}


def symbol(name, color, height, weight="Semibold", opacity=100, position=(0, 0), rotation=0, flip=False):
    glyph = GLYPHS.get(weight, {}).get(name)
    if glyph is None:
        MISSING.add((weight, name))
        return group([], name)
    factor = height / glyph["h"]
    shapes = [{"ty": "sh", "d": 1, "ks": const(scaled_path(part, factor))} for part in glyph["paths"]]
    scale = const([-100 if flip else 100, 100])
    return group(shapes + [fill(color, opacity), transform(position, scale=scale, rotation=const(rotation))], name)


# --- Lottie primitives ----------------------------------------------------------------------


def rgb(name):
    r, g, b = PALETTE[name]
    return [r / 255, g / 255, b / 255, 1]


def const(value):
    return {"a": 0, "k": value}


def anim(frames, ease=EASE):
    keys = []
    for index, frame in enumerate(frames):
        time, value = frame[0], frame[1]
        segment = frame[2] if len(frame) > 2 else ease
        values = value if isinstance(value, list) else [value]
        key = {"t": round(time), "s": values}
        if index < len(frames) - 1:
            key["i"] = {"x": [segment[0][0]] * len(values), "y": [segment[0][1]] * len(values)}
            key["o"] = {"x": [segment[1][0]] * len(values), "y": [segment[1][1]] * len(values)}
        keys.append(key)
    return {"a": 1, "k": keys}


def move(frames, ease=EASE):
    return anim([(frame[0], [frame[1][0], frame[1][1], 0], *frame[2:]) for frame in frames], ease)


def fill(color, opacity=100):
    return {"ty": "fl", "c": const(rgb(color)), "o": const(opacity), "r": 1}


def transform(position=(0, 0), scale=None, rotation=None, opacity=None, anchor=(0, 0)):
    return {
        "ty": "tr", "p": position if isinstance(position, dict) else const(list(position)),
        "a": const(list(anchor)), "s": scale if scale is not None else const([100, 100]),
        "r": rotation if rotation is not None else const(0),
        "o": opacity if opacity is not None else const(100),
    }


def rect(size, radius=0, position=(0, 0)):
    return {"ty": "rc", "d": 1, "s": const(list(size)), "p": const(list(position)), "r": const(radius)}


def ellipse(diameter, position=(0, 0)):
    return {"ty": "el", "d": 1, "s": const([diameter, diameter]), "p": const(list(position))}


def group(items, name="group"):
    return {"ty": "gr", "nm": name, "it": items}


def box_path(x0, y0, x1, y1):
    return {"c": True, "v": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "i": [[0, 0]] * 4, "o": [[0, 0]] * 4}


def wipe(delay, length, size, direction="right", ease=EASE):
    w, h = size[0] / 2 + 2, size[1] / 2 + 2
    full = box_path(-w, -h, w, h)
    start = {
        "right": box_path(-w, -h, -w, h), "left": box_path(w, -h, w, h),
        "up": box_path(-w, h, w, h), "down": box_path(-w, -h, w, -h),
    }[direction]
    path = {"a": 1, "k": [
        {"t": delay, "s": [start], "i": {"x": [ease[0][0]], "y": [ease[0][1]]}, "o": {"x": [ease[1][0]], "y": [ease[1][1]]}},
        {"t": delay + length, "s": [full]},
    ]}
    return {"inv": False, "mode": "a", "pt": path, "o": const(100), "x": const(0), "nm": "wipe"}


def layer(name, shapes, position=(CX, CY), scale=None, rotation=None, opacity=None, anchor=(0, 0), mask=None):
    item = {
        "ddd": 0, "ind": 1, "ty": 4, "nm": name, "sr": 1, "ao": 0, "ip": 0, "op": END, "st": 0, "bm": 0,
        "ks": {
            "o": opacity if opacity is not None else const(100),
            "r": rotation if rotation is not None else const(0),
            "p": position if isinstance(position, dict) else const([position[0], position[1], 0]),
            "a": const([anchor[0], anchor[1], 0]),
            "s": scale if scale is not None else const([100, 100, 100]),
        },
        "shapes": shapes,
    }
    if mask is not None:
        item["hasMask"] = True
        item["masksProperties"] = [mask]
    return item


def animation(name, layers):
    layers = list(reversed(layers))
    for index, item in enumerate(layers):
        item["ind"] = index + 1
    return {"v": "5.9.0", "fr": FPS, "ip": 0, "op": END, "w": W, "h": H, "nm": name, "ddd": 0, "assets": [], "layers": layers}


# --- Motion language --------------------------------------------------------------------------


def appear(delay, length=28, overshoot=104, start=60):
    peak = delay + round(length * 0.65)
    return anim([(delay, [start, start, 100]), (peak, [overshoot, overshoot, 100]), (delay + length, [100, 100, 100])])


def fade(delay, length=14):
    return anim([(delay, 0), (delay + length, 100)])


def wave(start, values, step, end=END):
    frames = [(start + index * step, value) for index, value in enumerate(values)]
    if frames[-1][0] < end:
        frames.append((end, values[0]))
    return frames


def breathe(start=0, amount=3, step=37, until=END):
    frames = wave(start, [100, 100 + amount], step, until)
    return anim([(time, [value, value, 100]) for time, value in frames])


def float_y(x, y, amount, start=0, step=37, until=END):
    return move([(time, (x, y + offset)) for time, offset in wave(start, [0, -amount], step, until)])


def settle(delay, angles, step=14):
    return anim([(delay + index * step, angle) for index, angle in enumerate(angles + [0])])


def icon(name, color, height, position, delay=None, weight="Semibold", alpha=100, flip=False, **keys):
    if delay is not None:
        keys.setdefault("scale", appear(delay))
        keys.setdefault("opacity", fade(delay))
    return layer(color, [symbol(name, color, height, weight, alpha, flip=flip)], position=position, **keys)


def bar(color, center, ratio, delay, width=120, height=12, length=40, track="ink"):
    x, y = center
    track_layer = layer(track, [group([rect((width, height), height / 2), fill(track, 12), transform()])], position=(x, y))
    grow = anim([(delay, [0, 100]), (delay + length, [ratio * 100, 100])])
    fill_layer = layer(color, [group([rect((width, height), height / 2, (width / 2, 0)), fill(color), transform(scale=grow)])], position=(x - width / 2, y))
    return [track_layer, fill_layer]


def dot(color, diameter, opacity=100):
    return group([ellipse(diameter), fill(color, opacity), transform()])


# --- Animations ------------------------------------------------------------------------------


def launch():
    coin = icon("dollarsign.circle.fill", "mustard", 44, move([(0, (176, 118)), (75, (190, 34)), (END, (176, 118))]),
                rotation=anim([(0, -14), (75, 10), (END, -14)]))
    card = icon("creditcard.fill", "tint", 84, float_y(150, 92, 5, step=75), scale=breathe(0, 3, step=75))
    spark_right = icon("sparkles", "ink", 36, (250, 60), alpha=45, scale=breathe(0, -20, step=75),
                       opacity=anim([(0, 0), (30, 100), (90, 100), (120, 0), (END, 0)]))
    spark_left = icon("sparkles", "ink", 26, (70, 126), alpha=45, scale=breathe(0, -20, step=75),
                      opacity=anim([(0, 100), (40, 100), (70, 0), (110, 0), (END, 100)]))
    return [spark_left, coin, card, spark_right]


def month():
    calendar = icon("calendar", "tint", 92, (124, 90), delay=0)
    chart = layer("olive", [symbol("chart.bar.fill", "olive", 60)], position=(238, 98),
                  opacity=fade(30, 10), mask=wipe(30, 40, (96, 66), "up"), scale=breathe(70, 2, 40))
    return [calendar, chart]


def history():
    sheet = icon("list.bullet.rectangle.portrait.fill", "tint", 92, (148, 90), delay=0)
    clock = icon("clock.fill", "mustard", 48, (204, 122), delay=26, rotation=settle(56, [-8, 6, -3]))
    clock["ks"]["s"] = appear(26, overshoot=110)
    dots = [icon("circle.fill", "ink", 8, (82, 60 + index * 26), delay=40 + index * 8, alpha=35) for index in range(3)]
    return [sheet, clock] + dots


def budget_pace():
    chart = layer("tint", [symbol("chart.line.uptrend.xyaxis", "tint", 84)], position=(90, 90),
                  opacity=fade(0, 10), mask=wipe(0, 50, (100, 90), "right"))
    layers = [chart]
    for row, (name, ratio, delay) in enumerate([("olive", 0.45, 20), ("mustard", 0.86, 34), ("rust", 1.0, 48)]):
        layers += bar(name, (214, 56 + row * 34), ratio, delay)
    flag = icon("flag.checkered", "ink", 34, (296, 90), delay=84, alpha=55)
    flag["ks"]["r"] = settle(84, [-10, 4])
    return layers + [flag]


def journey():
    trophy = icon("trophy.fill", "mustard", 90, (160, 98), delay=0, scale=appear(0, 32, overshoot=106, start=50))
    stars = []
    for index, (x, y, size) in enumerate([(104, 46, 22), (160, 26, 30), (216, 46, 22)]):
        delay = 32 + index * 8
        stars.append(icon("star.fill", "tint", size, (x, y), delay=delay, scale=appear(delay, 24, overshoot=118, start=40)))
    flame = icon("flame.fill", "rust", 44, (220, 130), delay=58)
    flame["ks"]["s"] = anim([(58, [40, 40, 100]), (74, [112, 112, 100]), (82, [100, 100, 100]), (104, [106, 106, 100]), (126, [100, 100, 100]), (END, [100, 100, 100])])
    return [trophy] + stars + [flame]


def budget():
    target = icon("target", "tint", 90, (108, 90), delay=0)
    target["ks"]["s"] = anim([(0, [150, 150, 100]), (22, [96, 96, 100]), (34, [100, 100, 100])])
    note = icon("banknote.fill", "olive", 46, (232, 66), delay=26)
    layers = [target, note] + bar("olive", (232, 112), 0.45, 44, width=130)
    return layers


def score():
    heart = icon("heart.text.square.fill", "tint", 90, (110, 90), delay=0)
    seal = icon("checkmark.seal.fill", "olive", 48, (156, 128), delay=30, rotation=settle(30, [-15, 4]))
    seal["ks"]["s"] = appear(30, overshoot=112)
    return [heart] + bar("olive", (236, 90), 0.82, 22, width=120, height=14) + [seal]


def participants():
    people = icon("person.2.fill", "tint", 80, (160, 74), delay=0)
    arrows = icon("arrow.left.arrow.right", "ink", 38, move([(24, (160, 138)), (50, (160, 138)), (70, (166, 138)), (95, (154, 138)), (115, (160, 138))]),
                  delay=24, alpha=45)
    coin_right = icon("dollarsign.circle.fill", "mustard", 26, move([(50, (108, 138)), (90, (212, 138))]),
                      opacity=anim([(50, 0), (58, 100), (84, 100), (94, 0)]), scale=appear(50, 20, overshoot=110))
    coin_left = icon("dollarsign.circle.fill", "mustard", 26, move([(72, (212, 138)), (112, (108, 138))]),
                     opacity=anim([(72, 0), (80, 100), (106, 100), (116, 0)]), scale=appear(72, 20, overshoot=110))
    return [arrows, people, coin_right, coin_left]


def split_modes():
    divide = icon("divide.circle.fill", "tint", 72, (160, 66), delay=0)
    divide["ks"]["s"] = anim([(0, [60, 60, 100]), (18, [104, 104, 100]), (28, [100, 100, 100]), (48, [100, 100, 100]), (62, [60, 60, 100])])
    divide["ks"]["o"] = anim([(0, 0), (12, 100), (48, 100), (60, 0)])
    percent = icon("percent", "tint", 62, (160, 66), delay=50)
    percent["ks"]["s"] = anim([(50, [60, 60, 100]), (68, [104, 104, 100]), (78, [100, 100, 100]), (96, [100, 100, 100]), (110, [60, 60, 100])])
    percent["ks"]["o"] = anim([(50, 0), (62, 100), (96, 100), (108, 0)])
    equal = icon("equal", "tint", 46, (160, 66), delay=98)
    width, height = 220, 18
    whole = layer("tint", [group([rect((width, height), height / 2), fill("tint"), transform(opacity=anim([(50, 100), (64, 0)]))])],
                  position=(160, 140), scale=anim([(0, [0, 100, 100]), (34, [100, 100, 100])]))
    layers = [whole]
    part = (width - 16) / 3
    for index, name in enumerate(["tint", "teal", "plum"]):
        target = 160 + (index - 1) * (part + 8)
        layers.append(layer(name, [group([rect((part, height), height / 2), fill(name), transform(opacity=anim([(50, 0), (62, 100)]))])],
                            position=move([(50, (160, 140)), (86, (target, 140))])))
    return [divide, percent, equal] + layers


def paid():
    card = icon("creditcard.fill", "tint", 78, (150, 86), delay=0, rotation=settle(0, [-6, 2]))
    check = icon("checkmark.circle.fill", "olive", 50, (206, 122), delay=32)
    check["ks"]["s"] = appear(32, overshoot=114, start=40)
    spark = icon("sparkles", "mustard", 36, (96, 42), delay=52)
    spark["ks"]["s"] = appear(52, 24, overshoot=118, start=40)
    return [card, check, spark]


def table():
    cells = layer("tint", [symbol("tablecells.fill", "tint", 84)], position=(138, 88),
                  opacity=fade(0, 10), mask=wipe(0, 46, (110, 90), "right"))
    doc = icon("arrow.down.doc.fill", "olive", 50, move([(40, (224, 96)), (62, (224, 118)), (76, (224, 112))]), delay=40)
    return [cells, doc]


def file_import():
    doc = icon("doc.fill", "ink", 96, (160, 92), delay=0, alpha=35)
    arrow = icon("arrow.down.circle.fill", "tint", 56, move([(20, (160, 20)), (54, (160, 104)), (68, (160, 98))], SNAP),
                 delay=20, scale=breathe(80, 3, 35))
    arrow["ks"]["o"] = fade(20, 8)
    return [doc, arrow]


def goals():
    flag = icon("flag.checkered", "tint", 84, (92, 92), delay=0, rotation=settle(0, [-10, 4]))
    flag["ks"]["s"] = appear(0, 32, overshoot=108, start=50)
    layers = [flag]
    for row, (name, ratio, delay) in enumerate([("olive", 0.45, 18), ("denim", 0.62, 32), ("mustard", 0.86, 46)]):
        layers += bar(name, (214, 56 + row * 34), ratio, delay)
    check = icon("checkmark.circle.fill", "olive", 30, (296, 56), delay=70, scale=appear(70, 24, overshoot=118, start=40))
    spark = icon("sparkles", "mustard", 24, (292, 128), delay=84, scale=breathe(108, 6, 30))
    spark["ks"]["o"] = fade(84, 10)
    return layers + [check, spark]


def done():
    check = icon("checkmark.circle.fill", "olive", 96, (160, 90), delay=0)
    check["ks"]["s"] = appear(0, 34, overshoot=110, start=40)
    layers = []
    for index, (name, dx, dy) in enumerate([("tint", -94, -46), ("mustard", 98, -40), ("mustard", -90, 50), ("tint", 96, 54)]):
        delay = 24 + index * 4
        path = move([(delay, (160 + dx * 0.4, 90 + dy * 0.4)), (delay + 36, (160 + dx, 90 + dy))])
        layers.append(layer(name, [dot(name, 12)], position=path, scale=appear(delay, 16, overshoot=120, start=0),
                            opacity=anim([(delay, 100), (delay + 40, 100), (delay + 60, 0)])))
    sparks = [icon("sparkles", "mustard", 44, (90, 54), delay=30), icon("sparkles", "mustard", 44, (232, 60), delay=42, flip=True)]
    for index, spark in enumerate(sparks):
        spark["ks"]["s"] = appear(30 + index * 12, 26, overshoot=120, start=40)
    return [check] + layers + sparks


def connect():
    terminal = icon("terminal.fill", "tint", 60, move([(0, (74, 90)), (40, (84, 90))]), delay=0)
    card = icon("creditcard.fill", "denim", 54, move([(10, (246, 90)), (50, (236, 90))]), delay=10)
    link = icon("link", "olive", 44, (160, 90), delay=34, rotation=anim([(34, 15), (66, 45)]))
    link["ks"]["s"] = appear(34, overshoot=112)
    dots = []
    for index, x in enumerate([116, 132, 188, 204]):
        dots.append(icon("circle.fill", "ink", 7, (x, 90), delay=64 + index * 6, alpha=35))
    return [terminal, card] + dots + [link]


def pro():
    crown = icon("crown.fill", "mustard", 78, (160, 94), delay=0)
    crown["ks"]["s"] = anim([(0, [50, 50, 100]), (22, [108, 108, 100]), (34, [100, 100, 100]), (80, [103, 103, 100]), (120, [100, 100, 100]), (END, [100, 100, 100])])
    orbit = layer("tint", [symbol("star.fill", "tint", 18, position=(0, -64))], position=(160, 94),
                  rotation=anim([(30, 0), (120, 360)]), opacity=anim([(30, 0), (40, 100), (110, 100), (120, 0)]))
    sparks = [icon("sparkles", "tint", 38, (88, 50), delay=20), icon("sparkles", "tint", 38, (232, 46), delay=32, flip=True)]
    for index, spark in enumerate(sparks):
        spark["ks"]["s"] = appear(20 + index * 12, 26, overshoot=118, start=40)
    return [orbit, crown] + sparks


def paywall():
    center = (160, 78)
    crown = icon("crown.fill", "mustard", 72, move([(0, (160, 118)), (26, (160, 70)), (40, center)]), delay=0)
    crown["ks"]["s"] = anim([(0, [60, 60, 100]), (24, [106, 106, 100]), (36, [100, 100, 100]), (92, [103, 103, 100]), (132, [100, 100, 100]), (END, [100, 100, 100])])
    sparks = [symbol("sparkles", "tint", size, position=(x, y), flip=flip)
              for size, x, y, flip in [(22, 0, -52, False), (18, 45, 26, True), (16, -45, 26, False)]]
    orbit = layer("tint", sparks, position=center, rotation=anim([(22, 0), (138, 360)]), opacity=fade(22, 12))
    card = icon("creditcard.fill", "denim", 42, (52, 92), delay=44, rotation=settle(44, [-8, 3]))
    card["ks"]["s"] = appear(44, overshoot=110, start=40)
    chart = icon("chart.bar.fill", "olive", 42, (268, 92), delay=56)
    chart["ks"]["s"] = appear(56, overshoot=110, start=40)
    cloud = icon("icloud.fill", "teal", 30, (160, 158), delay=68)
    cloud["ks"]["s"] = appear(68, overshoot=110, start=40)
    return [card, chart, cloud, orbit, crown]


def shop_icons():
    layers = []
    for index, name in enumerate(["tint", "mustard", "teal", "plum"]):
        layers.append(icon("app.fill", name, 50, (70 + index * 60, 100), delay=10 + index * 12))
        layers[-1]["ks"]["s"] = appear(10 + index * 12, overshoot=110, start=40)
    brush = icon("paintbrush.fill", "ink", 46, move([(0, (50, 42)), (60, (262, 42))]), delay=0, alpha=55,
                 rotation=anim([(0, -10), (30, 6), (60, 0)]))
    badge = icon("checkmark.circle.fill", "olive", 24, (92, 122), delay=84)
    badge["ks"]["s"] = appear(84, 22, overshoot=120, start=30)
    return layers + [brush, badge]


def shop_colors():
    palette = icon("paintpalette.fill", "tint", 80, (112, 90), delay=0)
    layers = [palette]
    targets = [("mustard", 214, 58), ("teal", 254, 58), ("plum", 294, 58), ("orange", 234, 122), ("denim", 274, 122)]
    for index, (name, x, y) in enumerate(targets):
        delay = 24 + index * 8
        swatch = layer(name, [dot(name, 28)], position=move([(delay, (128, 96)), (delay + 36, (x, y))]),
                       scale=appear(delay, 36, overshoot=108, start=20), opacity=fade(delay, 10))
        layers.append(swatch)
    layers[1]["ks"]["s"] = anim([(24, [20, 20, 100]), (47, [108, 108, 100]), (60, [100, 100, 100]), (100, [100, 100, 100]), (112, [118, 118, 100]), (126, [100, 100, 100])])
    return layers


def shop_helps():
    preserver = icon("lifepreserver.fill", "tint", 86, (150, 90), delay=0, rotation=anim([(30, 0), (120, 90)]))
    flake = icon("snowflake", "denim", 40, (230, 52), delay=36, rotation=anim([(36, -20), (110, 20)]))
    bolt = icon("bolt.fill", "mustard", 44, (236, 128), delay=50)
    bolt["ks"]["s"] = appear(50, 24, overshoot=120, start=40)
    bolt["ks"]["o"] = anim([(50, 0), (60, 100), (84, 100), (90, 60), (96, 100)])
    return [preserver, flake, bolt]


def capture():
    plus = icon("plus.circle.fill", "tint", 84, (160, 88), delay=0)
    plus["ks"]["s"] = appear(0, 30, overshoot=108, start=50)
    wallet = icon("wallet.pass.fill", "ink", 46, (76, 98), delay=18, alpha=40)
    bell = icon("bell.badge.fill", "ink", 46, (244, 96), delay=28, alpha=40, rotation=settle(100, [-14, 12, -6]), anchor=(0, -20))
    bell["ks"]["p"] = const([244, 76, 0])
    coin = icon("dollarsign.circle.fill", "mustard", 30, move([(50, (160, 88)), (90, (76, 92))]),
                scale=appear(50, 20, overshoot=112, start=30), opacity=anim([(50, 0), (58, 100), (90, 100), (102, 0)]))
    return [wallet, bell, plus, coin]


ANIMATIONS = {
    "launch": launch,
    "month": month, "history": history, "budgetPace": budget_pace, "journey": journey, "budget": budget,
    "score": score, "participants": participants, "splitModes": split_modes, "paid": paid, "table": table,
    "file": file_import, "done": done, "connect": connect,
    "goals": goals,
    "pro": pro, "paywall": paywall, "shopIcons": shop_icons, "shopColors": shop_colors, "shopHelps": shop_helps,
    "capture": capture,
}


# --- Output ----------------------------------------------------------------------------------


def build_all():
    documents = {name: animation(name, build()) for name, build in ANIMATIONS.items()}
    while MISSING:
        by_weight = {}
        for weight, name in MISSING:
            by_weight.setdefault(weight, set()).add(name)
        MISSING.clear()
        for weight, names in by_weight.items():
            load_glyphs(weight, names)
        documents = {name: animation(name, build()) for name, build in ANIMATIONS.items()}
    return documents


def write_swift(texts):
    lines = ["import Foundation", "", "public enum CashlyResourceAnimation {",
             "    public static func json(named name: String) -> String? {", "        switch name {"]
    for name, text in texts.items():
        lines += [f'        case "{name}":', f'            #"{text}"#']
    lines += ["        default: nil", "        }", "    }", "}", ""]
    with open(SWIFT, "w") as handle:
        handle.write("\n".join(lines))


def write_preview(texts):
    cards = "\n".join(f'<figure><div class="stage" data-name="{name}"></div><figcaption>{name}</figcaption></figure>' for name in texts)
    data = json.dumps(texts, separators=(",", ":")).replace("</", "<\\/")
    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cashly animations</title>
<style>
  :root {{ --bg: #F5F1EA; --fg: #1C1C1E; --card: #FFFFFF; }}
  body.dark {{ --bg: #1C1C1E; --fg: #F5F1EA; --card: #2C2C2E; }}
  body {{ margin: 0; padding: 24px; background: var(--bg); color: var(--fg); font: 14px -apple-system, system-ui, sans-serif; }}
  header {{ display: flex; gap: 16px; align-items: center; margin-bottom: 20px; }}
  button {{ font: inherit; padding: 6px 12px; border-radius: 8px; border: 1px solid currentColor; background: transparent; color: inherit; }}
  main {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 20px; }}
  figure {{ margin: 0; }}
  .stage {{ aspect-ratio: 16 / 9; background: var(--card); border-radius: 16px; overflow: hidden; }}
  figcaption {{ margin-top: 8px; font-family: ui-monospace, monospace; }}
</style>
</head>
<body>
<header><strong>Cashly animations</strong><button id="theme">Dark</button><button id="restart">Restart</button></header>
<main>
{cards}
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>
<script>
const animations = {data};
const ink = {{ light: [0.11, 0.11, 0.12, 1], dark: [0.96, 0.95, 0.92, 1] }};
let players = [];
function recolor(items, color) {{
  items.forEach((item) => {{
    if (item.ty === "fl" || item.ty === "st") item.c.k = color;
    if (item.it) recolor(item.it, color);
  }});
}}
function load() {{
  players.forEach((player) => player.destroy());
  players = [];
  const theme = document.body.classList.contains("dark") ? "dark" : "light";
  document.querySelectorAll(".stage").forEach((stage) => {{
    const data = JSON.parse(animations[stage.dataset.name]);
    data.layers.filter((item) => item.nm === "ink").forEach((item) => recolor(item.shapes, ink[theme]));
    players.push(lottie.loadAnimation({{ container: stage, renderer: "svg", loop: true, autoplay: true, animationData: data }}));
  }});
}}
load();
document.getElementById("theme").addEventListener("click", () => {{ document.body.classList.toggle("dark"); load(); }});
document.getElementById("restart").addEventListener("click", () => players.forEach((player) => player.goToAndPlay(0, true)));
</script>
</body>
</html>
"""
    with open(PREVIEW, "w") as handle:
        handle.write(page)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    texts = {}
    for name, document in build_all().items():
        text = json.dumps(document, separators=(",", ":"))
        with open(os.path.join(OUT, name + ".json"), "w") as handle:
            handle.write(text + "\n")
        texts[name] = text
    write_swift(texts)
    write_preview(texts)
    print(f"{len(ANIMATIONS)} animations written to {os.path.abspath(OUT)}, {os.path.abspath(SWIFT)} and {os.path.abspath(PREVIEW)}")
