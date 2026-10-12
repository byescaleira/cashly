#!/usr/bin/env python3
import json
import os
import sys

W, H, FPS, END = 320, 180, 60, 150
OUT = os.path.join(os.path.dirname(__file__), "animations")
SWIFT = os.path.join(os.path.dirname(__file__), "..", "CashlyKit/Sources/CashlyResource/CashlyResourceAnimation.swift")
SMOOTH = ((0.25, 1.0), (0.3, 0.0))
SNAP = ((0.1, 1.0), (0.5, 0.0))

PALETTE = {
    "olive": (0x5F, 0x7A, 0x2E), "mustard": (0xB8, 0x84, 0x1C), "rust": (0xA6, 0x3D, 0x2C),
    "orange": (0xC2, 0x60, 0x2A), "teal": (0x2A, 0x70, 0x69), "denim": (0x3D, 0x5F, 0x86),
    "plum": (0x74, 0x41, 0x5F), "brown": (0x7E, 0x55, 0x36), "tint": (0xC2, 0x60, 0x2A),
    "ink": (0x1C, 0x1C, 0x1E), "paper": (0xFF, 0xFF, 0xFF), "cream": (0xF0, 0xE6, 0xD2),
}


def rgb(name):
    r, g, b = PALETTE[name]
    return [r / 255, g / 255, b / 255, 1]


def const(value):
    return {"a": 0, "k": value}


def anim(frames, ease=SMOOTH):
    keys = []
    for index, (time, value) in enumerate(frames):
        dims = len(value) if isinstance(value, list) else 1
        key = {"t": time, "s": value if isinstance(value, list) else [value]}
        if index < len(frames) - 1:
            key["i"] = {"x": [ease[0][0]] * dims, "y": [ease[0][1]] * dims}
            key["o"] = {"x": [ease[1][0]] * dims, "y": [ease[1][1]] * dims}
        keys.append(key)
    return {"a": 1, "k": keys}


def fill(color, opacity=100):
    return {"ty": "fl", "c": const(rgb(color)), "o": const(opacity), "r": 1}


def stroke(color, width, opacity=100):
    return {"ty": "st", "c": const(rgb(color)), "o": const(opacity), "w": const(width), "lc": 2, "lj": 2}


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


def star(outer, inner, points=5):
    return {"ty": "sr", "sy": 1, "d": 1, "pt": const(points), "p": const([0, 0]), "r": const(0),
            "or": const(outer), "os": const(0), "ir": const(inner), "is": const(0)}


def path(vertices, closed=False):
    zero = [[0, 0]] * len(vertices)
    return {"ty": "sh", "d": 1, "ks": const({"c": closed, "v": vertices, "i": zero, "o": zero})}


def arc(radius):
    k = 0.5523 * radius
    return {"ty": "sh", "d": 1, "ks": const({
        "c": False, "v": [[-radius, 0], [0, -radius], [radius, 0]],
        "i": [[0, 0], [-k, 0], [0, -k]], "o": [[0, -k], [k, 0], [0, 0]]})}


def trim(end, start=None):
    return {"ty": "tm", "s": start if start is not None else const(0), "e": end, "o": const(0), "m": 1}


def group(items, name="group"):
    return {"ty": "gr", "nm": name, "it": items}


def layer(name, shapes, position=(W / 2, H / 2), index=1, scale=None, rotation=None, opacity=None, anchor=(0, 0)):
    return {
        "ddd": 0, "ind": index, "ty": 4, "nm": name, "sr": 1, "ao": 0, "ip": 0, "op": END, "st": 0, "bm": 0,
        "ks": {
            "o": opacity if opacity is not None else const(100),
            "r": rotation if rotation is not None else const(0),
            "p": position if isinstance(position, dict) else const([position[0], position[1], 0]),
            "a": const([anchor[0], anchor[1], 0]),
            "s": scale if scale is not None else const([100, 100, 100]),
        },
        "shapes": shapes,
    }


def animation(name, layers):
    layers = list(reversed(layers))
    for index, item in enumerate(layers):
        item["ind"] = index + 1
    return {"v": "5.9.0", "fr": FPS, "ip": 0, "op": END, "w": W, "h": H, "nm": name, "ddd": 0, "assets": [], "layers": layers}


