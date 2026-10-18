import argparse
import base64
import pathlib
import tempfile

from PIL import Image

from render import chrome

SOURCE = pathlib.Path(__file__).resolve().parent
MEDIA = SOURCE.parent
RAW = SOURCE / "raw"
ICON = SOURCE.parents[3] / "Cashly" / "Cashly" / "CashlyIcon.icon" / "Assets"

SIZES = {
    "iphone": (1320, 2868),
    "ipad": (2064, 2752),
    "mac": (2880, 1800),
    "vision": (3840, 2160),
    "header-wide": (5244, 2950),
    "header-banner": (3840, 1646),
}


def uri(path: pathlib.Path) -> str:
    return path.resolve().as_uri()


def raw(name: str) -> pathlib.Path:
    return RAW / name


def copy(title, subtitle, left, top, width, size, align="center"):
    sub = f"<p style='font-size:{size * 0.42:.0f}px'>{subtitle}</p>" if subtitle else ""
    return (
        f"<div class='copy' style='left:{left}px;top:{top}px;width:{width}px;text-align:{align}'>"
        f"<h1 style='font-size:{size}px'>{title}</h1>{sub}</div>"
    )


def iphone(shot, left, top, width):
    return (
        f"<div class='iphone' style='--d:{width}px;left:{left}px;top:{top}px'>"
        "<span class='button action'></span><span class='button up'></span>"
        "<span class='button down'></span><span class='button power'></span>"
        f"<div class='bezel'><div class='screen'><img class='shot' src='{uri(raw(shot))}'><span class='island'></span></div></div></div>"
    )


def ipad(shot, left, top, width):
    image = Image.open(raw(shot))
    ratio = image.height / image.width
    return (
        f"<div class='ipad' style='--d:{width}px;--ratio:{ratio};left:{left}px;top:{top}px'>"
        f"<div class='screen'><img class='shot' src='{uri(raw(shot))}'></div></div>"
    )


def card(shot, crop, scale, left, top, radius=66):
    x, y, w, h = crop
    image = Image.open(raw(shot))
    return (
        f"<div class='card' style='--s:{scale};left:{left}px;top:{top}px;width:{w * scale:.1f}px;"
        f"height:{h * scale:.1f}px;border-radius:{radius * scale:.1f}px;"
        f"background-image:url({uri(raw(shot))});background-size:{image.width * scale:.1f}px auto;"
        f"background-position:{-x * scale:.1f}px {-y * scale:.1f}px'></div>"
    )


def app_content(shot, width, trim):
    image = Image.open(raw(shot))
    scale = width / image.width
    height = (image.height - trim) * scale
    return height, (
        f"<div class='content' style='width:{width}px;height:{height:.1f}px'>"
        f"<img src='{uri(raw(shot))}' style='top:{-trim * scale:.1f}px'></div>"
    )


def mac_window(shot, left, top, width, bar, radius, title="Cashly", trim=52):
    height, content = app_content(shot, width, trim)
    return (
        f"<div class='window' style='--r:{radius}px;--bar:{bar}px;left:{left}px;top:{top}px;width:{width}px'>"
        f"<div class='titlebar'><i></i><i></i><i></i><span>{title}</span></div>{content}</div>"
    )


def macbook(shot, left, top, width, window_width, title="Cashly"):
    display_height = width / 1.54
    bar = width * 0.022
    window_left = (width - window_width) / 2
    window_top = display_height * 0.075
    menu = (
        "<div class='menubar'><b></b><b>Cashly</b><span>File</span><span>Edit</span>"
        "<span>View</span><span>Window</span><span>Help</span><span class='clock'>Sat Oct 17  9:41 AM</span></div>"
    )
    return (
        f"<div class='macbook' style='--d:{width}px;left:{left}px;top:{top}px'><div class='mac-lid'>"
        f"<div class='mac-display'><span class='notch'></span>{menu}"
        f"{mac_window(shot, window_left, window_top, window_width, bar, width * 0.008, title)}"
        "</div></div><div class='mac-base'></div></div>"
    )


def vision_window(shot, left, top, width, radius, trim=52):
    height, content = app_content(shot, width, trim)
    pad = radius * 0.32
    return (
        f"<div class='glass' style='--r:{radius}px;left:{left - pad:.1f}px;top:{top - pad:.1f}px'>{content}</div>"
        f"<div class='grabber' style='--r:{radius}px;left:{left + width / 2:.1f}px;top:{top + height + pad + radius * 0.55:.1f}px'></div>"
    )


