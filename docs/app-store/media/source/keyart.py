import argparse
import base64
import math
import pathlib
import random
import tempfile

from render import chrome

SOURCE = pathlib.Path(__file__).resolve().parent
MEDIA = SOURCE.parent
ICON = SOURCE / "raw" / "keyart" / "icon.png"

PAPER = "#fbf5ea"
CREAM = "#f3e7cf"
INK = "#3a2418"
MUSTARD = "#e3b04b"
OLIVE = "#8fa84e"
RUST = "#b8432f"
TEAL = "#4f9a90"
DENIM = "#5f86b3"
PLUM = "#9a5f82"
BILL = "#9cc27a"
BILL_DARK = "#5f8a3e"
GOLD = "#f0c04a"
GOLD_DARK = "#c8901e"

GLYPHS = {
    "cart": '<path d="M3 4h2l2.4 11h11L21 7H6.2"/><circle cx="9" cy="19.5" r="1.3"/><circle cx="17" cy="19.5" r="1.3"/>',
    "fork": '<path d="M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M16 21V3c-2 1-3 4-3 8h3"/>',
    "car": '<path d="M4 16v-4l2-5h12l2 5v4zM4 16v3M20 16v3"/><circle cx="7.5" cy="13" r="0.8"/><circle cx="16.5" cy="13" r="0.8"/>',
    "home": '<path d="M4 11 12 4l8 7v9H4z"/>',
    "heart": '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
    "plane": '<path d="M3 13l18-7-7 18-2.5-7.5z"/>',
    "flame": '<path d="M12 21c-4 0-7-2.8-7-6.6 0-3.3 2.4-5.4 3.6-7.9.3 2 1.6 3.2 2.8 3.6C11 7 12 4.6 14.6 3c-.3 3 1.6 4.6 2.8 6.4A8 8 0 0 1 19 14.4C19 18.2 16 21 12 21z"/>',
}


def icon_uri():
    return "data:image/png;base64," + base64.b64encode(ICON.read_bytes()).decode()


