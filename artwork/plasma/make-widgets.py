#!/usr/bin/env python3
"""mOS Plasma style: round, Material-looking buttons, text fields and list
highlights for everything Plasma draws (notifications, tray pop-ups, Start
menu, Spotlight). Colours come from the colour scheme, so light and dark
mode both work. Run from the repo root.
"""
import os

T = "build/config/includes.chroot/usr/share/plasma/desktoptheme/mOS/widgets"
os.makedirs(T, exist_ok=True)
STYLE = ('<defs><style type="text/css" id="current-color-scheme">'
         '.ColorScheme-Text{color:#232629;}.ColorScheme-Background{color:#eff0f1;}'
         '.ColorScheme-Highlight{color:#3daee9;}.ColorScheme-ButtonBackground{color:#fcfcfc;}'
         '.ColorScheme-ViewBackground{color:#ffffff;}</style></defs>')


def frame(prefix, C, M, ox, oy, fill="", stroke="", sw=1):
    """One FrameSvg frame (9 pieces) with round corners of radius C.
    Each piece is drawn on its own (QtSvg ignores clip paths)."""
    p = f"{prefix}-" if prefix else ""
    S = 2 * C + M
    X, Y = ox, oy
    h = sw / 2  # stroke sits inside the edge
    st = f'{stroke} stroke-width="{sw}" fill="none"' if stroke else ""
    out = []

    def piece(name, fill_d, stroke_d):
        g = f'<g id="{p}{name}"><path d="{fill_d}" {fill}/>'
        if stroke:
            g += f'<path d="{stroke_d}" {st}/>'
        out.append(g + "</g>")

    # corners: quarter discs + arc outline
    piece("topleft", f"M{X} {Y + C} A{C} {C} 0 0 1 {X + C} {Y} L{X + C} {Y + C} Z",
          f"M{X + h} {Y + C} A{C - h} {C - h} 0 0 1 {X + C} {Y + h}")
    piece("topright", f"M{X + C + M} {Y} A{C} {C} 0 0 1 {X + S} {Y + C} L{X + C + M} {Y + C} Z",
          f"M{X + C + M} {Y + h} A{C - h} {C - h} 0 0 1 {X + S - h} {Y + C}")
    piece("bottomright", f"M{X + S} {Y + C + M} A{C} {C} 0 0 1 {X + C + M} {Y + S} L{X + C + M} {Y + C + M} Z",
          f"M{X + S - h} {Y + C + M} A{C - h} {C - h} 0 0 1 {X + C + M} {Y + S - h}")
    piece("bottomleft", f"M{X + C} {Y + S} A{C} {C} 0 0 1 {X} {Y + C + M} L{X + C} {Y + C + M} Z",
          f"M{X + C} {Y + S - h} A{C - h} {C - h} 0 0 1 {X + h} {Y + C + M}")
    # edges and middle
    piece("top", f"M{X + C} {Y} h{M} v{C} h{-M} Z", f"M{X + C} {Y + h} h{M}")
    piece("bottom", f"M{X + C} {Y + C + M} h{M} v{C} h{-M} Z", f"M{X + C} {Y + S - h} h{M}")
    piece("left", f"M{X} {Y + C} h{C} v{M} h{-C} Z", f"M{X + h} {Y + C} v{M}")
    piece("right", f"M{X + C + M} {Y + C} h{C} v{M} h{-C} Z", f"M{X + S - h} {Y + C} v{M}")
    out.append(f'<g id="{p}center"><path d="M{X + C} {Y + C} h{M} v{M} h{-M} Z" {fill}/></g>')
    return "\n".join(out), S


def hints(prefix, ox, oy, left, top, right=None, bottom=None):
    p = f"{prefix}-" if prefix else ""
    right = left if right is None else right
    bottom = top if bottom is None else bottom
    return (f'<rect id="{p}hint-left-margin" x="{ox}" y="{oy}" width="{left}" height="2" fill="none"/>'
            f'<rect id="{p}hint-right-margin" x="{ox}" y="{oy + 4}" width="{right}" height="2" fill="none"/>'
            f'<rect id="{p}hint-top-margin" x="{ox}" y="{oy + 8}" width="2" height="{top}" fill="none"/>'
            f'<rect id="{p}hint-bottom-margin" x="{ox}" y="{oy + 30}" width="2" height="{bottom}" fill="none"/>')


def write(name, frames, extra=""):
    body, x = [], 0
    for prefix, C, M, fill, stroke, sw, h in frames:
        f, S = frame(prefix, C, M, x, 0, fill, stroke, sw)
        body.append(f)
        if h:
            body.append(hints(prefix, x, S + 4, *h))
        x += S + 10
    W = x + 10
    open(os.path.join(T, name), "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="140" viewBox="0 0 {W} 140">{STYLE}'
        + "\n".join(body) + extra + "</svg>\n")
    print("wrote", name)


HL = 'class="ColorScheme-Highlight" fill="currentColor"'
TXT_STROKE = 'class="ColorScheme-Text" stroke="currentColor" stroke-opacity="0.18"'

# List items: soft round highlight (Start menu, tray lists, notification history)
write("viewitem.svg", [
    ("normal", 12, 20, 'fill="none"', '', 0, (8, 4)),
    ("hover", 12, 20, f'{HL} fill-opacity="0.14"', '', 0, (8, 4)),
    ("selected", 12, 20, f'{HL} fill-opacity="0.24"', '', 0, (8, 4)),
    ("selected+hover", 12, 20, f'{HL} fill-opacity="0.32"', '', 0, (8, 4)),
])

# Buttons: Material tonal pills (filled, no outlines)
write("button.svg", [
    ("normal", 14, 20, 'class="ColorScheme-Highlight" fill="currentColor" fill-opacity="0.13"', '', 0, (14, 6)),
    ("hover", 14, 20, f'{HL} fill-opacity="0.22"', '', 0, (14, 6)),
    ("pressed", 14, 20, f'{HL} fill-opacity="0.36"', '', 0, (14, 6)),
    ("focus", 14, 20, f'{HL} fill-opacity="0.26"', '', 0, (14, 6)),
])

# Text fields: filled pills that tint when you hover or type
write("lineedit.svg", [
    ("base", 14, 20, 'class="ColorScheme-Text" fill="currentColor" fill-opacity="0.07"', '', 0, (14, 6)),
    ("hover", 14, 20, f'{HL} fill-opacity="0.08"', '', 0, (14, 6)),
    ("focus", 14, 20, f'{HL} fill-opacity="0.16"', '', 0, (14, 6)),
])