def icon(left, top, size):
    masks = {
        "star": "Star.svg",
        "rect": "Rectangle 2.svg",
        "dollar": "Vector.svg",
        "pocket": "Rectangle 4.svg",
    }
    variables = ";".join(
        f"--{key}:url(data:image/svg+xml;base64,{base64.b64encode((ICON / name).read_bytes()).decode()})"
        for key, name in masks.items())
    return (
        f"<div class='icon' style='--size:{size}px;--size-n:{size};left:{left}px;top:{top}px;{variables};"
        f"filter:drop-shadow(0 {size * 0.05:.0f}px {size * 0.08:.0f}px rgba(0,0,0,0.3))'><div class='canvas'>"
        "<div class='wrap' style='filter:drop-shadow(0 6px 10px rgba(0,0,0,0.2))'><div class='layer star'></div></div>"
        "<div class='wrap' style='filter:drop-shadow(0 10px 22px rgba(80,40,10,0.25))'><div class='layer rect'></div><div class='layer rect-shade'></div>"
        "<div class='layer dollar'></div></div>"
        "<div class='wrap' style='filter:drop-shadow(0 -10px 18px rgba(80,40,10,0.28))'><div class='layer pocket'></div></div>"
        "</div></div>"
    )


def page(size, background, body, light=False):
    width, height = size
    style = uri(SOURCE / "style.css")
    return (
        "<!doctype html><html><head><meta charset='utf-8'>"
        f"<link rel='stylesheet' href='{style}'>"
        f"<style>:root{{--w:{width}px;--h:{height}px;--bg:{background}}}</style></head>"
        f"<body class='{'light' if light else ''}'>{body}</body></html>"
    )


def room(size, body):
    width, height = size
    style = uri(SOURCE / "style.css")
    return (
        "<!doctype html><html><head><meta charset='utf-8'>"
        f"<link rel='stylesheet' href='{style}'>"
        f"<style>:root{{--w:{width}px;--h:{height}px;--bg:#d9cfbd}}</style></head>"
        f"<body class='room light'>{body}</body></html>"
    )


IPHONE = [
    ("01-pace", "var(--orange)", False, "Know where your money goes",
     "Every budget has a pace bar, so you see trouble while there is still time to fix it.",
     "goals.png", []),
    ("02-record", "var(--teal)", False, "Record in 3 taps",
     "The amount comes first. Pick a category and you are done. Tags fill themselves in.",
     "editor.png", []),
    ("03-forecast", "var(--denim)", False, "See where the month lands",
     "Cashly Pro forecasts the month and flags spending that is out of the ordinary.",
     "home-forecast.png",
     [("home-unusual.png", (40, 1555, 1240, 375), 0.78, 30, 2150, 66),
      ("home-small.png", (62, 369, 1196, 455), 0.66, 500, 2500, 66)]),
    ("04-journey", "var(--mustard)", True, "Make good habits a game",
     "Levels, streaks, missions and challenges turn every month into progress.",
     "journey.png",
     [("journey-2.png", (62, 1089, 1196, 550), 0.72, 400, 2160, 66)]),
    ("05-anywhere", "var(--olive)", False, "Record from anywhere",
     "Widgets, Siri, Control Center, the Action button and Apple Pay capture.",
     "widgets-2.png",
     [("widgets-3.png", (62, 674, 1196, 316), 0.8, 60, 2280, 66)]),
    ("06-private", "var(--brown)", False, "No account. No bank login.",
     "Your data stays on your devices and in your own iCloud. Export anytime, for free.",
     "data.png",
     [("privacy.png", (62, 1297, 1196, 760), 0.62, 560, 2280, 66)]),
    ("07-split", "var(--plum)", False, "Split costs fairly",
     "Equally, by percentage or by a fixed amount, and see who still owes you.",
     "split.png", []),
    ("08-pro", "var(--rust)", False, "Go further with Cashly Pro",
     "Forecasts, smart suggestions and automatic backups. Try it free for 7 days.",
     "paywall.png", []),
]

IPAD = [
    ("01-pace", "var(--orange)", False, "Know where your money goes",
     "Every budget has a pace bar, so you see trouble while there is still time to fix it.",
     "ipad/goals.png"),
    ("02-forecast", "var(--denim)", False, "See where the month lands",
     "Cashly Pro forecasts the month and flags spending that is out of the ordinary.",
     "ipad/home.png"),
    ("03-history", "var(--teal)", False, "Every expense in its place",
     "Categories, tags and splits, with the whole month at a glance.",
     "ipad/history.png"),
    ("04-journey", "var(--mustard)", True, "Make good habits a game",
     "Levels, streaks, missions and challenges turn every month into progress.",
     "ipad/journey.png"),
]

