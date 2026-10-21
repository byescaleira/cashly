import argparse
import json
import pathlib
import subprocess
import tempfile

from render import chrome

SOURCE = pathlib.Path(__file__).resolve().parent
MEDIA = SOURCE.parent
RECORDINGS = SOURCE / "raw" / "recordings"
FFMPEG = "/opt/homebrew/bin/ffmpeg"
MUSIC = pathlib.Path.home() / ".claude/plugins/cache/brag/brag/0.4.0/skills/brag/assets/music"
CUES = MUSIC / "cues" / "happy-beats-business-moves-vol-11-by-ende-dot-app.music-cues.json"
RISE = 30
ENTER_DELAY = 0.12
ENTER = 0.3
EXIT = 0.2

IPHONE = {
    "size": (886, 1920),
    "recording": "iphone-take2.mp4",
    "output": "iphone-preview.mp4",
    "poster": ("poster.png", 4.4),
    "caption": {"style": "band", "height": 112, "font": 44},
    "cuts": [0.0, 5.282, 13.700, 20.538, 24.753, 28.967],
    "segments": [
        ("Know where your money goes", [(2.34, 3.0, 0.5), (3.0, None, 1)]),
        ("Record in 3 taps", [
            (17.8, 18.9, 1), (21.1, 22.0, 1), (28.3, 32.7, 2),
            (33.8, 34.4, 1), (35.6, 36.7, 1), (44.0, None, 1)]),
        ("See where the month lands", [
            (54.25, 54.95, 1), (61.95, 64.6, 1), (73.45, 75.2, 1.25), (76.75, None, 1)]),
        ("Make good habits a game", [(87.75, None, 1)]),
        ("Your data, your iCloud", [(101.6, None, 1)]),
    ],
}

IPAD = {
    "size": (1200, 1600),
    "recording": "ipad-take1.mp4",
    "output": "ipad-preview.mp4",
    "poster": ("ipad-poster.png", 4.4),
    "caption": {"style": "pill", "top": 1452, "font": 44},
    "cuts": [0.0, 5.282, 13.700, 20.538, 24.753, 28.967],
    "segments": [
        ("Know where your money goes", [(4.22, 5.0, 0.5), (5.0, None, 1)]),
        ("Record in 3 taps", [
            (21.2, 22.0, 1), (23.3, 24.0, 1), (28.9, 33.0, 2.5),
            (41.3, 41.9, 1), (43.6, 44.2, 1), (62.8, 64.0, 1), (69.6, None, 1)]),
        ("See where the month lands", [(80.75, 83.25, 1), (92.5, None, 1)]),
        ("Make good habits a game", [(104.25, None, 1)]),
        ("Your data, your iCloud", [(123.0, None, 1)]),
    ],
}


SHADOW = "0 14px 34px -12px rgba(60,20,5,0.5),0 3px 8px rgba(60,20,5,0.18)"


def layer_png(size, body, path):
    width, height = size
    html = path.with_suffix(".html")
    html.write_text(
        "<!doctype html><html><head><meta charset='utf-8'>"
        f"<link rel='stylesheet' href='{(SOURCE / 'style.css').as_uri()}'>"
        f"<style>:root{{--w:{width}px;--h:{height}px}}body{{background:transparent}}"
        ".band{position:absolute;left:0;right:0;top:0;background:var(--orange);"
        f"box-shadow:{SHADOW}}}"
        ".pill{position:absolute;left:50%;transform:translateX(-50%);white-space:nowrap;"
        f"border-radius:999px;background:var(--orange);box-shadow:{SHADOW}}}"
        ".text{position:absolute;left:0;right:0;text-align:center;white-space:nowrap;"
        "color:var(--paper);font-weight:800;line-height:1;letter-spacing:-0.01em}"
        f"</style></head><body>{body}</body></html>"
    )
    chrome(html, path, width, height, transparent=True)


def backdrop_png(config, path):
    caption = config["caption"]
    if caption["style"] != "band":
        return None
    layer_png(config["size"], f"<div class='band' style='height:{caption['height']}px'></div>", path)
    return path


def caption_png(config, text, path):
    caption = config["caption"]
    font = caption["font"]
    if caption["style"] == "band":
        body = (f"<div class='text' style='top:{caption['height'] / 2 + caption.get('nudge', 0) - font * 0.5:.0f}px;"
                f"font-size:{font}px'>{text}</div>")
    else:
        body = (f"<div class='pill' style='top:{caption['top']}px;padding:{font * 0.46:.0f}px {font * 0.86:.0f}px;"
                f"color:var(--paper);font:800 {font}px/1.08 \"Cashly Rounded\";letter-spacing:-0.01em'>{text}</div>")
    layer_png(config["size"], body, path)


def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True)


def beats():
    return [beat["time"] for beat in json.loads(CUES.read_text())["beats"]]


