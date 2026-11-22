#!/usr/bin/env python3
"""mOS setup wizard: runs once, the first time you log in after installing.
Welcome -> Language -> Wi-Fi -> mOS Account -> Look -> Taskbar -> Done.
Uses the same backend as mOS Settings.
SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mos_settings as m  # noqa: E402
from PySide6.QtCore import QObject, Property, Slot  # noqa: E402
from PySide6.QtGui import QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

DONE = os.path.join(m.MOS_CONFIG, "setup-done")


def live_session():
    try:
        return "boot=live" in open("/proc/cmdline").read()
    except OSError:
        return False


def block_shortcuts(on):
    """First run: switch off Alt+Tab, the Start key and every other global shortcut
    so the setup can't be skipped. Plasma turns them back on at the next sign-in anyway."""
    try:
        from PySide6.QtDBus import QDBusConnection, QDBusInterface
        iface = QDBusInterface("org.kde.kglobalaccel", "/kglobalaccel",
                               "org.kde.KGlobalAccel", QDBusConnection.sessionBus())
        if iface.isValid():
            iface.call("blockGlobalShortcuts", bool(on))
    except Exception:
        pass


class Wizard(QObject):
    def __init__(self, parent, locked):
        super().__init__(parent)
        self._locked = locked
        self._finished = False

    @Property(bool, constant=True)
    def locked(self):
        return self._locked

    @Property(bool, constant=True)
    def finished(self):
        return self._finished

    @Slot()
    def finish(self):
        os.makedirs(m.MOS_CONFIG, exist_ok=True)
        open(DONE, "w").write("1\n")
        self._finished = True
        if self._locked:
            block_shortcuts(False)
        QGuiApplication.quit()


def main():
    if "--first-run" in sys.argv and (os.path.exists(DONE) or live_session()):
        return 0
    QGuiApplication.setApplicationName("Welcome to mOS")
    QGuiApplication.setDesktopFileName("mos-welcome")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("mos-logo"))
    backend = m.Backend(app)
    locked = "--first-run" in sys.argv
    wizard = Wizard(app, locked)
    if locked:
        block_shortcuts(True)
        app.aboutToQuit.connect(lambda: block_shortcuts(False))
    engine = QQmlApplicationEngine()
    engine.addImageProvider("icon", m.IconProvider())
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("wizard", wizard)
    engine.rootContext().setContextProperty("startPage", "welcome")
    engine.load(os.path.join(HERE, "welcome", "Welcome.qml"))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
