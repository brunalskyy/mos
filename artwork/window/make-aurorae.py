#!/usr/bin/env python3
"""mOS window style (KWin Aurorae): Windows 10-style buttons on the right
(minimise, maximise, close; close goes red on hover), flat Material title bar.
Two themes: mOS (light) and mOS-Dark; mOS Settings switches with dark mode.
Run from the repo root: python3 artwork/window/make-aurorae.py
"""
import os, shutil

OUT = "build/config/includes.chroot/usr/share/aurorae/themes"
BW, BH = 46, 32  # Windows 10 caption button size

THEMES = {
    "mOS": dict(name="mOS", bar="#F7F3FA", bar_in="#FBF8FD", border="#D8D3DE", text="#1D1B20", text_in="#8C8791",
                glyph="#1D1B20", glyph_in="#9A95A0", hover="#E6E1EA", press="#D3CED8"),
    "mOS-Dark": dict(name="mOS Dark", bar="#211F26", bar_in="#1A1820", border="#36333D", text="#E6E0E9", text_in="#8E8994",
                     glyph="#E6E0E9", glyph_in="#7D7884", hover="#36333D", press="#46424D"),
}
CLOSE_HOVER, CLOSE_PRESS = "#E81123", "#F1707A"

GLYPHS = {
    "minimize": '<path d="M18 16.5h10" stroke="{c}" stroke-width="1" fill="none"/>',
    "maximize": '<rect x="18.5" y="11.5" width="9" height="9" stroke="{c}" stroke-width="1" fill="none"/>',
    "restore": '<rect x="18.5" y="13.5" width="7" height="7" stroke="{c}" stroke-width="1" fill="none"/>'
               '<path d="M20.5 13.5v-2h7v7h-2" stroke="{c}" stroke-width="1" fill="none"/>',
    "close": '<path d="M18 11l10 10M28 11L18 21" stroke="{c}" stroke-width="1" fill="none"/>',
}


def button(kind, t):
    states = [
        ("active", "none", t["glyph"]),
        ("hover", CLOSE_HOVER if kind == "close" else t["hover"], "#FFFFFF" if kind == "close" else t["glyph"]),
        ("pressed", CLOSE_PRESS if kind == "close" else t["press"], "#FFFFFF" if kind == "close" else t["glyph"]),
        ("inactive", "none", t["glyph_in"]),
        ("deactivated", "none", t["glyph_in"]),
    ]
    parts = []
    for i, (state, bg, fg) in enumerate(states):
        x = i * (BW + 2)
        parts.append(f'<g id="{state}-center" transform="translate({x} 0)">'
                     f'<rect x="0" y="0" width="{BW}" height="{BH}" fill="{bg}"/>'
                     + GLYPHS[kind].format(c=fg) + "</g>")
    w = len(states) * (BW + 2)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{BH}" viewBox="0 0 {w} {BH}">' + "".join(parts) + "</svg>\n"


def decoration(t):
    out, y = [], 0
    for prefix, bar in (("decoration", t["bar"]), ("decoration-inactive", t["bar_in"]),
                        ("decoration-maximized", t["bar"]), ("decoration-maximized-inactive", t["bar_in"])):
        b = 0 if "maximized" in prefix else 1   # 1px border round the window, none when maximised
        H = BH
        e = [
            (f"{prefix}-topleft", 0, 0, b or 1, H, bar), (f"{prefix}-top", 10, 0, 10, H, bar),
            (f"{prefix}-topright", 30, 0, b or 1, H, bar),
            (f"{prefix}-left", 0, H, b or 1, 10, t["border"]), (f"{prefix}-center", 10, H, 10, 10, bar),
            (f"{prefix}-right", 30, H, b or 1, 10, t["border"]),
            (f"{prefix}-bottomleft", 0, H + 10, b or 1, b or 1, t["border"]),
            (f"{prefix}-bottom", 10, H + 10, 10, b or 1, t["border"]),
            (f"{prefix}-bottomright", 30, H + 10, b or 1, b or 1, t["border"]),
        ]
        for name, x, yy, w, h, c in e:
            out.append(f'<rect id="{name}" x="{x}" y="{yy + y}" width="{w}" height="{h}" fill="{c}"/>')
        y += H + 20
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="40" height="{y}" viewBox="0 0 40 {y}">' + "".join(out) + "</svg>\n"


RC = """[General]
ActiveTextColor={text}
InactiveTextColor={text_in}
TitleAlignment=AlignLeft
TitleVerticalAlignment=AlignVCenter
Animation=120
DecorationPosition=0
ActiveHighlightedTextColor={text}
InactiveHighlightedTextColor={text_in}

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=12
TitleEdgeRight=0
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=12
TitleEdgeRightMaximized=0
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={h}
ButtonWidth={w}
ButtonHeight={h}
ButtonSpacing=0
ButtonMarginTop=0
ButtonMarginTopMaximized=0
ExplicitButtonSpacer=8
PaddingTop=0
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
"""

for folder, t in THEMES.items():
    d = os.path.join(OUT, folder)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for kind in GLYPHS:
        open(os.path.join(d, kind + ".svg"), "w").write(button(kind, t))
    open(os.path.join(d, "decoration.svg"), "w").write(decoration(t))
    open(os.path.join(d, folder + "rc"), "w").write(RC.format(h=BH, w=BW, **t))
    open(os.path.join(d, "metadata.desktop"), "w").write(
        f"[Desktop Entry]\nName={t['name']}\nComment=mOS window style, Windows 10-style buttons\n"
        f"X-KDE-PluginInfo-Author=Bruno Woznicki\nX-KDE-PluginInfo-Name={folder}\nX-KDE-PluginInfo-Version=0.6\n"
        "X-KDE-PluginInfo-License=GPL-2.0-or-later\nX-KDE-PluginInfo-EnabledByDefault=true\n")
    open(os.path.join(d, "metadata.json"), "w").write(
        '{\n    "KPlugin": {\n        "Authors": [{ "Name": "Bruno Woznicki" }],\n'
        f'        "Description": "mOS window style, Windows 10-style buttons",\n        "Id": "{folder}",\n'
        f'        "License": "GPL-2.0-or-later",\n        "Name": "{t["name"]}",\n        "Version": "0.6"\n    }}\n}}\n')
    print("wrote", d)