def resolve(config):
    cuts = config["cuts"]
    plan = []
    for index, (text, ranges) in enumerate(config["segments"]):
        target = cuts[index + 1] - cuts[index]
        fixed = sum((end - start) / speed for start, end, speed in ranges if end is not None)
        clips = []
        for start, end, speed in ranges:
            if end is None:
                end = start + (target - fixed) * speed
            clips.append((start, end, speed))
        plan.append((text, clips, target))
    return plan


def steady(config, work):
    width, height = config["size"]
    path = work / "steady.mp4"
    run([FFMPEG, "-v", "error", "-y", "-i", str(RECORDINGS / config["recording"]), "-vf",
         f"fps=60,scale={width}:-2:flags=lanczos,crop={width}:{height}:0:(ih-{height})/2,setsar=1",
         "-fps_mode", "cfr", "-c:v", "libx264", "-crf", "8", "-preset", "fast", "-an", str(path)])
    return path


def silence(total, work):
    path = work / "silence.wav"
    run([FFMPEG, "-v", "error", "-y", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
         "-t", f"{total:.3f}", "-ac", "2", "-ar", "48000", str(path)])
    return path


def build(config):
    out_dir = MEDIA / "preview"
    plan = resolve(config)
    total = config["cuts"][-1]
    grid = beats()
    for cut in config["cuts"][1:-1]:
        print(f"cut {cut:.3f}s, nearest beat {min(grid, key=lambda beat: abs(beat - cut)):.3f}s")
    with tempfile.TemporaryDirectory() as work:
        work = pathlib.Path(work)
        source = steady(config, work)
        inputs, filters, labels = ["-i", str(source)], [], []
        for index, (text, clips, duration) in enumerate(plan):
            parts = []
            for part, (start, end, speed) in enumerate(clips):
                label = f"s{index}p{part}"
                filters.append(
                    f"[0:v]trim={start:.3f}:{end:.3f},setpts=(PTS-STARTPTS)/{speed},fps=30[{label}]")
                parts.append(f"[{label}]")
            filters.append(f"{''.join(parts)}concat=n={len(parts)}:v=1:a=0,"
                           f"trim=0:{duration:.3f},setpts=PTS-STARTPTS,format=yuv420p[c{index}]")
            labels.append(f"[c{index}]")
        filters.append(f"{''.join(labels)}concat=n={len(labels)}:v=1:a=0,format=rgba[base]")
        layers = []
        backdrop = backdrop_png(config, work / "backdrop.png")
        if backdrop:
            layers.append((backdrop, 0.0, total, False))
        cuts = config["cuts"]
        for index, (text, _, _) in enumerate(plan):
            png = work / f"caption-{index}.png"
            caption_png(config, text, png)
            layers.append((png, cuts[index], cuts[index + 1], index != len(plan) - 1))
        current = "[base]"
        for index, (png, start, end, leaves) in enumerate(layers):
            inputs += ["-loop", "1", "-framerate", "30", "-t", f"{total:.3f}", "-i", str(png)]
            enter = start + (ENTER_DELAY if start > 0 or not backdrop else 0)
            fades = f"fade=t=in:st={enter:.3f}:d={ENTER}:alpha=1"
            if leaves:
                fades += f",fade=t=out:st={end - EXIT:.3f}:d={EXIT}:alpha=1"
            filters.append(f"[{index + 1}:v]format=rgba,{fades}[l{index}]")
            rise = f"{RISE}*pow(1-min(max((t-{enter:.3f})/{ENTER},0),1),3)"
            target = f"[o{index}]"
            filters.append(
                f"{current}[l{index}]overlay=x=0:y='{rise}':eval=frame:shortest=1:"
                f"enable='between(t,{start:.3f},{end:.3f})'{target}")
            current = target
        filters.append(f"{current}format=yuv420p[video]")
        audio = silence(total, work)
        inputs += ["-i", str(audio)]
        output = out_dir / config["output"]
        run([FFMPEG, "-v", "error", "-y", *inputs,
             "-filter_complex", ";".join(filters),
             "-map", "[video]", "-map", f"{len(layers) + 1}:a",
             "-c:v", "libx264", "-profile:v", "high", "-level", "4.2", "-pix_fmt", "yuv420p",
             "-r", "30", "-b:v", "10M", "-maxrate", "12M", "-bufsize", "20M",
             "-c:a", "aac", "-b:a", "256k", "-ac", "2", "-ar", "48000",
             "-t", f"{total:.3f}", "-movflags", "+faststart", str(output)])
        poster, at = config["poster"]
        run([FFMPEG, "-v", "error", "-y", "-ss", str(at), "-i", str(output), "-frames:v", "1",
             "-pix_fmt", "rgb24", str(out_dir / poster)])
        print(output, f"{total:.2f}s")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("device", choices=["iphone", "ipad"])
    args = parser.parse_args()
    build(IPHONE if args.device == "iphone" else IPAD)


if __name__ == "__main__":
    main()
