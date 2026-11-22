#!/usr/bin/env python3
"""mOS Apple Control Panel: fans, temperatures, keyboard and battery on Intel Macs
(made for the MacBook Air 2017, works on most Intel Macs without a T2 chip).
Reads live values from the Mac's SMC chip (applesmc), changes go through
mos-apple-helper with your password. Keyboard light goes through KDE's power service.
SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mos_settings as m  # noqa: E402
from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot  # noqa: E402
from PySide6.QtGui import QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

SMC = "/sys/devices/platform/applesmc.768"
HID = "/sys/module/hid_apple/parameters"
HELPER = "/usr/lib/mos-settings/mos-apple-helper"
CONF = "/etc/mos/apple.json"
KBD = ("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl",
       "org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl")

# SMC sensor keys → names people understand (the rest are hidden)
SENSORS = {"TC0P": "Processor", "TC0E": "Processor", "TC0F": "Processor", "TB0T": "Battery", "TB1T": "Battery",
           "TG0P": "Graphics", "TM0P": "Memory", "TH0P": "Storage", "TH0x": "Storage", "Ts0P": "Palm rest",
           "Ts0S": "Keyboard", "TW0P": "Wi-Fi", "Th1H": "Heat pipe", "TA0P": "Air inside"}


def read(path, default=""):
    try:
        return open(path).read().strip()
    except OSError:
        return default


def read_int(path, default=0):
    try:
        return int(read(path))
    except ValueError:
        return default


class Apple(QObject):
    changed = Signal()
    toast = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._fans, self._temps, self._battery = [], [], {}
        self._kbd, self._kbdMax = -1, 0
        self._busy = False
        self._finished.connect(self._on_finished)
        self.refresh()
        t = QTimer(self)
        t.timeout.connect(self.refresh)
        t.start(2000)

    # ------------------------------------------------------------ reading
    @Slot()
    def refresh(self):
        fans = []
        for p in sorted(glob.glob(os.path.join(SMC, "fan[0-9]_input"))):
            n = os.path.basename(p).split("_")[0]
            label = read(os.path.join(SMC, n + "_label"), "Fan") or "Fan"
            fans.append({"id": n, "name": label if label.lower() != "master" else "Fan",
                         "rpm": read_int(p), "min": read_int(os.path.join(SMC, n + "_min")),
                         "max": read_int(os.path.join(SMC, n + "_max"), 6500),
                         "manual": read_int(os.path.join(SMC, n + "_manual")) == 1})
        self._fans = fans

        temps, seen = [], set()
        for hw in glob.glob("/sys/class/hwmon/hwmon*"):
            if read(os.path.join(hw, "name")) == "coretemp":
                for lab in glob.glob(os.path.join(hw, "temp*_label")):
                    if read(lab).startswith("Package"):
                        temps.append({"name": "Processor", "value": read_int(lab.replace("_label", "_input")) / 1000})
                        seen.add("Processor")
        for lab in sorted(glob.glob(os.path.join(SMC, "temp*_label"))):
            name = SENSORS.get(read(lab))
            if not name or name in seen:
                continue
            v = read_int(lab.replace("_label", "_input")) / 1000
            if 0 < v < 120:
                temps.append({"name": name, "value": v})
                seen.add(name)
        self._temps = temps

        bat = {}
        for b in glob.glob("/sys/class/power_supply/BAT*"):
            full = read_int(os.path.join(b, "energy_full")) or read_int(os.path.join(b, "charge_full"))
            design = read_int(os.path.join(b, "energy_full_design")) or read_int(os.path.join(b, "charge_full_design"))
            health = round(100 * full / design) if design else 0
            bat = {"present": True, "percent": max(0, min(100, read_int(os.path.join(b, "capacity")))),
                   "status": read(os.path.join(b, "status")), "cycles": read_int(os.path.join(b, "cycle_count")),
                   "health": max(0, min(100, health)),
                   "condition": "Normal" if health >= 80 else ("Service recommended" if health else "Unknown")}
            break
        self._battery = bat

        ok, out = m.dbus_user("call", *KBD, "keyboardBrightness", timeout=3)
        mm = re.match(r"i (\d+)", out.strip()) if ok else None
        if mm:
            self._kbd = int(mm.group(1))
            ok, out = m.dbus_user("call", *KBD, "keyboardBrightnessMax", timeout=3)
            mm = re.match(r"i (\d+)", out.strip()) if ok else None
            self._kbdMax = int(mm.group(1)) if mm else 100
        else:
            led = glob.glob("/sys/class/leds/*kbd_backlight")
            self._kbd = read_int(os.path.join(led[0], "brightness"), -1) if led else -1
            self._kbdMax = read_int(os.path.join(led[0], "max_brightness"), 0) if led else 0
        self.changed.emit()

    @Property(bool, constant=True)
    def isMac(self):
        return "apple" in read("/sys/class/dmi/id/sys_vendor").lower()

    @Property(str, constant=True)
    def model(self):
        return read("/sys/class/dmi/id/product_name", "Mac")

    @Property(str, constant=True)
    def niceModel(self):
        p = read("/sys/class/dmi/id/product_name")
        names = {"MacBookAir7,2": "MacBook Air (13-inch, 2015–2017)", "MacBookAir7,1": "MacBook Air (11-inch, 2015)",
                 "MacBookAir6,2": "MacBook Air (13-inch, 2013–2014)", "MacBookAir6,1": "MacBook Air (11-inch, 2013–2014)",
                 "MacBookPro11,1": "MacBook Pro (13-inch, 2013–2014)", "MacBookPro12,1": "MacBook Pro (13-inch, 2015)",
                 "MacBookPro11,4": "MacBook Pro (15-inch, 2015)", "MacBookPro11,5": "MacBook Pro (15-inch, 2015)"}
        return names.get(p, p or "Mac")

    @Property(bool, constant=True)
    def hasSmc(self):
        return os.path.isdir(SMC)

    @Property("QVariantList", notify=changed)
    def fans(self):
        return self._fans

    @Property("QVariantList", notify=changed)
    def temps(self):
        return self._temps

    @Property("QVariantMap", notify=changed)
    def battery(self):
        return self._battery

    @Property(int, notify=changed)
    def keyboardLight(self):
        return self._kbd

    @Property(int, notify=changed)
    def keyboardLightMax(self):
        return self._kbdMax

    @Property("QVariantMap", notify=changed)
    def saved(self):
        try:
            return json.load(open(CONF))
        except (OSError, ValueError):
            return {}

    @Property(int, notify=changed)
    def fnMode(self):
        return read_int(os.path.join(HID, "fnmode"), 1)

    @Property(bool, notify=changed)
    def swapped(self):
        return read_int(os.path.join(HID, "swap_opt_cmd"), 0) == 1

    @Property(bool, notify=changed)
    def busy(self):
        return self._busy

    # ------------------------------------------------------------ changing
    _finished = Signal(str)

    def _helper(self, args, done):
        """Run mos-apple-helper through pkexec (password pop-up) without freezing the window."""
        import threading
        self._busy = True
        self.changed.emit()

        def go():
            ok, out = m.sh(["pkexec", HELPER, *args], timeout=120)
            self._finished.emit(done if ok else "Nothing was changed")
        threading.Thread(target=go, daemon=True).start()

    @Slot(str)
    def _on_finished(self, text):
        self._busy = False
        self.toast.emit(text)
        self.refresh()

    @Slot(str, int)
    def setFan(self, mode, rpm):
        names = {"auto": "Fans on automatic", "quiet": "Fans set to quiet", "cool": "Fans set to keep cool",
                 "manual": "Fan speed set to %d RPM" % rpm}
        self._helper(["fan", mode] + ([str(int(rpm))] if mode == "manual" else []), names.get(mode, "Done"))

    @Slot(int)
    def setFnMode(self, mode):
        self._helper(["fnmode", str(mode)], "Top row keys changed")

    @Slot(bool)
    def setSwapped(self, on):
        self._helper(["swap", "1" if on else "0"], "Cmd and Option swapped" if on else "Cmd and Option back to normal")

    @Slot(int)
    def setKeyboardLight(self, value):
        m.dbus_user("call", *KBD, "setKeyboardBrightnessSilent", "i", str(int(value)), timeout=3)
        self._kbd = int(value)
        self.changed.emit()


def main():
    QGuiApplication.setApplicationName("Apple Control Panel")
    QGuiApplication.setDesktopFileName("mos-apple")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("computer-laptop"))
    backend = m.Backend(app)
    apple = Apple(app)
    engine = QQmlApplicationEngine()
    engine.addImageProvider("icon", m.IconProvider())
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("apple", apple)
    engine.load(os.path.join(HERE, "apple", "Apple.qml"))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