MAC = [
    ("01-overview", "var(--orange)", False, "Know where your money goes",
     "Budgets, forecasts and history side by side on a big screen.", "ipad/landscape-home.png"),
    ("02-pace", "var(--teal)", False, "Every budget on pace",
     "The fill is what you spent. The line is how much of the month has gone by.", "ipad/landscape-goals.png"),
    ("03-details", "var(--denim)", False, "Details beside the list",
     "Open any expense next to your history to split, tag or edit it.", "ipad/landscape-inspector.png"),
    ("04-journey", "var(--mustard)", True, "Make good habits a game",
     "Levels, streaks, missions and challenges, synced across your devices.", "ipad/landscape-journey.png"),
]

VISION = [
    ("01-overview", "Know where your money goes", "Your month, right in front of you.", "ipad/landscape-home.png"),
    ("02-pace", "Every budget on pace", "See trouble while there is still time to fix it.", "ipad/landscape-goals.png"),
    ("03-journey", "Make good habits a game", "Levels, streaks, missions and challenges.", "ipad/landscape-journey.png"),
]


def iphone_slide(spec):
    name, background, light, title, subtitle, shot, cards = spec
    width = 900
    body = copy(title, subtitle, 110, 170, 1100, 120)
    body += iphone(shot, (1320 - width * 1.078) / 2, 720, width)
    body += "".join(card(*item) for item in cards)
    return name, page(SIZES["iphone"], background, body, light)


def ipad_slide(spec):
    name, background, light, title, subtitle, shot = spec
    width = 1600
    body = copy(title, subtitle, 132, 170, 1800, 132)
    body += ipad(shot, (2064 - width * 1.068) / 2, 720, width)
    return name, page(SIZES["ipad"], background, body, light)


def mac_slide(spec):
    name, background, light, title, subtitle, shot = spec
    width = 2280
    body = copy(title, subtitle, 240, 110, 2400, 108)
    body += macbook(shot, (2880 - width * 1.032) / 2, 470, width, width * 0.8)
    return name, page(SIZES["mac"], background, body, light)


def vision_slide(spec):
    name, title, subtitle, shot = spec
    width = 1960
    body = copy(title, subtitle, 420, 130, 3000, 124)
    body += vision_window(shot, (3840 - width) / 2, 520, width, 60)
    return name, room(SIZES["vision"], body)


def header(size):
    width, height = size
    unit = min(width / 4300, height / 1500)
    left = width / 2 - 1330 * unit
    middle = height / 2
    body = icon(left, middle - 470 * unit, 190 * unit)
    body += (
        f"<div class='copy' style='left:{left}px;top:{middle - 230 * unit}px;width:{1120 * unit}px;text-align:left'>"
        f"<h1 style='font-size:{138 * unit:.0f}px'>Know where your money goes</h1>"
        f"<p style='font-size:{54 * unit:.0f}px'>See if every budget is on pace before the month ends. No account, no bank login.</p></div>"
    )
    ipad_left = width / 2 + 60 * unit
    body += ipad("ipad/landscape-home.png", ipad_left, middle - 430 * unit, 1240 * unit)
    body += iphone("iphone/goals.png", ipad_left - 150 * unit, middle - 330 * unit, 380 * unit)
    return page(size, "var(--orange)", body)


def build(device, slides, folder, builder):
    out = MEDIA / folder
    with tempfile.TemporaryDirectory() as work:
        for spec in slides:
            name, html = builder(spec)
            path = pathlib.Path(work) / f"{name}.html"
            path.write_text(html)
            size = SIZES[device]
            chrome(path, out / f"{name}.png", *size)
            print(out / f"{name}.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("targets", nargs="*", default=["iphone", "ipad", "header"])
    args = parser.parse_args()
    if "iphone" in args.targets:
        build("iphone", [(*s[:5], "iphone/" + s[5], [("iphone/" + c[0], *c[1:]) for c in s[6]]) for s in IPHONE], "iphone", iphone_slide)
    if "ipad" in args.targets:
        build("ipad", IPAD, "ipad", ipad_slide)
    if "mac" in args.targets:
        build("mac", MAC, "mac", mac_slide)
    if "vision" in args.targets:
        build("vision", VISION, "vision", vision_slide)
    if "header" in args.targets:
        with tempfile.TemporaryDirectory() as work:
            for key, name in (("header-wide", "header-5244x2950"), ("header-banner", "header-3840x1646")):
                path = pathlib.Path(work) / f"{name}.html"
                path.write_text(header(SIZES[key]))
                chrome(path, MEDIA / "header" / f"{name}.png", *SIZES[key])
                print(MEDIA / "header" / f"{name}.png")


if __name__ == "__main__":
    main()