def pop(delay, overshoot=108):
    return anim([(delay, [0, 0, 100]), (delay + 18, [overshoot, overshoot, 100]), (delay + 30, [100, 100, 100])], SNAP)


def fade(delay, length=20):
    return anim([(delay, 0), (delay + length, 100)])


def grow_x(delay, to, length=40):
    return anim([(delay, [0, 100]), (delay + length, [to, 100])])


def bar(name, y, ratio, delay, width=220, height=14, track="ink"):
    left = -width / 2
    track_layer = layer(track, [group([rect((width, height), height / 2), fill(track, 12), transform()])], position=(W / 2, y))
    fill_layer = layer(name, [group([rect((width, height), height / 2, (width / 2, 0)), fill(name), transform(scale=grow_x(delay, ratio * 100))])], position=(W / 2 + left, y))
    return [track_layer, fill_layer]


def check(color, delay, size=1.0, width=8):
    points = [[-18 * size, 2 * size], [-6 * size, 14 * size], [20 * size, -14 * size]]
    return group([path(points), trim(anim([(delay, 0), (delay + 24, 100)])), stroke(color, width), transform()])


def month():
    ring = layer("ink", [group([ellipse(110), stroke("ink", 12, 12), transform()])], position=(110, 90))
    arc_layer = layer("tint", [group([ellipse(110), trim(anim([(0, 0), (60, 72)])), stroke("tint", 12), transform(rotation=const(-90))])], position=(110, 90))
    dot = layer("tint", [group([ellipse(22), fill("tint"), transform(scale=pop(55))])], position=(110, 90))
    bars = []
    for offset, (name, ratio, delay) in enumerate([("olive", 1.0, 10), ("mustard", 0.65, 25), ("denim", 0.8, 40)]):
        x = 205 + offset * 36
        bars.append(layer(name, [group([rect((22, 90), 8, (0, -45)), fill(name), transform(scale=anim([(delay, [100, 0]), (delay + 40, [100, ratio * 100])]))])], position=(x, 140)))
    return [ring, arc_layer, dot] + bars


def history():
    layers = []
    for row, (color, delay) in enumerate([("orange", 0), ("teal", 18), ("olive", 36)]):
        y = 45 + row * 46
        slide = anim([(delay, [W / 2 + 60, y, 0]), (delay + 30, [W / 2, y, 0])])
        shapes = [
            group([ellipse(30, (-110, 0)), fill(color), transform()]),
            group([rect((110, 10), 5, (-30, -7)), fill("ink", 55), transform()]),
            group([rect((70, 8), 4, (-50, 9)), fill("ink", 20), transform()]),
            group([rect((56, 10), 5, (92, 0)), fill(color if row != 2 else "olive", 100 if row == 2 else 55), transform()]),
        ]
        layers.append(layer(color, shapes, position=slide, opacity=fade(delay, 18)))
    return layers


def budget_pace():
    layers = []
    for row, (name, ratio, delay) in enumerate([("olive", 0.45, 0), ("mustard", 0.86, 15), ("rust", 1.0, 30)]):
        layers += bar(name, 40 + row * 50, ratio, delay)
    layers.append(layer("rust", [group([ellipse(18), fill("rust"), transform(scale=pop(70))])], position=(W / 2 + 110, 140)))
    return layers


def journey():
    star_layer = layer("mustard", [group([star(44, 20), fill("mustard"), transform(scale=pop(10, 115))])], position=(100, 84))
    glow = layer("mustard", [group([ellipse(120), fill("mustard", 15), transform(scale=pop(0))])], position=(100, 84))
    layers = [glow, star_layer]
    for step in range(7):
        x = 180 + step * 20
        delay = 30 + step * 10
        layers.append(layer("ink", [group([rect((14, 14), 7), fill("ink", 12), transform()])], position=(x, 84)))
        if step < 5:
            layers.append(layer("olive", [group([rect((14, 14), 7), fill("olive"), transform(scale=pop(delay))])], position=(x, 84)))
    return layers


