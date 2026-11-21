#!/usr/bin/env python3
"""mOS Settings: the Material 3 settings app for mOS.

The everyday settings (wallpaper, colours, icon shape, dark mode, about) are
built in. Everything else opens the matching KDE settings page.
SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import configparser
import glob
import os
import platform
import shutil
import subprocess
import sys

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
KDEGLOBALS = os.path.expanduser("~/.config/kdeglobals")
SHAPES = {"circle": "mOS", "squircle": "mOS-Squircle", "rounded": "mOS-Rounded"}


def read_ini(path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    for p in ("/etc/xdg/kdeglobals", path):
        try:
            cp.read(p)
        except configparser.Error:
            pass
    return cp


def run(cmd):
    """Start a command without waiting; ignore it if the tool is missing."""
    if shutil.which(cmd[0]) or os.path.exists(cmd[0]):
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    return False


def find_tool(name):
    for p in [shutil.which(name)] + glob.glob(f"/usr/lib/*/libexec/{name}") + [f"/usr/libexec/{name}"]:
        if p and os.path.exists(p):
            return p
    return None


class Backend(QObject):
    changed = Signal()

    def _globals(self):
        return read_ini(KDEGLOBALS)

    # ---- colours ----
    @Property(str, notify=changed)
    def accent(self):
        g = self._globals()
        for key in ("LastUsedCustomAccentColor", "AccentColor"):
            v = g.get("General", key, fallback="")
            parts = [p.strip() for p in v.split(",")]
            if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
                r, gg, b = (int(x) for x in parts[:3])
                return f"#{r:02X}{gg:02X}{b:02X}"
        return "#E8833A"  # Amber

    @Property(bool, notify=changed)
    def accentFromWallpaper(self):
        return self._globals().get("General", "accentColorFromWallpaper", fallback="true").lower() == "true"

    @Slot(bool)
    def setAccentFromWallpaper(self, on):
        run(["kwriteconfig6", "--file", "kdeglobals", "--group", "General",
             "--key", "accentColorFromWallpaper", "true" if on else "false"])
        self.changed.emit()

    @Property(bool, notify=changed)
    def dark(self):
        return "dark" in self._globals().get("General", "ColorScheme", fallback="BreezeLight").lower()

    @Slot(bool)
    def setDark(self, on):
        run(["plasma-apply-colorscheme", "BreezeDark" if on else "BreezeLight"])
        self.changed.emit()

    # ---- icon shape ----
    @Property(str, notify=changed)
    def iconShape(self):
        theme = self._globals().get("Icons", "Theme", fallback="mOS")
        for shape, name in SHAPES.items():
            if name == theme:
                return shape
        return "circle"

    @Slot(str)
    def setIconShape(self, shape):
        theme = SHAPES.get(shape, "mOS")
        tool = find_tool("plasma-changeicons")
        if not (tool and run([tool, theme])):
            run(["kwriteconfig6", "--file", "kdeglobals", "--group", "Icons", "--key", "Theme", theme])
        self.changed.emit()

    # ---- wallpaper ----
    @Property("QVariantList", constant=True)
    def wallpapers(self):
        out = []
        for meta in sorted(glob.glob("/usr/share/wallpapers/mOS*/metadata.json")):
            folder = os.path.dirname(meta)
            images = sorted(glob.glob(os.path.join(folder, "contents/images/*.png"))
                            + glob.glob(os.path.join(folder, "contents/images/*.jpg")))
            if not images:
                continue
            shot = os.path.join(folder, "contents/screenshot.png")
            name = os.path.basename(folder).replace("mOS-", "").replace("mOS", "Amber")
            try:
                import json
                name = json.load(open(meta))["KPlugin"]["Name"].replace("mOS ", "")
            except Exception:
                pass
            out.append({"name": name, "image": images[-1],
                        "preview": QUrl.fromLocalFile(shot if os.path.exists(shot) else images[-1]).toString()})
        return out

    @Slot(str)
    def setWallpaper(self, path):
        run(["plasma-apply-wallpaperimage", path])

    # ---- open other settings ----
    @Slot(str)
    def openModule(self, module):
        if not run(["systemsettings", module]):
            run(["kcmshell6", module])

    @Slot(str)
    def launch(self, desktop_id):
        """Start an app from its .desktop file."""
        import shlex
        path = f"/usr/share/applications/{desktop_id}.desktop"
        try:
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            cp.optionxform = str
            cp.read(path)
            exec_line = cp.get("Desktop Entry", "Exec")
            args = [a for a in shlex.split(exec_line) if not (a.startswith("%") and len(a) == 2)]
            run(args)
        except (configparser.Error, ValueError):
            run([desktop_id])

    # ---- about ----
    @Property("QVariantMap", constant=True)
    def about(self):
        info = {"name": "mOS", "version": "", "cpu": platform.processor() or "", "memory": "", "model": ""}
        try:
            for line in open("/etc/os-release"):
                k, _, v = line.strip().partition("=")
                if k == "PRETTY_NAME":
                    info["version"] = v.strip('"')
        except OSError:
            pass
        try:
            for line in open("/proc/cpuinfo"):
                if line.startswith("model name"):
                    info["cpu"] = " ".join(line.split(":", 1)[1].split())
                    break
        except OSError:
            pass
        try:
            for line in open("/proc/meminfo"):
                if line.startswith("MemTotal"):
                    kb = int(line.split()[1])
                    info["memory"] = f"{round(kb / 1024 / 1024)} GB"
                    break
        except (OSError, ValueError):
            pass
        for p in ("/sys/class/dmi/id/product_name",):
            try:
                info["model"] = open(p).read().strip()
            except OSError:
                pass
        return info


def main():
    QGuiApplication.setApplicationName("mOS Settings")
    QGuiApplication.setDesktopFileName("mos-settings")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("systemsettings"))
    backend = Backend(app)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("startPage", sys.argv[1] if len(sys.argv) > 1 else "style")
    engine.load(os.path.join(HERE, "Main.qml"))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
