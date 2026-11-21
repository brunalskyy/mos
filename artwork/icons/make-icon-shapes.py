#!/usr/bin/env python3
"""Build the mOS icon themes (PNG) from the SVG sources in artwork/icons/src.

KDE draws SVG icons with QtSvg, which ignores clip paths, so a shaped icon
would show its square background. We render PNGs with librsvg instead, in
every size Plasma asks for, one theme per shape:

  mOS             Circle (default)
  mOS-Squircle    Squircle (macOS style)
  mOS-Rounded     Rounded square

The mOS logo goes into hicolor as PNGs too.
Run from the repo root:  python3 artwork/icons/make-icon-shapes.py
"""
import os, re, shutil, subprocess, tempfile

SRC = "artwork/icons/src"
OUT = "build/config/includes.chroot/usr/share/icons"
SIZES = [16, 22, 24, 32, 48, 64, 96, 128, 256]

CIRCLE = "M64 0A64 64 0 1 1 64 128A64 64 0 1 1 64 0Z"
R = 28
ROUNDED = (f"M{R} 0H{128-R}A{R} {R} 0 0 1 128 {R}V{128-R}A{R} {R} 0 0 1 {128-R} 128"
           f"H{R}A{R} {R} 0 0 1 0 {128-R}V{R}A{R} {R} 0 0 1 {R} 0Z")

def superellipse(n, size=128, steps=360):
    """Samsung One UI-style squircle: smooth corners that curve in gradually."""
    import math
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, si = math.cos(t), math.sin(t)
        x = (abs(c) ** (2 / n)) * (1 if c >= 0 else -1)
        y = (abs(si) ** (2 / n)) * (1 if si >= 0 else -1)
        pts.append(((x + 1) * size / 2, (y + 1) * size / 2))
    return "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + "Z"


SQUIRCLE = superellipse(3.2)

THEMES = {
    "mOS": ("mOS Circle", "mOS app icons, circle shape (default)", CIRCLE),
    "mOS-Squircle": ("mOS Squircle", "mOS app icons, One UI-style squircle", SQUIRCLE),
    "mOS-Rounded": ("mOS Rounded square", "mOS app icons, rounded square shape", ROUNDED),
}


def render(svg_text, size, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as t:
        t.write(svg_text)
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), t.name, "-o", dest], check=True)
    os.unlink(t.name)


def index(name, comment):
    dirs = ",".join(f"{s}x{s}/apps" for s in SIZES)
    out = [f"[Icon Theme]\nName={name}\nComment={comment}\nInherits=breeze,breeze-dark,hicolor\nDirectories={dirs}\n"]
    for s in SIZES:
        out.append(f"[{s}x{s}/apps]\nSize={s}\nContext=Applications\nType=Threshold\n")
    return "\n".join(out)


if __name__ == "__main__":
    sources = sorted(f for f in os.listdir(SRC) if f.endswith(".svg"))
    for folder, (name, comment, shape) in THEMES.items():
        root = os.path.join(OUT, folder)
        shutil.rmtree(root, ignore_errors=True)
        os.makedirs(root)
        open(os.path.join(root, "index.theme"), "w").write(index(name, comment))
        n = 0
        for fn in sources:
            if fn == "mos-logo.svg":
                continue
            s = open(os.path.join(SRC, fn)).read()
            m = re.search(r'<clipPath id="\w+"><path d="([^"]+)"', s)
            if m and shape:
                s = s.replace(m.group(1), shape)
            for size in SIZES:
                render(s, size, os.path.join(root, f"{size}x{size}", "apps", fn[:-4] + ".png"))
            n += 1
        print(f"{folder}: {n} icons x {len(SIZES)} sizes")

    logo = open(os.path.join(SRC, "mos-logo.svg")).read()
    for size in SIZES:
        render(logo, size, os.path.join(OUT, "hicolor", f"{size}x{size}", "apps", "mos-logo.png"))
    print("hicolor: mos-logo")