def budget():
    badge = layer("orange", [group([ellipse(56), fill("orange"), transform(scale=pop(0))])], position=(52, 90))
    inner = layer("paper", [group([rect((22, 22), 5), fill("paper"), transform(scale=pop(6))])], position=(52, 90))
    layers = [badge, inner] + bar("olive", 78, 0.45, 20, width=180)
    layers[2]["ks"]["p"] = const([200, 78, 0])
    layers[3]["ks"]["p"] = const([110, 78, 0])
    layers.append(layer("ink", [group([rect((3, 30), 1.5), fill("ink", 45), transform(opacity=fade(55))])], position=(290, 78)))
    layers.append(layer("ink", [group([rect((110, 8), 4), fill("ink", 20), transform(opacity=fade(60))])], position=(165, 106)))
    return layers


def score():
    track = layer("ink", [group([arc(84), stroke("ink", 14, 12), transform()])], position=(W / 2, 128))
    arc_fill = layer("olive", [group([arc(84), trim(anim([(0, 0), (60, 82)])), stroke("olive", 14), transform()])], position=(W / 2, 128))
    needle = layer("ink", [group([rect((6, 70), 3, (0, -35)), fill("ink", 70), transform()])], position=(W / 2, 128), rotation=anim([(0, -90), (60, 58)], SNAP))
    pivot = layer("ink", [group([ellipse(18), fill("ink", 70), transform()])], position=(W / 2, 128))
    return [track, arc_fill, needle, pivot]


def participants():
    layers = []
    for index, (name, delay) in enumerate([("tint", 0), ("teal", 15), ("plum", 30)]):
        x = W / 2 + (index - 1) * 64
        layers.append(layer(name, [group([ellipse(68), fill(name), transform(scale=pop(delay))])], position=(x, 90)))
        layers.append(layer("paper", [
            group([ellipse(22, (0, -10)), fill("paper", 90), transform()]),
            group([rect((36, 22), 11, (0, 16)), fill("paper", 90), transform()]),
        ], position=(x, 90), scale=pop(delay + 6)))
    return layers


def split_modes():
    width = 240
    whole = layer("tint", [group([rect((width, 26), 13), fill("tint"), transform(opacity=anim([(20, 100), (40, 0)]))])], position=(W / 2, 90))
    layers = [whole]
    part = (width - 16) / 3
    for index, name in enumerate(["tint", "teal", "plum"]):
        target = W / 2 + (index - 1) * (part + 8)
        move = anim([(20, [W / 2, 90, 0]), (55, [target, 90, 0])], SNAP)
        layers.append(layer(name, [group([rect((part, 26), 13), fill(name), transform(opacity=anim([(20, 0), (35, 100)]))])], position=move))
    return layers


def paid():
    circle = layer("olive", [group([ellipse(96), fill("olive"), transform(scale=pop(0, 112))])], position=(W / 2, 90))
    mark = layer("paper", [check("paper", 22, 1.4, 10)], position=(W / 2, 90))
    return [circle, mark]


def table():
    layers = []
    for row in range(3):
        for column, width in enumerate([80, 110, 60]):
            x = 60 + sum([80, 110, 60][:column]) + column * 12 + width / 2
            y = 48 + row * 42
            delay = row * 14 + column * 6
            name = "tint" if row == 0 else "ink"
            layers.append(layer(name, [group([rect((width, 22), 6), fill(name, 100 if row == 0 else 14), transform(scale=pop(delay, 104))])], position=(x, y)))
    return layers


def file_import():
    sheet = layer("ink", [
        group([rect((100, 124), 14), fill("ink", 10), transform()]),
        group([rect((56, 8), 4, (0, -30)), fill("ink", 30), transform()]),
        group([rect((56, 8), 4, (0, -10)), fill("ink", 30), transform()]),
        group([rect((36, 8), 4, (-10, 10)), fill("ink", 30), transform()]),
    ], position=(130, 90), scale=pop(0, 104))
    arrow_shaft = group([rect((10, 46), 5, (0, -10)), fill("tint"), transform()])
    arrow_head = group([path([[-22, 4], [0, 26], [22, 4]], True), fill("tint"), transform()])
    arrow = layer("tint", [arrow_shaft, arrow_head], position=anim([(20, [222, 60, 0]), (50, [222, 96, 0])], SNAP), opacity=fade(20, 12))
    return [sheet, arrow]


