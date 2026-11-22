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


M_PATH = "M300 680 V450 A106 106 0 0 1 512 450 V680 M512 450 A106 106 0 0 1 724 450 V680"


def start_icon(shape):
    """mOS logo for the Start button: Amber gradient filling the whole shape, solid white m."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="shape"><path transform="scale(8)" d="{shape}"/></clipPath>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFD36B"/><stop offset="0.5" stop-color="#FF9A3C"/><stop offset="1" stop-color="#E8505B"/>
    </linearGradient>
    <radialGradient id="glowA" cx="0.22" cy="0.18" r="0.6">
      <stop offset="0" stop-color="#FFF4C2" stop-opacity="0.8"/><stop offset="1" stop-color="#FFF4C2" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glowB" cx="0.85" cy="0.9" r="0.55">
      <stop offset="0" stop-color="#C2185B" stop-opacity="0.45"/><stop offset="1" stop-color="#C2185B" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.25"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="rim" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.7"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.06"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0.35"/>
    </linearGradient>
    <linearGradient id="mfill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#FFF3E6"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="18"/></filter>
  </defs>
  <g clip-path="url(#shape)">
    <rect width="1024" height="1024" fill="url(#bg)"/>
    <rect width="1024" height="1024" fill="url(#glowA)"/>
    <rect width="1024" height="1024" fill="url(#glowB)"/>
    <rect width="1024" height="1024" fill="url(#sheen)"/>
    <path d="{M_PATH}" transform="translate(0 26)" fill="none" stroke="#8A2E12" stroke-opacity="0.4"
          stroke-width="140" stroke-linecap="round" stroke-linejoin="round" filter="url(#shadow)"/>
    <path d="{M_PATH}" fill="none" stroke="url(#mfill)" stroke-width="140" stroke-linecap="round" stroke-linejoin="round"/>
    <path transform="scale(8)" d="{shape}" fill="none" stroke="url(#rim)" stroke-width="1.6"/>
  </g>
</svg>
"""


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

    # The Start button / mOS logo: Amber, a solid white m, filled right to the edge of your shape
    for folder, (name, comment, shape) in THEMES.items():
        for size in SIZES:
            render(start_icon(shape), size, os.path.join(OUT, folder, f"{size}x{size}", "apps", "mos-logo.png"))
    for size in SIZES:
        render(start_icon(SQUIRCLE), size, os.path.join(OUT, "hicolor", f"{size}x{size}", "apps", "mos-logo.png"))
    open("artwork/icons/src/mos-logo.svg", "w").write(start_icon(SQUIRCLE))
    print("Start button: mos-logo in every shape (Amber)")
