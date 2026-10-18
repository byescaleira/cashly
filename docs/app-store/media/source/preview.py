import argparse
import pathlib
import subprocess
import tempfile

from render import chrome

SOURCE = pathlib.Path(__file__).resolve().parent
MEDIA = SOURCE.parent
FFMPEG = "/opt/homebrew/bin/ffmpeg"
FADE = 0.35

IPHONE = {
    "size": (886, 1920),
    "output": "iphone-preview.mp4",
    "poster": ("poster.png", 4.0),
    "caption": {"top": 1640, "font": 44, "hold": 2.6},
    "segments": [
        ("Know where your money goes", [(0.3, 2.7, 1.0)]),
        ("Every budget has a pace bar", [(3.0, 7.7, 1.0)]),
        ("Record in 3 taps", [(11.5, 12.5, 1.0), (14.3, 17.0, 1.3), (21.8, 26.5, 1.6)]),
        ("See where the month lands", [(30.2, 39.6, 1.3)]),
        ("Make good habits a game", [(41.6, 49.5, 1.25)]),
    ],
}

IPAD = {
    "size": (1600, 1200),
    "output": "ipad-preview.mp4",
    "poster": ("ipad-poster.png", 6.3),
    "caption": {"top": 1060, "font": 36, "hold": 2.6},
    "segments": [
        ("Know where your money goes", [(0.2, 5.6, 0.9)]),
        ("Every budget has a pace bar", [(6.0, 8.3, 0.7)]),
        ("Every expense in its place", [(9.0, 10.3, 0.7)]),
        ("Make good habits a game", [(12.2, 15.3, 0.6)]),
    ],
}


def caption_png(text, size, top, font, path):
    width, height = size
    html = path.with_suffix(".html")
    html.write_text(
        "<!doctype html><html><head><meta charset='utf-8'>"
        f"<link rel='stylesheet' href='{(SOURCE / 'style.css').as_uri()}'>"
        f"<style>:root{{--w:{width}px;--h:{height}px}}body{{background:transparent}}"
        f".pill{{position:absolute;left:50%;top:{top}px;transform:translateX(-50%);white-space:nowrap;"
        f"padding:{font * 0.48:.0f}px {font * 0.9:.0f}px;border-radius:999px;background:var(--orange);"
        f"color:var(--paper);font:800 {font}px/1.05 'Cashly Rounded';letter-spacing:-0.01em;"
        "box-shadow:0 18px 40px -16px rgba(60,20,5,0.55)}</style></head>"
        f"<body><div class='pill'>{text}</div></body></html>"
    )
    chrome(html, path, width, height, transparent=True)


def build(config, recording):
    width, height = config["size"]
    out_dir = MEDIA / "preview"
    out_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        work = pathlib.Path(work)
        steady = work / "steady.mp4"
        subprocess.run(
            [FFMPEG, "-v", "error", "-y", "-i", str(recording), "-vf",
             f"fps=30,scale={width}:-2:flags=lanczos,crop={width}:{height}:0:0,setsar=1",
             "-fps_mode", "cfr", "-c:v", "libx264", "-crf", "10", "-preset", "fast", "-an", str(steady)],
            check=True)
        inputs, filters, labels, durations = ["-i", str(steady)], [], [], []
        for index, (text, ranges) in enumerate(config["segments"]):
            png = work / f"caption-{index}.png"
            caption_png(text, config["size"], config["caption"]["top"], config["caption"]["font"], png)
            inputs += ["-loop", "1", "-i", str(png)]
            parts = []
            total = 0.0
            for part, (start, end, speed) in enumerate(ranges):
                label = f"s{index}p{part}"
                filters.append(
                    f"[0:v]trim={start}:{end},setpts=(PTS-STARTPTS)/{speed},fps=30[{label}]")
                parts.append(f"[{label}]")
                total += (end - start) / speed
            filters.append(f"{''.join(parts)}concat=n={len(parts)}:v=1:a=0[c{index}]")
            filters.append(
                f"[{index + 1}:v]format=rgba,trim=0:{total:.3f},setpts=PTS-STARTPTS,fps=30,"
                f"fade=t=in:st=0.15:d=0.3:alpha=1,fade=t=out:st={min(config['caption']['hold'], total - 0.45):.3f}:d=0.3:alpha=1[t{index}]")
            filters.append(f"[c{index}][t{index}]overlay=0:0:shortest=1,format=yuv420p[v{index}]")
            labels.append(f"[v{index}]")
            durations.append(total)
        current, offset = labels[0], 0.0
        for index in range(1, len(labels)):
            offset += durations[index - 1] - FADE
            target = f"[x{index}]"
            filters.append(f"{current}{labels[index]}xfade=transition=fade:duration={FADE}:offset={offset:.3f}{target}")
            current = target
        total = sum(durations) - FADE * (len(durations) - 1)
        output = out_dir / config["output"]
        command = [
            FFMPEG, "-v", "error", "-y", *inputs,
            "-f", "lavfi", "-t", f"{total:.3f}", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
            "-filter_complex", ";".join(filters),
            "-map", current, "-map", f"{len(config['segments']) + 1}:a",
            "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-pix_fmt", "yuv420p",
            "-r", "30", "-b:v", "10M", "-maxrate", "12M", "-bufsize", "20M",
            "-c:a", "aac", "-b:a", "256k", "-ac", "2", "-ar", "44100",
            "-t", f"{total:.3f}", "-movflags", "+faststart", str(output),
        ]
        subprocess.run(command, check=True)
        poster, at = config["poster"]
        subprocess.run(
            [FFMPEG, "-v", "error", "-y", "-ss", str(at), "-i", str(output), "-frames:v", "1",
             "-pix_fmt", "rgb24", str(out_dir / poster)], check=True)
        print(output, f"{total:.2f}s")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("device", choices=["iphone", "ipad"])
    parser.add_argument("recording", type=pathlib.Path)
    args = parser.parse_args()
    build(IPHONE if args.device == "iphone" else IPAD, args.recording)


if __name__ == "__main__":
    main()