def done():
    circle = layer("olive", [group([ellipse(110), fill("olive"), transform(scale=pop(0, 114))])], position=(W / 2, 90))
    mark = layer("paper", [check("paper", 24, 1.7, 11)], position=(W / 2, 90))
    layers = [circle, mark]
    for index, (name, dx, dy) in enumerate([("mustard", -92, -40), ("orange", 96, -34), ("teal", -84, 44), ("plum", 90, 48)]):
        delay = 30 + index * 4
        move = anim([(delay, [W / 2 + dx * 0.4, 90 + dy * 0.4, 0]), (delay + 30, [W / 2 + dx, 90 + dy, 0])])
        layers.append(layer(name, [group([ellipse(14), fill(name), transform(scale=pop(delay, 120))])], position=move))
    return layers


def connect():
    left = layer("tint", [group([rect((64, 64), 18), fill("tint"), transform(scale=pop(0))])], position=anim([(0, [100, 90, 0]), (30, [96, 90, 0])]))
    right = layer("denim", [group([rect((64, 64), 18), fill("denim"), transform(scale=pop(10))])], position=anim([(0, [220, 90, 0]), (30, [224, 90, 0])]))
    line = layer("ink", [group([rect((80, 4), 2), fill("ink", 18), transform(scale=anim([(20, [0, 100]), (45, [100, 100])]))])], position=(W / 2, 90))
    dot = layer("olive", [group([ellipse(14), fill("olive"), transform()])], position=anim([(45, [W / 2 - 30, 90, 0]), (80, [W / 2 + 30, 90, 0]), (115, [W / 2 - 30, 90, 0])]), opacity=fade(45, 10))
    return [left, right, line, dot]


def launch():
    square = layer("tint", [group([rect((150, 150), 36), fill("tint"), transform(scale=pop(0, 106))])], position=(W / 2, 92))
    drop = anim([(30, [W / 2, -30, 0]), (62, [W / 2, 100, 0]), (74, [W / 2, 90, 0]), (84, [W / 2, 100, 0])], SNAP)
    coin = layer("mustard", [
        group([ellipse(54), fill("mustard"), transform()]),
        group([ellipse(36), stroke("cream", 4, 70), transform()]),
    ], position=drop, opacity=anim([(100, 100), (118, 0)]))
    pocket = layer("cream", [
        group([rect((150, 70), 24, (0, 0)), fill("cream"), transform()]),
        group([rect((150, 30), 0, (0, -20)), fill("cream"), transform()]),
    ], position=(W / 2, 132), scale=pop(10, 104))
    lip = layer("ink", [group([rect((110, 6), 3), fill("ink", 10), transform()])], position=(W / 2, 100), opacity=fade(24, 10))
    return [square, coin, pocket, lip]


def pro():
    glow = layer("mustard", [group([ellipse(130), fill("mustard", 15), transform(scale=pop(0))])], position=(W / 2, 92))
    crown = layer("mustard", [group([path([[-60, 30], [-60, -10], [-30, 10], [0, -36], [30, 10], [60, -10], [60, 30]], True), fill("mustard"), transform(scale=pop(8, 110))])], position=(W / 2, 92))
    layers = [glow, crown]
    for index, (dx, dy) in enumerate([(-30, 14), (0, 8), (30, 14)]):
        layers.append(layer("paper", [group([ellipse(11), fill("paper"), transform(scale=pop(30 + index * 6, 120))])], position=(W / 2 + dx, 92 + dy)))
    for index, (x, y) in enumerate([(78, 48), (246, 132), (236, 44)]):
        delay = 50 + index * 10
        layers.append(layer("tint", [group([star(9, 3, 4), fill("tint"), transform(scale=pop(delay, 130))])], position=(x, y), opacity=anim([(delay, 0), (delay + 10, 100), (delay + 50, 100), (delay + 70, 0)])))
    return layers


