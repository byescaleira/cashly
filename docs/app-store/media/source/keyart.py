import argparse
import base64
import pathlib
import tempfile

from render import chrome

SOURCE = pathlib.Path(__file__).resolve().parent
MEDIA = SOURCE.parent
ICON = SOURCE / "raw" / "keyart" / "icon.png"

PAPER = "#fbf5ea"
INK = "#2a1a12"
MUSTARD = "#e3b04b"
OLIVE = "#9db35c"
RUST = "#a63d2c"
TEAL = "#62aba2"
DENIM = "#7fa0c6"

GLYPHS = {
    "cart": '<path d="M3 4h2l2.4 11h11L21 7H6.2"/><circle cx="9" cy="19.5" r="1.3"/><circle cx="17" cy="19.5" r="1.3"/>',
    "fork": '<path d="M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M16 21V3c-2 1-3 4-3 8h3"/>',
    "car": '<path d="M4 16v-4l2-5h12l2 5v4zM4 16v3M20 16v3"/><circle cx="7.5" cy="13" r="0.8"/><circle cx="16.5" cy="13" r="0.8"/>',
}


def icon_uri():
    return "data:image/png;base64," + base64.b64encode(ICON.read_bytes()).decode()


def page(width, height, body):
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
html, body {{ margin: 0; width: {width}px; height: {height}px; overflow: hidden; }}
body {{ position: relative; background:
  radial-gradient(60% 70% at 50% 45%, #db7a40 0%, #c2602a 45%, #a3442a 100%); }}
.grain {{ position: absolute; inset: 0; background:
  radial-gradient(40% 45% at 50% 50%, rgba(251, 245, 234, 0.22), transparent 70%); }}
.bar {{ position: absolute; border-radius: 999px; background: rgba(251, 245, 234, 0.13); overflow: hidden; }}
.bar i {{ position: absolute; inset: 0 auto 0 0; border-radius: 999px; }}
.marker {{ position: absolute; border-radius: 999px; background: {PAPER}; opacity: 0.9; }}
.icon {{ position: absolute; filter: drop-shadow(0 0 0 transparent); }}
.icon img {{ width: 100%; height: 100%; display: block; filter: drop-shadow(0 {height * 0.035:.0f}px {height * 0.06:.0f}px rgba(70, 20, 5, 0.45)); }}
.card {{ position: absolute; background: {PAPER}; box-shadow: 0 {height * 0.04:.0f}px {height * 0.09:.0f}px -{height * 0.02:.0f}px rgba(70, 20, 5, 0.5); }}
.row {{ position: absolute; display: flex; align-items: center; }}
.badge {{ display: grid; place-items: center; flex: none; }}
.badge svg {{ fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; }}
.track {{ position: relative; flex: 1; border-radius: 999px; overflow: visible; }}
.track i {{ position: absolute; inset: 0 auto 0 0; border-radius: 999px; }}
.track b {{ position: absolute; border-radius: 999px; background: {INK}; opacity: 0.85; }}
</style></head><body><div class="grain"></div>{body}</body></html>"""


def bars(width, height, specs, thickness, marker=None):
    out = ""
    for top, left, length, fill, color in specs:
        mark = ""
        if marker is not None:
            mark = (
                f"<b style='position:absolute;left:{marker * 100}%;top:-{thickness * 0.3}px;"
                f"width:{thickness * 0.16}px;height:{thickness * 1.6}px;border-radius:999px;background:{INK};opacity:0.55'></b>"
            )
        out += (
            f"<div class='bar' style='left:{left * width}px;top:{top * height - thickness / 2}px;"
            f"width:{length * width}px;height:{thickness}px;overflow:visible'>"
            f"<i style='width:{fill * 100}%;background:{color}'></i>{mark}</div>"
        )
    return out


def icon(cx, cy, size):
    return (
        f"<div class='icon' style='left:{cx - size / 2}px;top:{cy - size / 2}px;width:{size}px;height:{size}px'>"
        f"<img src='{icon_uri()}'></div>"
    )


def header(width, height):
    unit = min(width / 16, height / 9)
    thickness = unit * 0.7
    specs = [
        (0.22, -0.04, 0.50, 0.80, MUSTARD),
        (0.38, -0.04, 0.50, 0.55, PAPER),
        (0.54, -0.04, 0.50, 0.95, OLIVE),
        (0.70, -0.04, 0.50, 0.62, PAPER),
        (0.30, 0.54, 0.50, 0.70, OLIVE),
        (0.46, 0.54, 0.50, 0.40, MUSTARD),
        (0.62, 0.54, 0.50, 0.85, PAPER),
        (0.78, 0.54, 0.50, 0.50, MUSTARD),
    ]
    body = bars(width, height, specs, thickness, marker=0.66)
    size = unit * 4.6
    body += icon(width / 2, height / 2, size)
    return page(width, height, body)


def card_rows(left, top, width, height, rows):
    out = ""
    pad = width * 0.075
    row_height = (height - pad * 2) / len(rows)
    badge = row_height * 0.52
    for index, (glyph, color, fill, elapsed) in enumerate(rows):
        y = top + pad + row_height * index
        out += (
            f"<div class='row' style='left:{left + pad}px;top:{y}px;width:{width - pad * 2}px;height:{row_height}px;gap:{badge * 0.5}px'>"
            f"<span class='badge' style='width:{badge}px;height:{badge}px;border-radius:{badge * 0.28}px;"
            f"background:color-mix(in srgb, {color} 22%, transparent);color:{color}'>"
            f"<svg viewBox='0 0 24 24' style='width:{badge * 0.56}px;height:{badge * 0.56}px;stroke-width:2.2'>{GLYPHS[glyph]}</svg></span>"
            f"<span class='track' style='height:{badge * 0.36}px;background:color-mix(in srgb, {color} 22%, transparent)'>"
            f"<i style='width:{fill * 100}%;background:{color}'></i>"
            f"<b style='left:{elapsed * 100}%;top:-{badge * 0.12}px;width:{badge * 0.07}px;height:{badge * 0.6}px'></b></span></div>"
        )
    return out


def search(width, height):
    unit = min(width / 3, height / 2)
    thickness = unit * 0.075
    specs = [
        (0.12, -0.08, 0.50, 0.7, MUSTARD),
        (0.90, 0.55, 0.60, 0.45, OLIVE),
    ]
    body = bars(width, height, specs, thickness)
    size = unit * 0.95
    card_width = unit * 1.45
    card_height = unit * 0.95
    overlap = size * 0.22
    total = size - overlap + card_width
    left = (width - total) / 2
    card_left = left + size - overlap
    card_top = height / 2 - card_height / 2
    body += (
        f"<div class='card' style='left:{card_left}px;top:{card_top}px;width:{card_width}px;"
        f"height:{card_height}px;border-radius:{unit * 0.12}px'></div>"
    )
    body += card_rows(card_left + overlap, card_top, card_width - overlap, card_height, [
        ("cart", "#5f7a2e", 0.62, 0.55),
        ("fork", "#b8841c", 0.88, 0.55),
        ("car", RUST, 1.0, 0.55),
    ])
    body += icon(left + size / 2, height / 2, size)
    return page(width, height, body)


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
