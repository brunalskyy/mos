#!/usr/bin/env python3
"""mOS Add widgets: a widget gallery like iOS and macOS, with only mOS widgets.
Pick a widget, pick a size, and it lands in a free spot on your desktop.
SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mos_settings as m  # noqa: E402
from PySide6.QtCore import QObject, Signal, Slot  # noqa: E402
from PySide6.QtGui import QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

# Finds the first free spot (top to bottom, then the next column) on the left of the
# main screen's desktop, so new widgets never land on top of old ones or the desktop icons.
ADD_JS = """
(function () {
    var type = __TYPE__, w = gridUnit * __W__, h = gridUnit * __H__;
    var ds = desktops(), d = ds[0];
    for (var i = 0; i < ds.length; i++) { if (ds[i].screen === 0) { d = ds[i]; } }
    if (!d) { print("no desktop"); return; }
    var sg = screenGeometry(d.screen);
    var taken = [], ws = d.widgets();
    for (var j = 0; j < ws.length; j++) { taken.push(ws[j].geometry); }
    var gap = gridUnit;
    function free(x, y) {
        for (var k = 0; k < taken.length; k++) {
            var a = taken[k];
            if (x < a.x + a.width + gap && x + w + gap > a.x && y < a.y + a.height + gap && y + h + gap > a.y) { return false; }
        }
        return true;
    }
    for (var x = gridUnit * 2; x + w < sg.width * 0.65; x += gridUnit) {
        for (var y = gridUnit * 7; y + h < sg.height - gridUnit * 5; y += gridUnit) {
            if (free(x, y)) { d.addWidget(type, x, y, w, h); print("ok"); return; }
        }
    }
    d.addWidget(type, gridUnit * 2, gridUnit * 7, w, h);
    print("ok");
})();
"""

ALLOWED = {"org.mos.glance", "org.mos.clock", "org.mos.battery", "org.mos.calendar", "org.mos.weather", "org.mos.notes"}


class Gallery(QObject):
    toast = Signal(str)

    @Slot(str, int, int, str)
    def add(self, kind, w, h, name):
        if kind not in ALLOWED or not (1 <= w <= 40 and 1 <= h <= 40):
            return
        js = ADD_JS.replace("__TYPE__", json.dumps(kind)).replace("__W__", str(int(w))).replace("__H__", str(int(h)))
        ok, out = m.plasma_script(js)
        self.toast.emit(f"{name} added to your desktop" if ok and "ok" in out else "Couldn't add it. Is the desktop running?")


def main():
    QGuiApplication.setApplicationName("Add widgets")
    QGuiApplication.setDesktopFileName("mos-widgets")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("view-grid"))
    backend = m.Backend(app)
    gallery = Gallery(app)
    engine = QQmlApplicationEngine()
    engine.addImageProvider("icon", m.IconProvider())
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("gallery", gallery)
    engine.load(os.path.join(HERE, "widgets", "Gallery.qml"))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