def shop_icons():
    layers = []
    for index, name in enumerate(["tint", "mustard", "teal", "plum"]):
        x = 64 + index * 64
        layers.append(layer(name, [group([rect((56, 56), 14), fill(name), transform(scale=pop(index * 10, 110))])], position=(x, 90)))
    badge = layer("olive", [group([ellipse(28), fill("olive"), transform(scale=pop(50, 120))])], position=(256 + 22, 90 + 22))
    mark = layer("paper", [check("paper", 62, 0.5, 5)], position=(256 + 22, 90 + 22))
    return layers + [badge, mark]


def shop_colors():
    layers = []
    for index, (name, opacity) in enumerate([("mustard", 100), ("ink", 28), ("brown", 100), ("orange", 100), ("plum", 100)]):
        x = 56 + index * 52
        layers.append(layer(name, [group([ellipse(40), fill(name, opacity), transform(scale=pop(index * 8, 112))])], position=(x, 90)))
    ring = layer("tint", [group([ellipse(56), stroke("tint", 5), transform()])], position=anim([(50, [56, 90, 0]), (85, [160, 90, 0])]), opacity=fade(50, 10))
    return layers + [ring]


def shop_helps():
    circle = layer("orange", [group([ellipse(100), fill("orange"), transform(scale=pop(0, 112))])], position=(W / 2 - 50, 90))
    mark = layer("paper", [check("paper", 22, 1.2, 9)], position=(W / 2 - 50, 90))
    flake = layer("denim", [group([ellipse(76), fill("denim"), transform(scale=pop(16, 112))])], position=(W / 2 + 62, 90))
    spin = layer("paper", [group([star(26, 9, 6), fill("paper"), transform(scale=pop(32, 115))])], position=(W / 2 + 62, 90), rotation=anim([(32, 0), (110, 60)]))
    return [circle, mark, flake, spin]


def capture():
    glow = layer("tint", [group([ellipse(130), fill("tint", 14), transform(scale=pop(0))])], position=(W / 2, 90))
    button = layer("tint", [group([ellipse(96), fill("tint"), transform(scale=pop(6, 112))])], position=(W / 2, 90))
    plus = layer("paper", [
        group([rect((44, 9), 4), fill("paper"), transform()]),
        group([rect((9, 44), 4), fill("paper"), transform()]),
    ], position=(W / 2, 90), scale=pop(22, 118))
    coin = layer("mustard", [
        group([ellipse(30), fill("mustard"), transform()]),
        group([ellipse(18), stroke("cream", 3, 70), transform()]),
    ], position=anim([(50, [W / 2 + 120, 30, 0]), (85, [W / 2 + 34, 58, 0])], SNAP), scale=pop(50, 110), opacity=anim([(50, 0), (58, 100), (100, 100), (115, 0)]))
    return [glow, button, plus, coin]


ANIMATIONS = {
    "launch": launch,
    "month": month, "history": history, "budgetPace": budget_pace, "journey": journey, "budget": budget,
    "score": score, "participants": participants, "splitModes": split_modes, "paid": paid, "table": table,
    "file": file_import, "done": done, "connect": connect,
    "pro": pro, "shopIcons": shop_icons, "shopColors": shop_colors, "shopHelps": shop_helps,
    "capture": capture,
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    cases = []
    for name, build in ANIMATIONS.items():
        text = json.dumps(animation(name, build()), separators=(",", ":"))
        with open(os.path.join(OUT, name + ".json"), "w") as handle:
            handle.write(text + "\n")
        cases.append(f'        case "{name}": #"{text}"#')
    lines = ["import Foundation", "", "public enum CashlyResourceAnimation {",
             "    public static func json(named name: String) -> String? {", "        switch name {"]
    lines += cases + ["        default: nil", "        }", "    }", "}", ""]
    with open(SWIFT, "w") as handle:
        handle.write("\n".join(lines))
    print(f"{len(ANIMATIONS)} animations written to {os.path.abspath(OUT)} and {os.path.abspath(SWIFT)}")