def page(width, height, body, rays=None):
    burst = ""
    if rays:
        cx, cy, radius = rays
        stops = ",".join(
            f"rgba(251,245,234,{0.16 if i % 2 == 0 else 0}) {i * 10}deg {(i + 1) * 10}deg" for i in range(36)
        )
        burst = (
            f"<div style='position:absolute;left:{cx - radius}px;top:{cy - radius}px;width:{radius * 2}px;height:{radius * 2}px;"
            f"border-radius:50%;background:conic-gradient({stops});"
            f"-webkit-mask:radial-gradient(circle, #000 0%, #000 35%, transparent 70%);mask:radial-gradient(circle, #000 0%, #000 35%, transparent 70%)'></div>"
        )
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
html, body {{ margin: 0; width: {width}px; height: {height}px; overflow: hidden; }}
body {{ position: relative; background: radial-gradient(70% 80% at 50% 45%, #e0814a 0%, #c9642c 42%, #a8432a 100%); }}
.glow {{ position: absolute; inset: 0; background: radial-gradient(35% 45% at 50% 48%, rgba(255, 236, 200, 0.35), transparent 70%); }}
.abs {{ position: absolute; }}
.card {{ position: absolute; background: {PAPER}; box-shadow: 0 {height * 0.018:.0f}px {height * 0.05:.0f}px -{height * 0.012:.0f}px rgba(80, 25, 8, 0.45); }}
.icon img {{ width: 100%; height: 100%; display: block; filter: drop-shadow(0 {height * 0.03:.0f}px {height * 0.05:.0f}px rgba(70, 20, 5, 0.45)); }}
svg {{ overflow: visible; }}
</style></head><body>{burst}<div class="glow"></div>{body}</body></html>"""


def icon(cx, cy, size):
    return (
        f"<div class='abs icon' style='left:{cx - size / 2}px;top:{cy - size / 2}px;width:{size}px;height:{size}px'>"
        f"<img src='{icon_uri()}'></div>"
    )


def bill(size):
    w, h = size, size * 0.48
    return (
        f"<svg width='{w}' height='{h}' viewBox='0 0 100 48'>"
        f"<rect x='1' y='1' width='98' height='46' rx='7' fill='{BILL}' stroke='{BILL_DARK}' stroke-width='2.5'/>"
        f"<rect x='8' y='7' width='84' height='34' rx='4' fill='none' stroke='{BILL_DARK}' stroke-width='1.6' opacity='0.6'/>"
        f"<circle cx='50' cy='24' r='11' fill='{PAPER}' opacity='0.85'/>"
        f"<path d='M53.5 19.5c-1-1.6-2.6-2.2-4.2-2.2-2.4 0-4 1.2-4 3 0 4 8.6 2.2 8.6 6.6 0 1.9-1.8 3.3-4.5 3.3-2 0-3.7-.8-4.6-2.4M49.4 15v19' "
        f"fill='none' stroke='{BILL_DARK}' stroke-width='2.2' stroke-linecap='round'/>"
        f"<circle cx='17' cy='24' r='3.5' fill='{BILL_DARK}' opacity='0.5'/><circle cx='83' cy='24' r='3.5' fill='{BILL_DARK}' opacity='0.5'/></svg>"
    ), w, h


def coin(size):
    return (
        f"<svg width='{size}' height='{size}' viewBox='0 0 40 40'>"
        f"<circle cx='20' cy='20' r='18.5' fill='{GOLD}' stroke='{GOLD_DARK}' stroke-width='2.5'/>"
        f"<circle cx='20' cy='20' r='13' fill='none' stroke='{GOLD_DARK}' stroke-width='1.5' opacity='0.6'/>"
        f"<path d='M23.4 15.6c-.8-1.2-2-1.7-3.3-1.7-1.9 0-3.2 1-3.2 2.4 0 3.2 6.8 1.7 6.8 5.2 0 1.5-1.4 2.6-3.5 2.6-1.6 0-2.9-.6-3.6-1.9M20.1 12v16' "
        f"fill='none' stroke='{GOLD_DARK}' stroke-width='2' stroke-linecap='round'/></svg>"
    ), size, size


def dot(size, color, shape):
    if shape == "circle":
        return f"<svg width='{size}' height='{size}'><circle cx='{size / 2}' cy='{size / 2}' r='{size / 2}' fill='{color}'/></svg>", size, size
    if shape == "pill":
        return f"<svg width='{size}' height='{size * 0.4}'><rect width='{size}' height='{size * 0.4}' rx='{size * 0.2}' fill='{color}'/></svg>", size, size * 0.4
    return f"<svg width='{size}' height='{size}'><rect width='{size}' height='{size}' rx='{size * 0.2}' fill='{color}'/></svg>", size, size


def overlaps(box, boxes, margin):
    x, y, w, h = box
    for bx, by, bw, bh in boxes:
        if x < bx + bw + margin and x + w + margin > bx and y < by + bh + margin and y + h + margin > by:
            return True
    return False


def confetti(width, height, blocked, count, scale, seed, center=None, spread=None):
    rng = random.Random(seed)
    placed = list(blocked)
    out = ""
    colors = [MUSTARD, PAPER, OLIVE, TEAL, DENIM, PLUM, CREAM]
    attempts = 0
    while count > 0 and attempts < 8000:
        attempts += 1
        kind = rng.random()
        if kind < 0.28:
            svg, w, h = bill(scale * rng.uniform(1.1, 1.6))
        elif kind < 0.55:
            svg, w, h = coin(scale * rng.uniform(0.45, 0.7))
        else:
            svg, w, h = dot(scale * rng.uniform(0.14, 0.28), rng.choice(colors), rng.choice(["circle", "pill", "square"]))
        if center:
            angle = rng.uniform(0, math.tau)
            radius = rng.uniform(spread[0], spread[1])
            x = center[0] + math.cos(angle) * radius * (width / height if width > height else 1) - w / 2
            y = center[1] + math.sin(angle) * radius - h / 2
        else:
            x, y = rng.uniform(-w * 0.3, width - w * 0.7), rng.uniform(-h * 0.3, height - h * 0.7)
        if x < -w * 0.4 or y < -h * 0.4 or x > width - w * 0.6 or y > height - h * 0.6:
            continue
        if overlaps((x, y, w, h), placed, scale * 0.12):
            continue
        placed.append((x, y, w, h))
        rotation = rng.uniform(-35, 35)
        out += f"<div class='abs' style='left:{x}px;top:{y}px;transform:rotate({rotation:.1f}deg)'>{svg}</div>"
        count -= 1
    return out


def line(x, y, w, h, color, opacity=1.0):
    return f"<div class='abs' style='left:{x}px;top:{y}px;width:{w}px;height:{h}px;border-radius:999px;background:{color};opacity:{opacity}'></div>"


def badge(x, y, size, color, glyph):
    return (
        f"<div class='abs' style='left:{x}px;top:{y}px;width:{size}px;height:{size}px;border-radius:{size * 0.28}px;"
        f"background:color-mix(in srgb, {color} 22%, {PAPER});display:grid;place-items:center;color:{color}'>"
        f"<svg viewBox='0 0 24 24' style='width:{size * 0.56}px;height:{size * 0.56}px;fill:none;stroke:currentColor;"
        f"stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round'>{GLYPHS[glyph]}</svg></div>"
    )


def bar(x, y, w, h, color, fill, marker=None):
    out = line(x, y, w, h, f"color-mix(in srgb, {color} 24%, {PAPER})")
    out += line(x, y, w * fill, h, color)
    if marker is not None:
        out += line(x + w * marker - h * 0.12, y - h * 0.45, h * 0.24, h * 1.9, INK, 0.75)
    return out


def card(x, y, w, h, radius):
    return f"<div class='card' style='left:{x}px;top:{y}px;width:{w}px;height:{h}px;border-radius:{radius}px'></div>"


def month_card(x, y, w, h, u):
    pad = w * 0.1
    out = card(x, y, w, h, min(w, h) * 0.16)
    out += line(x + w * 0.35, y + h * 0.12, w * 0.3, h * 0.075, f"color-mix(in srgb, {RUST} 30%, {PAPER})")
    out += line(x + w * 0.22, y + h * 0.26, w * 0.56, h * 0.13, INK, 0.9)
    out += bar(x + pad, y + h * 0.52, w - pad * 2, h * 0.07, OLIVE, 0.6, 0.55)
    col = (w - pad * 2) / 3
    for i in range(3):
        cx = x + pad + col * i + col / 2
        out += line(cx - col * 0.28, y + h * 0.7, col * 0.56, h * 0.045, "#b9ab95")
        out += line(cx - col * 0.36, y + h * 0.79, col * 0.72, h * 0.075, OLIVE if i == 2 else INK, 0.85)
    return out


def budgets_card(x, y, w, h, u):
    pad = min(w, h) * 0.14
    out = card(x, y, w, h, min(w, h) * 0.16)
    rows = [("cart", "#5f7a2e", 0.62), ("fork", "#b8841c", 0.88), ("car", RUST, 1.0)]
    step = (h - pad * 2) / len(rows)
    size = step * 0.66
    for i, (glyph, color, fill) in enumerate(rows):
        top = y + pad + step * i
        ry = top + (step - size) / 2
        out += badge(x + pad, ry, size, color, glyph)
        bx = x + pad + size * 1.4
        bw = x + w - pad - bx
        out += line(bx, ry + size * 0.04, bw * 0.36, size * 0.18, "#8f7f6a", 0.8)
        out += bar(bx, ry + size * 0.62, bw, size * 0.24, color, fill, 0.55)
    return out


def categories_card(x, y, w, h, u):
    pad = min(w, h) * 0.14
    out = card(x, y, w, h, min(w, h) * 0.16)
    items = [("cart", "#5f7a2e"), ("fork", "#b8841c"), ("car", RUST), ("home", DENIM), ("heart", TEAL), ("plane", PLUM)]
    cols, rows = 3, 2
    cell_w = (w - pad * 2) / cols
    cell_h = (h - pad * 2) / rows
    size = min(cell_w, cell_h) * 0.7
    for i, (glyph, color) in enumerate(items):
        cx = x + pad + cell_w * (i % cols) + (cell_w - size) / 2
        cy = y + pad + cell_h * (i // cols) + (cell_h - size) / 2
        out += badge(cx, cy, size, color, glyph)
    return out


def journey_card(x, y, w, h, u):
    pad = min(w, h) * 0.14
    out = card(x, y, w, h, min(w, h) * 0.16)
    size = h * 0.36
    out += badge(x + pad, y + pad, size, "#c8601e", "flame")
    tx = x + pad + size * 1.3
    out += line(tx, y + pad + size * 0.14, w * 0.34, size * 0.3, INK, 0.85)
    out += line(tx, y + pad + size * 0.62, w * 0.22, size * 0.2, "#8f7f6a", 0.8)
    seg_h = h * 0.1
    seg_y = y + h - pad - seg_h
    gap = w * 0.025
    seg_w = (w - pad * 2 - gap * 4) / 5
    for i in range(5):
        out += line(x + pad + (seg_w + gap) * i, seg_y, seg_w, seg_h, MUSTARD if i < 4 else f"color-mix(in srgb, {MUSTARD} 28%, {PAPER})")
    return out


def header(width, height):
    u = height
    size = u * 0.52
    cx, cy = width / 2, height / 2
    gap = u * 0.06
    side_w = min(u * 0.46, (width / 2 - size * 0.6 - gap - u * 0.06))
    side_h = side_w * 0.62
    left = (cx - size * 0.6 - gap - side_w, cy - side_h - u * 0.02)
    right = (cx + size * 0.6 + gap, cy + u * 0.02)
    blocked = [(cx - size * 0.6, cy - size * 0.6, size * 1.2, size * 1.2), (left[0], left[1], side_w, side_h), (right[0], right[1], side_w, side_h)]
    body = confetti(width, height, blocked, 80, u * 0.1, 7, center=(cx, cy), spread=(size * 0.6, u * 0.95))
    body += month_card(left[0], left[1], side_w, side_h, u)
    body += budgets_card(right[0], right[1], side_w, side_h, u)
    body += icon(cx, cy, size)
    return page(width, height, body, rays=(cx, cy, u * 1.15))


def search(width, height):
    u = min(width / 3, height / 2) * 2
    gap = u * 0.035
    size = u * 0.3
    card_w = u * 0.44
    card_h = u * 0.27
    grid_w = card_w * 2 + gap
    total = size + gap * 2.2 + grid_w
    left = (width - total) / 2
    icon_cx = left + size / 2
    grid_x = left + size + gap * 2.2
    grid_y = height / 2 - card_h - gap / 2
    boxes = [
        (grid_x, grid_y), (grid_x + card_w + gap, grid_y),
        (grid_x, grid_y + card_h + gap), (grid_x + card_w + gap, grid_y + card_h + gap),
    ]
    blocked = [(left - size * 0.08, height / 2 - size * 0.58, size * 1.16, size * 1.16)]
    blocked += [(bx, by, card_w, card_h) for bx, by in boxes]
    body = confetti(width, height, blocked, 26, u * 0.07, 11)
    body += month_card(*boxes[0], card_w, card_h, u * 0.5)
    body += budgets_card(*boxes[1], card_w, card_h, u * 0.5)
    body += categories_card(*boxes[2], card_w, card_h, u * 0.5)
    body += journey_card(*boxes[3], card_w, card_h, u * 0.5)
    body += icon(icon_cx, height / 2, size)
    return page(width, height, body, rays=(icon_cx, height / 2, size * 1.4))


TARGETS = {
    "header-3840x1646": (header, 3840, 1646),
    "header-5244x2950": (header, 5244, 2950),
    "search-3840x2560": (search, 3840, 2560),
    "search-1920x1280": (search, 1920, 1280),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("targets", nargs="*", default=list(TARGETS))
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as work:
        for name in args.targets:
            builder, width, height = TARGETS[name]
            path = pathlib.Path(work) / f"{name}.html"
            path.write_text(builder(width, height))
            folder = "header" if name.startswith("header") else "search"
            out = MEDIA / folder / f"{name}.png"
            chrome(path, out, width, height)
            print(out)


if __name__ == "__main__":
    main()
