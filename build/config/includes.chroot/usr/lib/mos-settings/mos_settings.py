#!/usr/bin/env python3
"""mOS Settings: the Material 3 settings app for mOS.

Every page is built in. Each setting talks to the real system tool underneath
(NetworkManager, BlueZ, KScreen, PipeWire/PulseAudio, UPower, KWin, Plasma,
systemd, Flatpak, apt), so nothing opens the old KDE settings window.

SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import configparser
import glob
import json
import os
import platform
import pwd
import re
import shlex
import shutil
import subprocess
import sys
import threading

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl, QSize, Qt
from PySide6.QtGui import QGuiApplication, QIcon, QPixmap
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mos_account  # noqa: E402
import mos_update  # noqa: E402

HOME = os.path.expanduser("~")
CONFIG = os.path.join(HOME, ".config")
MOS_CONFIG = os.path.join(CONFIG, "mos")
SHAPES = {"circle": "mOS", "squircle": "mOS-Squircle", "rounded": "mOS-Rounded"}


# ---------------------------------------------------------------- helpers
def have(tool):
    return shutil.which(tool) is not None


def sh(cmd, timeout=10, inp=None):
    """Run a command and return (ok, output). Never raises."""
    if isinstance(cmd, str):
        cmd = shlex.split(cmd)
    if not cmd or not (have(cmd[0]) or os.path.exists(cmd[0])):
        return False, ""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, input=inp)
        return p.returncode == 0, (p.stdout or "") + ("" if p.returncode == 0 else (p.stderr or ""))
    except (OSError, subprocess.TimeoutExpired) as e:
        return False, str(e)


def start(cmd):
    """Start a command and don't wait for it."""
    if isinstance(cmd, str):
        cmd = shlex.split(cmd)
    if cmd and (have(cmd[0]) or os.path.exists(cmd[0])):
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return True
    return False


def ini(name):
    """Read a KDE config file the way KDE does: /etc/xdg first, then ~/.config."""
    cp = configparser.ConfigParser(interpolation=None, strict=False, delimiters=("=",))
    cp.optionxform = str
    for p in (os.path.join("/etc/xdg", name), os.path.join(CONFIG, name)):
        try:
            cp.read(p, encoding="utf-8")
        except (configparser.Error, UnicodeDecodeError):
            pass
    return cp


def kread(name, group, key, default=""):
    cp = ini(name)
    groups = group if isinstance(group, (list, tuple)) else [group]
    section = "][".join(groups)
    try:
        return cp.get(section, key)
    except (configparser.Error, KeyError):
        return default


def kwrite(name, group, key, value):
    groups = group if isinstance(group, (list, tuple)) else [group]
    cmd = ["kwriteconfig6", "--notify", "--file", name]
    for g in groups:
        cmd += ["--group", g]
    cmd += ["--key", key]
    if isinstance(value, bool):
        cmd += ["--type", "bool", "true" if value else "false"]
    else:
        cmd += [str(value)]
    return sh(cmd)[0]


def dbus_user(*args, timeout=10):
    return sh(["busctl", "--user", *args], timeout=timeout)


def kwin_reconfigure():
    dbus_user("call", "org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure")


def plasma_script(js, timeout=15):
    ok, out = dbus_user("call", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell",
                        "evaluateScript", "s", js, timeout=timeout)
    m = re.match(r'^s\s+"(.*)"\s*$', out.strip(), re.S)
    text = m.group(1) if m else ""
    return ok, bytes(text, "utf-8").decode("unicode_escape", "ignore")


def split_nm(line):
    """Split an nmcli -t line on ':' but keep escaped '\\:'."""
    parts = re.split(r"(?<!\\):", line)
    return [p.replace("\\:", ":").replace("\\\\", "\\") for p in parts]


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def desktop_entry(path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    try:
        cp.read(path, encoding="utf-8")
        return dict(cp["Desktop Entry"])
    except (configparser.Error, KeyError, UnicodeDecodeError):
        return None


# ---------------------------------------------------------------- light / dark
def apply_dark(on):
    """Switch mOS light/dark: colours for every app and the window title bars."""
    scheme = "mOSDark" if on else "mOSLight"
    if not os.path.exists(f"/usr/share/color-schemes/{scheme}.colors"):
        scheme = "BreezeDark" if on else "BreezeLight"
    sh(["plasma-apply-colorscheme", scheme])
    kwrite("kwinrc", "org.kde.kdecoration2", "theme", "__aurorae__svg__mOS-Dark" if on else "__aurorae__svg__mOS")
    kwin_reconfigure()
    refresh_themed_icons()
    refresh_app_style()


def app_style_on():
    """Round Material buttons inside apps (the mOS Kvantum theme)."""
    return kread("kdeglobals", "KDE", "widgetStyle", "kvantum").lower() == "kvantum"


def refresh_app_style():
    """The app style follows your accent colour and light/dark: remake it after a change."""
    if app_style_on():
        start(["mos-kvantum"])


def themed_icons_on():
    return kread("kdeglobals", "Icons", "Theme", "mOS") == "mOS-Themed"


def refresh_themed_icons():
    """Themed icons follow the wallpaper colours and light/dark: remake them after a change."""
    if themed_icons_on():
        start(["mos-themed-icons"])


def is_dark():
    return "dark" in kread("kdeglobals", "General", "ColorScheme", "mOSLight").lower()


def sun_times(day=None):
    """Sunrise and sunset (local hours, e.g. 7.5) for your time zone's location."""
    import datetime
    import math
    lat, lon = 51.5, -0.13  # London if we can't tell
    try:
        tz = os.path.realpath("/etc/localtime").split("zoneinfo/", 1)[1]
        for line in open("/usr/share/zoneinfo/zone1970.tab"):
            if line.startswith("#"):
                continue
            cols = line.split("\t")
            if len(cols) > 2 and cols[2].strip() == tz:
                m = re.match(r"([+-]\d{2})(\d{2})(\d{2})?([+-]\d{3})(\d{2})(\d{2})?", cols[1])
                if m:
                    sgn = lambda v: -1 if v.startswith("-") else 1
                    lat = int(m.group(1)) + sgn(m.group(1)) * int(m.group(2)) / 60
                    lon = int(m.group(4)) + sgn(m.group(4)) * int(m.group(5)) / 60
                break
    except (OSError, IndexError):
        pass
    day = day or datetime.date.today()
    n = day.timetuple().tm_yday
    decl = 23.44 * math.sin(math.radians(360 / 365 * (n - 81)))
    b = math.radians(360 / 365 * (n - 81))
    eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b)  # minutes
    x = -math.tan(math.radians(lat)) * math.tan(math.radians(decl))
    x = max(-1.0, min(1.0, x))
    half = math.degrees(math.acos(x)) / 15  # hours
    offset = (datetime.datetime.now().astimezone().utcoffset().total_seconds()) / 3600
    noon = 12 - lon / 15 - eot / 60 + offset
    return noon - half, noon + half


def should_be_dark(prefs):
    import datetime
    mode = prefs.get("mode", "light")
    if mode in ("light", "dark"):
        return mode == "dark"
    now = datetime.datetime.now()
    h = now.hour + now.minute / 60
    if mode == "custom":
        def hours(t):
            try:
                hh, mm = t.split(":")
                return int(hh) + int(mm) / 60
            except ValueError:
                return 0
        dark_at, light_at = hours(prefs.get("darkAt", "19:00")), hours(prefs.get("lightAt", "07:00"))
    else:
        light_at, dark_at = sun_times()
    if dark_at > light_at:
        return h >= dark_at or h < light_at
    return dark_at <= h < light_at


APP_DIRS = [
    "/usr/share/applications",
    "/var/lib/flatpak/exports/share/applications",
    os.path.join(HOME, ".local/share/flatpak/exports/share/applications"),
    os.path.join(HOME, ".local/share/applications"),
]


def all_apps():
    seen, apps = set(), []
    for d in APP_DIRS:
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            did = os.path.basename(f)[:-8]
            if did in seen:
                continue
            e = desktop_entry(f)
            if not e or e.get("Type", "Application") != "Application":
                continue
            if e.get("NoDisplay", "false").lower() == "true" or e.get("Hidden", "false").lower() == "true":
                continue
            seen.add(did)
            apps.append({
                "id": did, "name": e.get("Name", did), "icon": e.get("Icon", "application-x-executable"),
                "flatpak": e.get("X-Flatpak", ""), "mime": e.get("MimeType", ""), "path": f,
            })
    apps.sort(key=lambda a: a["name"].lower())
    return apps


class IconProvider(QQuickImageProvider):
    """image://icon/<name> -> the app icon from the current icon theme."""

    def __init__(self):
        super().__init__(QQuickImageProvider.Pixmap)

    def requestPixmap(self, name, size, requested):
        w = requested.width() if requested.width() > 0 else 64
        icon = QIcon(name) if name.startswith("/") else QIcon.fromTheme(name, QIcon.fromTheme("application-x-executable"))
        pm = icon.pixmap(QSize(w, w))
        if pm.isNull():
            pm = QPixmap(w, w)
            pm.fill(Qt.transparent)
        if size is not None:
            size.setWidth(pm.width())
            size.setHeight(pm.height())
        return pm


# ---------------------------------------------------------------- backend
class Backend(QObject):
    changed = Signal()            # something changed: re-read properties
    jobDone = Signal(str, bool, str)   # key, ok, message
    toast = Signal(str)           # short message at the bottom of the window

    def __init__(self, parent=None):
        super().__init__(parent)
        self.account = mos_account.Account(self)
        self.updates = mos_update.Updates(self)

    @Property(QObject, constant=True)
    def accountApi(self):
        return self.account

    @Property(QObject, constant=True)
    def updateApi(self):
        return self.updates

    # run a command in the background, report back with jobDone(key, ok, text)
    def _job(self, key, fn):
        def run():
            try:
                ok, msg = fn()
            except Exception as e:  # keep the app alive whatever happens
                ok, msg = False, str(e)
            self.jobDone.emit(key, ok, msg)
            self.changed.emit()
        threading.Thread(target=run, daemon=True).start()

    # ------------------------------------------------------------ colours
    @Property(str, notify=changed)
    def accent(self):
        for key in ("LastUsedCustomAccentColor", "AccentColor"):
            v = kread("kdeglobals", "General", key)
            parts = [p.strip() for p in v.split(",")]
            if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
                r, g, b = (int(x) for x in parts[:3])
                return f"#{r:02X}{g:02X}{b:02X}"
        return "#E8833A"

    @Property(bool, notify=changed)
    def accentFromWallpaper(self):
        return kread("kdeglobals", "General", "accentColorFromWallpaper", "true").lower() == "true"

    @Slot(bool)
    def setAccentFromWallpaper(self, on):
        kwrite("kdeglobals", "General", "accentColorFromWallpaper", on)
        self.changed.emit()

    @Slot(str)
    def setAccent(self, hexcolour):
        c = hexcolour.lstrip("#")
        rgb = ",".join(str(int(c[i:i + 2], 16)) for i in (0, 2, 4))
        kwrite("kdeglobals", "General", "accentColorFromWallpaper", False)
        kwrite("kdeglobals", "General", "AccentColor", rgb)
        kwrite("kdeglobals", "General", "LastUsedCustomAccentColor", rgb)
        start(["plasma-apply-colorscheme", "--accent-color", "#" + c])
        refresh_themed_icons()
        refresh_app_style()
        self.changed.emit()

    @Property(bool, notify=changed)
    def dark(self):
        return is_dark()

    @Slot(bool)
    def setDark(self, on):
        apply_dark(on)
        self.changed.emit()

    @Property("QVariantMap", notify=changed)
    def themeMode(self):
        d = {"mode": "light", "darkAt": "19:00", "lightAt": "07:00"}
        d.update(load_json(os.path.join(MOS_CONFIG, "theme.json"), {}))
        if d["mode"] == "auto":
            rise, sset = sun_times()
            d["sunrise"] = f"{int(rise):02d}:{int(rise % 1 * 60):02d}"
            d["sunset"] = f"{int(sset):02d}:{int(sset % 1 * 60):02d}"
        return d

    @Slot("QVariantMap")
    def setThemeMode(self, opts):
        d = self.themeMode
        d.update({k: opts[k] for k in ("mode", "darkAt", "lightAt") if k in opts})
        save_json(os.path.join(MOS_CONFIG, "theme.json"), {k: d[k] for k in ("mode", "darkAt", "lightAt")})
        want = should_be_dark(d)
        if want != is_dark():
            apply_dark(want)
        self.changed.emit()

    # ------------------------------------------------------------ icon shape
    @Property(str, notify=changed)
    def iconShape(self):
        theme = kread("kdeglobals", "Icons", "Theme", "mOS")
        if theme == "mOS-Themed":
            theme = kread("kdeglobals", "Icons", "mosShape", "mOS")
        for shape, name in SHAPES.items():
            if name == theme:
                return shape
        return "circle"

    @Slot(str)
    def setIconShape(self, shape):
        theme = SHAPES.get(shape, "mOS")
        kwrite("kdeglobals", "Icons", "mosShape", theme)
        if themed_icons_on():
            self._job("icons", lambda: (sh(["mos-themed-icons"], timeout=600)[0], "Icon shape changed"))
        else:
            tool = next(iter(glob.glob("/usr/lib/*/libexec/plasma-changeicons")), None)
            if not (tool and sh([tool, theme])[0]):
                kwrite("kdeglobals", "Icons", "Theme", theme)
            self.toast.emit("Icon shape changed")
        self.changed.emit()

    @Property(bool, notify=changed)
    def themedIcons(self):
        return themed_icons_on()

    @Slot(bool)
    def setThemedIcons(self, on):
        self.toast.emit("Making your themed icons…" if on else "Back to normal icons")
        self._job("icons", lambda: (sh(["mos-themed-icons"] + ([] if on else ["--off"]), timeout=600)[0],
                                    "Themed icons are on" if on else "Themed icons are off"))

    # ------------------------------------------------------------ wallpaper
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
            name = load_json(meta, {}).get("KPlugin", {}).get("Name", "mOS").replace("mOS ", "")
            if name == "mOS":
                name = "Amber"
            out.append({"name": name, "image": images[-1],
                        "preview": QUrl.fromLocalFile(shot if os.path.exists(shot) else images[-1]).toString()})
        return out

    @Property(str, notify=changed)
    def wallpaper(self):
        return load_json(os.path.join(MOS_CONFIG, "style.json"), {}).get("wallpaper", "")

    @Slot(str)
    def setWallpaper(self, path):
        sh(["plasma-apply-wallpaperimage", path])
        data = load_json(os.path.join(MOS_CONFIG, "style.json"), {})
        data["wallpaper"] = path
        save_json(os.path.join(MOS_CONFIG, "style.json"), data)
        # the lock screen follows the desktop, unless you picked its own picture
        if not data.get("lockWallpaper"):
            kwrite("kscreenlockerrc", ["Greeter", "Wallpaper", "org.kde.image", "General"], "Image", "file://" + path)
        if themed_icons_on():
            # wait a moment for mOS to pick the new colours from the wallpaper
            self._job("icons", lambda: (__import__("time").sleep(4) or sh(["mos-themed-icons"], timeout=600)[0], "ok"))
        self.changed.emit()

    # ------------------------------------------------------------ Lock screen picture
    @Property(str, notify=changed)
    def lockWallpaper(self):
        """The lock screen's own picture, or "" when it's the same as the desktop."""
        return load_json(os.path.join(MOS_CONFIG, "style.json"), {}).get("lockWallpaper", "")

    @Property(bool, notify=changed)
    def loginFollowsLock(self):
        return load_json(os.path.join(MOS_CONFIG, "style.json"), {}).get("loginFollowsLock", True)

    @Slot(str)
    def setLockWallpaper(self, path):
        if path.startswith("file://"):
            path = QUrl(path).toLocalFile()
        data = load_json(os.path.join(MOS_CONFIG, "style.json"), {})
        data["lockWallpaper"] = path
        save_json(os.path.join(MOS_CONFIG, "style.json"), data)
        shown = path or data.get("wallpaper") or "/usr/share/wallpapers/mOS/contents/images/2880x1800.png"
        kwrite("kscreenlockerrc", ["Greeter", "Wallpaper", "org.kde.image", "General"], "Image", "file://" + shown)
        dbus_user("call", "org.freedesktop.ScreenSaver", "/ScreenSaver", "org.kde.screensaver", "configure")
        if data.get("loginFollowsLock", True):
            self._set_login_wallpaper(shown)
        self.changed.emit()

    @Slot(bool)
    def setLoginFollowsLock(self, on):
        data = load_json(os.path.join(MOS_CONFIG, "style.json"), {})
        data["loginFollowsLock"] = bool(on)
        save_json(os.path.join(MOS_CONFIG, "style.json"), data)
        if on:
            self._set_login_wallpaper(data.get("lockWallpaper") or data.get("wallpaper")
                                      or "/usr/share/wallpapers/mOS/contents/images/2880x1800.png")
        self.changed.emit()

    def _set_login_wallpaper(self, path):
        # the sign-in screen belongs to the whole computer, so this asks for your password
        def go():
            ok = sh(["pkexec", "/usr/lib/mos-settings/mos-login-wallpaper", path], timeout=180)[0]
            return ok, "Sign-in screen picture changed" if ok else "The sign-in screen picture wasn't changed"
        self._job("login-wallpaper", go)

    # ------------------------------------------------------------ Wi-Fi
    @Slot(result="QVariantMap")
    def wifi(self):
        res = {"available": have("nmcli"), "enabled": False, "networks": [], "connected": "", "wired": ""}
        if not res["available"]:
            return res
        ok, out = sh(["nmcli", "-t", "-f", "WIFI", "general"])
        res["enabled"] = out.strip() == "enabled"
        ok, out = sh(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"])
        for line in out.splitlines():
            p = split_nm(line)
            if len(p) >= 4 and p[1] == "ethernet" and p[2] == "connected":
                res["wired"] = p[3]
        ok, out = sh(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
        saved = {split_nm(l)[0] for l in out.splitlines() if l.endswith(":802-11-wireless")}
        if res["enabled"]:
            ok, out = sh(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"], timeout=15)
            best = {}
            for line in out.splitlines():
                p = split_nm(line)
                if len(p) < 4 or not p[1]:
                    continue
                n = {"ssid": p[1], "signal": int(p[2] or 0), "secure": p[3] not in ("", "--"),
                     "active": p[0] == "*", "saved": p[1] in saved}
                if n["active"]:
                    res["connected"] = p[1]
                if p[1] not in best or n["signal"] > best[p[1]]["signal"] or n["active"]:
                    best[p[1]] = n
            res["networks"] = sorted(best.values(), key=lambda n: (not n["active"], not n["saved"], -n["signal"]))
        return res

    @Slot(bool)
    def setWifiEnabled(self, on):
        self._job("wifi", lambda: sh(["nmcli", "radio", "wifi", "on" if on else "off"]))

    @Slot()
    def wifiRescan(self):
        self._job("wifi", lambda: sh(["nmcli", "device", "wifi", "rescan"], timeout=20))

    @Slot(str, str)
    def wifiConnect(self, ssid, password):
        def saved():
            ok, out = sh(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
            return [split_nm(l)[0] for l in out.splitlines() if split_nm(l)[0] == ssid]

        def fresh(key_mgmt=None):
            # Never stack "Name 1", "Name 2" copies: start from a clean profile.
            for _ in saved():
                sh(["nmcli", "connection", "delete", "id", ssid])
            cmd = ["nmcli", "device", "wifi", "connect", ssid]
            if password:
                cmd += ["password", password]
            ok, out = sh(cmd, timeout=45)
            if not ok and key_mgmt and saved():
                # Mixed WPA2/WPA3 routers: the Broadcom wl driver can't do WPA3, so force WPA2.
                sh(["nmcli", "connection", "modify", "id", ssid,
                    "802-11-wireless-security.key-mgmt", key_mgmt,
                    "802-11-wireless-security.pmf", "1"])
                ok, out = sh(["nmcli", "connection", "up", "id", ssid], timeout=45)
            return ok, out

        def go():
            if saved() and not password:
                ok, out = sh(["nmcli", "connection", "up", "id", ssid], timeout=45)
            else:
                ok, out = fresh("wpa-psk" if password else None)
            if ok:
                return True, f"Connected to {ssid}"
            if "Secrets were required" in out or "password" in out.lower():
                return False, "Wrong password"
            return False, f"Couldn't connect to {ssid}"
        self._job("wifi-connect", go)

    @Slot(str)
    def wifiDisconnect(self, ssid):
        self._job("wifi", lambda: sh(["nmcli", "connection", "down", "id", ssid]))

    @Slot(str)
    def wifiForget(self, ssid):
        self._job("wifi", lambda: sh(["nmcli", "connection", "delete", "id", ssid]))

    # ------------------------------------------------------------ Bluetooth
    @Slot(result="QVariantMap")
    def bluetooth(self):
        res = {"available": False, "enabled": False, "devices": []}
        if not have("bluetoothctl"):
            return res
        ok, out = sh(["bluetoothctl", "show"], timeout=5)
        if not ok or "Controller" not in out:
            return res
        res["available"] = True
        res["enabled"] = "Powered: yes" in out

        def macs(*filters):
            ok, o = sh(["bluetoothctl", "devices", *filters], timeout=5)
            r = {}
            for line in o.splitlines():
                m = re.match(r"Device ([0-9A-F:]{17}) (.*)", line.strip())
                if m:
                    r[m.group(1)] = m.group(2)
            return r
        everything, paired, connected = macs(), macs("Paired"), macs("Connected")
        for mac, name in everything.items():
            if re.fullmatch(r"([0-9A-F]{2}-){5}[0-9A-F]{2}", name):
                continue  # nameless devices
            res["devices"].append({"mac": mac, "name": name, "paired": mac in paired, "connected": mac in connected})
        res["devices"].sort(key=lambda d: (not d["connected"], not d["paired"], d["name"].lower()))
        return res

    @Slot(bool)
    def setBluetoothEnabled(self, on):
        self._job("bt", lambda: sh(["bluetoothctl", "power", "on" if on else "off"]))

    @Slot()
    def bluetoothScan(self):
        self._job("bt-scan", lambda: (sh(["bluetoothctl", "--timeout", "10", "scan", "on"], timeout=15)[0], "Done"))

    @Slot(str)
    def bluetoothPair(self, mac):
        def go():
            sh(["bluetoothctl", "--timeout", "20", "pair", mac], timeout=25)
            sh(["bluetoothctl", "trust", mac])
            ok, out = sh(["bluetoothctl", "--timeout", "15", "connect", mac], timeout=20)
            return ok, "Connected" if ok else "Couldn't connect. Is it in pairing mode?"
        self._job("bt", go)

    @Slot(str)
    def bluetoothConnect(self, mac):
        self._job("bt", lambda: sh(["bluetoothctl", "--timeout", "15", "connect", mac], timeout=20))

    @Slot(str)
    def bluetoothDisconnect(self, mac):
        self._job("bt", lambda: sh(["bluetoothctl", "disconnect", mac]))

    @Slot(str)
    def bluetoothRemove(self, mac):
        self._job("bt", lambda: sh(["bluetoothctl", "remove", mac]))

    # ------------------------------------------------------------ Display
    @Slot(result="QVariantMap")
    def display(self):
        res = {"outputs": [], "brightness": -1, "nightLight": False, "nightLightTemp": 4500}
        ok, out = sh(["kscreen-doctor", "-j"], timeout=8)
        try:
            data = json.loads(out[out.index("{"):]) if ok else {}
        except ValueError:
            data = {}
        for o in data.get("outputs", []):
            if not o.get("enabled") or not o.get("connected", True):
                continue
            modes, seen = [], set()
            for m in o.get("modes", []):
                w, h = m["size"]["width"], m["size"]["height"]
                if (w, h) in seen:
                    continue
                seen.add((w, h))
                modes.append({"id": str(m["id"]), "label": f"{w} × {h}", "w": w, "h": h})
            modes.sort(key=lambda m: -m["w"] * m["h"])
            cur = next((m for m in o.get("modes", []) if str(m["id"]) == str(o.get("currentModeId"))), None)
            res["outputs"].append({
                "name": o.get("name", ""), "scale": o.get("scale", 1), "modes": modes,
                "current": f'{cur["size"]["width"]} × {cur["size"]["height"]}' if cur else "",
            })
        ok, out = sh(["brightnessctl", "-m", "-c", "backlight"], timeout=3)
        if ok and out.strip():
            try:
                res["brightness"] = int(out.strip().split(",")[3].rstrip("%"))
            except (IndexError, ValueError):
                pass
        res["nightLight"] = kread("kwinrc", "NightColor", "Active", "false").lower() == "true"
        res["nightMode"] = "times" if kread("kwinrc", "NightColor", "Mode", "Automatic") == "Times" else "sun"
        def hhmm(v, d):
            v = (v or d).zfill(4)
            return f"{v[:2]}:{v[2:]}"
        res["nightEvening"] = hhmm(kread("kwinrc", "NightColor", "EveningBeginFixed", ""), "2000")
        res["nightMorning"] = hhmm(kread("kwinrc", "NightColor", "MorningBeginFixed", ""), "0600")
        try:
            res["nightLightTemp"] = int(kread("kwinrc", "NightColor", "NightTemperature", "4500"))
        except ValueError:
            pass
        return res

    @Slot(int)
    def setBrightness(self, percent):
        start(["brightnessctl", "-q", "-c", "backlight", "set", f"{max(1, min(100, percent))}%"])

    @Slot(str, str)
    def setResolution(self, output, mode_id):
        self._job("display", lambda: sh(["kscreen-doctor", f"output.{output}.mode.{mode_id}"]))

    @Slot(str, float)
    def setScale(self, output, scale):
        self._job("display", lambda: sh(["kscreen-doctor", f"output.{output}.scale.{scale:g}"]))

    @Slot(bool)
    def setNightLight(self, on):
        kwrite("kwinrc", "NightColor", "Active", on)
        if not kread("kwinrc", "NightColor", "Mode", ""):
            kwrite("kwinrc", "NightColor", "Mode", "Automatic")
        kwin_reconfigure()
        self.changed.emit()

    @Slot(str, str, str)
    def setNightSchedule(self, mode, evening, morning):
        """mode: 'sun' (sunset to sunrise) or 'times' (evening/morning as HH:MM)."""
        if mode == "times":
            kwrite("kwinrc", "NightColor", "Mode", "Times")
            kwrite("kwinrc", "NightColor", "EveningBeginFixed", evening.replace(":", ""))
            kwrite("kwinrc", "NightColor", "MorningBeginFixed", morning.replace(":", ""))
        else:
            kwrite("kwinrc", "NightColor", "Mode", "Automatic")
        kwin_reconfigure()
        self.changed.emit()

    @Slot(int)
    def setNightLightTemp(self, kelvin):
        kwrite("kwinrc", "NightColor", "NightTemperature", int(kelvin))
        kwin_reconfigure()

    # ------------------------------------------------------------ Sound
    def _pactl_list(self, kind):
        ok, out = sh(["pactl", "-f", "json", "list", kind], timeout=5)
        try:
            return json.loads(out) if ok else []
        except ValueError:
            return []

    @Slot(result="QVariantMap")
    def sound(self):
        res = {"available": have("pactl"), "outputs": [], "inputs": [], "volume": 0, "muted": False,
               "micVolume": 0, "micMuted": False}
        if not res["available"]:
            return res
        dsink = sh(["pactl", "get-default-sink"])[1].strip()
        dsrc = sh(["pactl", "get-default-source"])[1].strip()

        def vol(d):
            try:
                ch = list(d.get("volume", {}).values())
                return int(round(sum(int(c["value_percent"].rstrip("%")) for c in ch) / max(1, len(ch))))
            except (ValueError, KeyError, TypeError):
                return 0
        for s in self._pactl_list("sinks"):
            item = {"name": s.get("name"), "label": s.get("description", s.get("name")), "default": s.get("name") == dsink}
            res["outputs"].append(item)
            if item["default"]:
                res["volume"], res["muted"] = vol(s), bool(s.get("mute"))
        for s in self._pactl_list("sources"):
            if ".monitor" in (s.get("name") or ""):
                continue
            item = {"name": s.get("name"), "label": s.get("description", s.get("name")), "default": s.get("name") == dsrc}
            res["inputs"].append(item)
            if item["default"]:
                res["micVolume"], res["micMuted"] = vol(s), bool(s.get("mute"))
        return res

    @Slot(int)
    def setVolume(self, v):
        start(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{max(0, min(150, v))}%"])

    @Slot(bool)
    def setMuted(self, m):
        start(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "1" if m else "0"])

    @Slot(int)
    def setMicVolume(self, v):
        start(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", f"{max(0, min(150, v))}%"])

    @Slot(bool)
    def setMicMuted(self, m):
        start(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "1" if m else "0"])

    @Slot(str)
    def setOutput(self, name):
        sh(["pactl", "set-default-sink", name])
        self.changed.emit()

    @Slot(str)
    def setInput(self, name):
        sh(["pactl", "set-default-source", name])
        self.changed.emit()

    # ------------------------------------------------------------ Battery & power
    @Slot(result="QVariantMap")
    def power(self):
        res = {"hasBattery": False, "percent": 0, "state": "", "timeLeft": "", "profile": "", "profiles": [],
               "screenOff": 10, "sleep": 15, "health": ""}
        ok, out = sh(["upower", "-e"], timeout=4)
        bat = next((l for l in out.splitlines() if "battery_BAT" in l or "/battery_" in l), None)
        if bat:
            ok, info = sh(["upower", "-i", bat], timeout=4)
            res["hasBattery"] = "present:               yes" in info or "present: yes" in re.sub(r"\s+", " ", info)
            for line in info.splitlines():
                k, _, v = line.strip().partition(":")
                v = v.strip()
                if k == "percentage":
                    res["percent"] = max(0, min(100, int(float(v.rstrip("%").replace(",", ".") or 0))))
                elif k == "state":
                    res["state"] = {"charging": "Charging", "discharging": "On battery",
                                    "fully-charged": "Fully charged"}.get(v, v.capitalize())
                elif k in ("time to empty", "time to full"):
                    res["timeLeft"] = v
                elif k == "capacity":
                    res["health"] = v
        ok, out = sh(["powerprofilesctl", "list"], timeout=4)
        for line in out.splitlines():
            m = re.match(r"\s*(\*?)\s*([a-z-]+):\s*$", line)
            if m:
                res["profiles"].append(m.group(2))
                if m.group(1):
                    res["profile"] = m.group(2)
        group = "Battery" if res["hasBattery"] and res["state"] == "On battery" else "AC"
        try:
            res["screenOff"] = int(kread("powerdevilrc", [group, "Display"], "TurnOffDisplayIdleTimeoutSec", "600")) // 60
            res["sleep"] = int(kread("powerdevilrc", [group, "SuspendAndShutdown"], "AutoSuspendIdleTimeoutSec", "900")) // 60
        except ValueError:
            pass
        return res

    @Slot(str)
    def setPowerProfile(self, p):
        self._job("power", lambda: sh(["powerprofilesctl", "set", p]))

    @Slot(int, int)
    def setPowerTimeouts(self, screen_off_min, sleep_min):
        for group in ("AC", "Battery", "LowBattery"):
            if screen_off_min > 0:
                kwrite("powerdevilrc", [group, "Display"], "TurnOffDisplayWhenIdle", True)
                kwrite("powerdevilrc", [group, "Display"], "TurnOffDisplayIdleTimeoutSec", screen_off_min * 60)
            else:
                kwrite("powerdevilrc", [group, "Display"], "TurnOffDisplayWhenIdle", False)
            if sleep_min > 0:
                kwrite("powerdevilrc", [group, "SuspendAndShutdown"], "AutoSuspendAction", 1)
                kwrite("powerdevilrc", [group, "SuspendAndShutdown"], "AutoSuspendIdleTimeoutSec", sleep_min * 60)
            else:
                kwrite("powerdevilrc", [group, "SuspendAndShutdown"], "AutoSuspendAction", 0)
        dbus_user("call", "org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement",
                  "org.kde.Solid.PowerManagement", "refreshStatus")
        self.changed.emit()

    # ------------------------------------------------------------ Lock screen
    @Slot(result="QVariantMap")
    def lockScreen(self):
        def b(key, d):
            return kread("kscreenlockerrc", "Daemon", key, d).lower() == "true"
        try:
            timeout = int(kread("kscreenlockerrc", "Daemon", "Timeout", "5"))
        except ValueError:
            timeout = 5
        return {"autolock": b("Autolock", "true"), "timeout": timeout, "lockOnResume": b("LockOnResume", "true"),
                "showClock": kread("kscreenlockerrc", ["Greeter", "LnF", "General"], "alwaysShowClock", "true").lower() == "true",
                "mediaControls": kread("kscreenlockerrc", ["Greeter", "LnF", "General"], "showMediaControls", "true").lower() == "true"}

    @Slot(str, "QVariant")
    def setLock(self, key, value):
        if key in ("Autolock", "Timeout", "LockOnResume"):
            kwrite("kscreenlockerrc", "Daemon", key, value)
        else:
            kwrite("kscreenlockerrc", ["Greeter", "LnF", "General"], key, value)
        dbus_user("call", "org.freedesktop.ScreenSaver", "/ScreenSaver", "org.kde.screensaver", "configure")
        self.changed.emit()

    @Slot()
    def lockNow(self):
        start(["loginctl", "lock-session"])

    # ------------------------------------------------------------ Taskbar
    TASKBAR_DEFAULTS = {"style": "windows", "floating": True, "position": "bottom", "size": "medium",
                        "autohide": False, "spacing": 2, "labels": True}

    @Property("QVariantMap", notify=changed)
    def taskbar(self):
        d = dict(self.TASKBAR_DEFAULTS)
        d.update(load_json(os.path.join(MOS_CONFIG, "taskbar.json"), {}))
        return d

    @Slot("QVariantMap")
    def setTaskbar(self, opts):
        d = self.taskbar
        d.update({k: opts[k] for k in opts if k in self.TASKBAR_DEFAULTS})
        save_json(os.path.join(MOS_CONFIG, "taskbar.json"), d)
        js = open(os.path.join(HERE, "taskbar.js")).read().replace("__OPTIONS__", json.dumps(d))
        self._job("taskbar", lambda: (plasma_script(js)[0], "Taskbar updated"))
        self.changed.emit()

    # ------------------------------------------------------------ Notifications
    @Slot(result="QVariantMap")
    def notifications(self):
        until = kread("plasmanotifyrc", "DoNotDisturb", "Until", "")
        return {"dnd": bool(until) and until > "2026",
                "badges": kread("plasmanotifyrc", "Badges", "InTaskManager", "true").lower() == "true",
                "popups": kread("plasmanotifyrc", "Notifications", "PopupPosition", "BottomRight"),
                "lowPriority": kread("plasmanotifyrc", "Notifications", "LowPriorityPopups", "true").lower() == "true"}

    @Slot(bool)
    def setDnd(self, on):
        kwrite("plasmanotifyrc", "DoNotDisturb", "Until", "2100,1,1,0,0,0" if on else "")
        if not on:
            sh(["kwriteconfig6", "--file", "plasmanotifyrc", "--group", "DoNotDisturb", "--key", "Until", "--delete"])
        self.changed.emit()
        self.toast.emit("Do not disturb is on" if on else "Do not disturb is off")

    @Slot(str, bool)
    def setNotifyOption(self, key, on):
        group = "Badges" if key == "InTaskManager" else "Notifications"
        kwrite("plasmanotifyrc", group, key, on)
        self.changed.emit()

    # ------------------------------------------------------------ Privacy (store apps)
    @Slot(result="QVariantList")
    def privacyApps(self):
        out = []
        if not have("flatpak"):
            return out
        for a in all_apps():
            if not a["flatpak"]:
                continue
            ok, perms = sh(["flatpak", "info", "--show-permissions", a["flatpak"]], timeout=5)
            ok2, over = sh(["flatpak", "override", "--user", "--show", a["flatpak"]], timeout=5)
            text = perms + "\n" + over

            def has(pattern, negative):
                if re.search(negative, over):
                    return False
                return bool(re.search(pattern, text))
            out.append({"id": a["flatpak"], "name": a["name"], "icon": a["icon"],
                        "camera": has(r"devices=.*\ball\b", r"devices=.*!all"),
                        "microphone": has(r"sockets=.*\bpulseaudio\b", r"sockets=.*!pulseaudio"),
                        "files": has(r"filesystems=.*\b(home|host)\b", r"filesystems=.*!(home|host)")})
        return out

    @Slot(str, str, bool)
    def setAppPermission(self, app_id, what, allow):
        flag = {"camera": ("--device=all", "--nodevice=all"),
                "microphone": ("--socket=pulseaudio", "--nosocket=pulseaudio"),
                "files": ("--filesystem=home", "--nofilesystem=home")}[what][0 if allow else 1]
        self._job("privacy", lambda: sh(["flatpak", "override", "--user", flag, app_id]))

    # ------------------------------------------------------------ About
    @Property("QVariantMap", notify=changed)
    def about(self):
        info = {"name": "mOS", "version": "", "cpu": platform.processor() or "", "memory": "", "model": "",
                "hostname": platform.node(), "gpu": "", "storage": "", "kernel": platform.release(), "plasma": ""}
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
                    info["memory"] = f"{round(int(line.split()[1]) / 1024 / 1024)} GB"
                    break
        except (OSError, ValueError):
            pass
        try:
            vendor = open("/sys/class/dmi/id/sys_vendor").read().strip()
            prod = open("/sys/class/dmi/id/product_name").read().strip()
            info["model"] = prod if prod.lower().startswith(vendor.lower()) else f"{vendor} {prod}".strip()
        except OSError:
            pass
        ok, out = sh(["lspci"], timeout=3)
        gpus = [l.split(": ", 1)[1] for l in out.splitlines() if re.search(r"VGA|3D controller|Display controller", l)]
        info["gpu"] = "; ".join(re.sub(r"\s*\(rev [0-9a-f]+\)", "", g) for g in gpus)
        try:
            du = shutil.disk_usage("/")
            info["storage"] = f"{du.free / 1e9:.0f} GB free of {du.total / 1e9:.0f} GB"
        except OSError:
            pass
        ok, out = sh(["plasmashell", "--version"], timeout=3)
        info["plasma"] = out.replace("plasmashell", "").strip()
        return info

    @Slot(str)
    def setHostname(self, name):
        name = re.sub(r"[^A-Za-z0-9-]", "-", name.strip())[:63].strip("-") or "mos"
        self._job("hostname", lambda: sh(["hostnamectl", "set-hostname", name], timeout=60))

    # ------------------------------------------------------------ Storage
    @Slot()
    def scanStorage(self):
        def go():
            du = shutil.disk_usage("/")
            parts = []
            for label, path in (("Documents", "Documents"), ("Downloads", "Downloads"), ("Pictures", "Pictures"),
                                ("Music", "Music"), ("Videos", "Videos"), ("Desktop", "Desktop")):
                p = os.path.join(HOME, path)
                if os.path.isdir(p):
                    ok, out = sh(["du", "-sb", p], timeout=60)
                    if ok:
                        parts.append({"label": label, "bytes": int(out.split()[0])})
            apps = 0
            for p in ("/var/lib/flatpak", os.path.join(HOME, ".local/share/flatpak")):
                if os.path.isdir(p):
                    ok, out = sh(["du", "-sb", p], timeout=120)
                    if ok:
                        apps += int(out.split()[0])
            parts.append({"label": "Store apps", "bytes": apps})
            used_known = sum(p["bytes"] for p in parts)
            parts.append({"label": "mOS and other files", "bytes": max(0, du.used - used_known)})
            save_json(os.path.join(MOS_CONFIG, "storage-cache.json"),
                      {"total": du.total, "used": du.used, "free": du.free, "parts": parts})
            return True, "ok"
        self._job("storage", go)

    @Property("QVariantMap", notify=changed)
    def storage(self):
        return load_json(os.path.join(MOS_CONFIG, "storage-cache.json"), {})

    # ------------------------------------------------------------ Apps & defaults
    @Slot(result="QVariantList")
    def apps(self):
        return [{"id": a["id"], "name": a["name"], "icon": a["icon"], "removable": bool(a["flatpak"]),
                 "flatpak": a["flatpak"]} for a in all_apps()]

    @Slot(str)
    def openApp(self, desktop_id):
        for d in APP_DIRS:
            p = os.path.join(d, desktop_id + ".desktop")
            if os.path.exists(p):
                e = desktop_entry(p) or {}
                args = [a for a in shlex.split(e.get("Exec", "")) if not (a.startswith("%") and len(a) == 2)]
                if args:
                    start(args)
                return

    @Slot(str)
    def uninstallApp(self, flatpak_id):
        self._job("apps", lambda: (sh(["flatpak", "uninstall", "-y", "--noninteractive", flatpak_id], timeout=300)[0],
                                   "Uninstalled"))

    DEFAULT_KINDS = {
        "browser": ("Web browser", "x-scheme-handler/https"),
        "email": ("Email", "x-scheme-handler/mailto"),
        "files": ("Files", "inode/directory"),
        "music": ("Music", "audio/mpeg"),
        "video": ("Videos", "video/mp4"),
        "photos": ("Photos", "image/png"),
        "text": ("Text", "text/plain"),
    }

    @Slot(result="QVariantList")
    def defaultApps(self):
        apps = all_apps()
        out = []
        for kind, (label, mime) in self.DEFAULT_KINDS.items():
            cur = sh(["xdg-mime", "query", "default", mime])[1].strip().removesuffix(".desktop")
            choices = [{"id": a["id"], "name": a["name"], "icon": a["icon"]} for a in apps if mime in a["mime"].split(";")]
            out.append({"kind": kind, "label": label, "current": cur, "choices": choices})
        return out

    @Slot(str, str)
    def setDefaultApp(self, kind, desktop_id):
        mime = self.DEFAULT_KINDS[kind][1]
        if kind == "browser":
            sh(["xdg-settings", "set", "default-web-browser", desktop_id + ".desktop"])
            for m in ("x-scheme-handler/http", "text/html"):
                sh(["xdg-mime", "default", desktop_id + ".desktop", m])
        sh(["xdg-mime", "default", desktop_id + ".desktop", mime])
        self.changed.emit()

    # ------------------------------------------------------------ Language & region
    LANGUAGES = [("en_GB", "English (UK)"), ("en_US", "English (US)"), ("pl_PL", "Polski"),
                 ("de_DE", "Deutsch"), ("fr_FR", "Français"), ("es_ES", "Español")]

    @Slot(result="QVariantMap")
    def language(self):
        lang = kread("plasma-localerc", "Formats", "LANG", os.environ.get("LANG", "en_GB.UTF-8")).split(".")[0]
        return {"current": lang, "choices": [{"code": c, "label": l} for c, l in self.LANGUAGES]}

    @Slot(str)
    def setLanguage(self, code):
        lang = code.split("_")[0]
        kwrite("plasma-localerc", "Translations", "LANGUAGE", f"{code}:{lang}" if code != "en_GB" else "en_GB:en")
        kwrite("plasma-localerc", "Formats", "LANG", f"{code}.UTF-8")
        self.changed.emit()
        self.toast.emit("Sign out and back in to use the new language")

    # ------------------------------------------------------------ Date & time
    @Slot(result="QVariantMap")
    def dateTime(self):
        ok, out = sh(["timedatectl", "show"], timeout=5)
        d = dict(l.split("=", 1) for l in out.splitlines() if "=" in l)
        clock = load_json(os.path.join(MOS_CONFIG, "clock.json"), {"h24": True})
        return {"timezone": d.get("Timezone", ""), "auto": d.get("NTP", "no") == "yes", "h24": clock.get("h24", True)}

    @Slot(result="QVariantList")
    def timezones(self):
        return sh(["timedatectl", "list-timezones"], timeout=5)[1].split()

    @Slot(str)
    def setTimezone(self, tz):
        self._job("time", lambda: sh(["timedatectl", "set-timezone", tz], timeout=60))

    @Slot(bool)
    def setAutoTime(self, on):
        self._job("time", lambda: sh(["timedatectl", "set-ntp", "true" if on else "false"], timeout=60))

    @Slot(bool)
    def set24h(self, on):
        save_json(os.path.join(MOS_CONFIG, "clock.json"), {"h24": on})
        js = ("panels().forEach(function(p){p.widgets('org.kde.plasma.digitalclock').forEach(function(w){"
              "w.currentConfigGroup=['Appearance'];w.writeConfig('use24hFormat', %d);});});" % (2 if on else 0))
        plasma_script(js)
        self.changed.emit()

    # ------------------------------------------------------------ Users
    @Slot(result="QVariantList")
    def users(self):
        me = pwd.getpwuid(os.getuid()).pw_name
        out = []
        for p in pwd.getpwall():
            if 1000 <= p.pw_uid < 60000 and p.pw_shell not in ("/usr/sbin/nologin", "/bin/false"):
                out.append({"login": p.pw_name, "name": p.pw_gecos.split(",")[0] or p.pw_name, "me": p.pw_name == me})
        out.sort(key=lambda u: (not u["me"], u["name"].lower()))
        return out

    @Slot(str, str)
    def setPassword(self, login, password):
        self._job("users", lambda: (sh(["pkexec", "chpasswd"], inp=f"{login}:{password}\n", timeout=120)[0],
                                    "Password changed"))

    @Slot(str, str)
    def setFullName(self, login, name):
        name = name.replace(",", " ").replace(":", " ")
        self._job("users", lambda: (sh(["pkexec", "usermod", "-c", name, login], timeout=120)[0], "Name changed"))

    @Slot(str, str, str, bool)
    def addUser(self, name, login, password, admin):
        login = re.sub(r"[^a-z0-9_-]", "", login.lower())[:32]
        name = name.replace(",", " ").replace(":", " ")

        def go():
            script = ("set -e\nuseradd -m -s /bin/bash -c \"$1\" \"$2\"\n"
                      "printf '%s:%s\\n' \"$2\" \"$3\" | chpasswd\n"
                      "if [ \"$4\" = yes ]; then usermod -aG sudo \"$2\"; fi\n")
            return sh(["pkexec", "sh", "-c", script, "mos", name, login, password, "yes" if admin else "no"],
                      timeout=120)[0], f"Added {name}"
        self._job("users", go)

    @Slot(str)
    def removeUser(self, login):
        self._job("users", lambda: (sh(["pkexec", "userdel", "-r", login], timeout=120)[0], "Removed"))

    # ------------------------------------------------------------ Keyboard
    LAYOUTS = [("gb", "English (UK)"), ("us", "English (US)"), ("pl", "Polish"), ("de", "German"),
               ("fr", "French"), ("es", "Spanish"), ("it", "Italian"), ("pt", "Portuguese"), ("ie", "Irish"),
               ("ua", "Ukrainian"), ("ru", "Russian"), ("tr", "Turkish"), ("ro", "Romanian"), ("nl", "Dutch")]

    @Slot(result="QVariantMap")
    def keyboard(self):
        cur = [l for l in kread("kxkbrc", "Layout", "LayoutList", "gb").split(",") if l]
        names = dict(self.LAYOUTS)
        return {"layouts": [{"code": c, "label": names.get(c, c.upper())} for c in cur],
                "choices": [{"code": c, "label": l} for c, l in self.LAYOUTS if c not in cur],
                "repeat": kread("kcminputrc", "Keyboard", "KeyRepeat", "repeat") != "nothing"}

    @Slot("QVariantList")
    def setLayouts(self, codes):
        codes = [c for c in codes if re.fullmatch(r"[a-z]{2,3}", c)] or ["gb"]
        kwrite("kxkbrc", "Layout", "Use", True)
        kwrite("kxkbrc", "Layout", "LayoutList", ",".join(codes))
        kwrite("kxkbrc", "Layout", "VariantList", "," * (len(codes) - 1))
        kwin_reconfigure()
        dbus_user("call", "org.kde.keyboard", "/Layouts", "org.kde.KeyboardLayouts", "setLayout", "u", "0")
        self.changed.emit()

    # ------------------------------------------------------------ Mouse & trackpad
    def _kwin_devices(self):
        ok, out = dbus_user("get-property", "org.kde.KWin", "/org/kde/KWin/InputDevice",
                            "org.kde.KWin.InputDeviceManager", "devicesSysNames", timeout=5)
        return re.findall(r'"([^"]+)"', out) if ok else []

    @Slot(result="QVariantList")
    def pointers(self):
        out = []
        props = ["name", "pointer", "touchpad", "naturalScroll", "tapToClick", "pointerAcceleration",
                 "supportsDisableEvents"]
        for dev in self._kwin_devices():
            ok, o = dbus_user("get-property", "org.kde.KWin", f"/org/kde/KWin/InputDevice/{dev}",
                              "org.kde.KWin.InputDevice", *props, timeout=5)
            vals = o.strip().splitlines()
            if not ok or len(vals) != len(props):
                continue
            def val(v):
                t, _, rest = v.partition(" ")
                return rest.strip('"') if t == "s" else rest == "true" if t == "b" else float(rest or 0)
            d = dict(zip(props, map(val, vals)))
            if not d["pointer"] or "virtual" in str(d["name"]).lower():
                continue
            out.append({"dev": dev, "name": d["name"], "touchpad": d["touchpad"], "natural": d["naturalScroll"],
                        "tap": d["tapToClick"], "speed": d["pointerAcceleration"]})
        return out

    @Slot(str, str, "QVariant")
    def setPointer(self, dev, prop, value):
        if prop not in ("naturalScroll", "tapToClick", "pointerAcceleration") or not re.fullmatch(r"[\w.-]+", dev):
            return
        t = "d" if prop == "pointerAcceleration" else "b"
        v = f"{float(value):.2f}" if t == "d" else ("true" if value else "false")
        dbus_user("set-property", "org.kde.KWin", f"/org/kde/KWin/InputDevice/{dev}",
                  "org.kde.KWin.InputDevice", prop, t, v, timeout=5)

    # ------------------------------------------------------------ Startup apps
    @Slot(result="QVariantList")
    def startupApps(self):
        user_dir = os.path.join(CONFIG, "autostart")
        out, seen = [], set()
        for d in (user_dir, "/etc/xdg/autostart"):
            for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
                fid = os.path.basename(f)
                if fid in seen:
                    continue
                seen.add(fid)
                e = desktop_entry(f) or {}
                if d != user_dir and (e.get("NoDisplay", "false").lower() == "true"
                                      or "KDE" in e.get("OnlyShowIn", "") or fid.startswith(("mos-", "org.kde.", "kde", "polkit", "xdg-", "at-spi"))):
                    continue  # parts of mOS itself
                out.append({"id": fid, "name": e.get("Name", fid[:-8]), "icon": e.get("Icon", "application-x-executable"),
                            "on": e.get("Hidden", "false").lower() != "true" and e.get("X-GNOME-Autostart-enabled", "true") != "false"})
        return out

    @Slot(str, bool)
    def setStartupApp(self, fid, on):
        user_dir = os.path.join(CONFIG, "autostart")
        os.makedirs(user_dir, exist_ok=True)
        dest = os.path.join(user_dir, fid)
        if not os.path.exists(dest):
            for d in ("/etc/xdg/autostart",) + tuple(APP_DIRS):
                if os.path.exists(os.path.join(d, fid)):
                    shutil.copy(os.path.join(d, fid), dest)
                    break
        if os.path.exists(dest):
            sh(["kwriteconfig6", "--file", dest, "--group", "Desktop Entry", "--key", "Hidden", "false" if on else "true"])
        self.changed.emit()

    @Slot(str)
    def addStartupApp(self, desktop_id):
        self.setStartupApp(desktop_id + ".desktop", True)

    @Slot(str)
    def removeStartupApp(self, fid):
        p = os.path.join(CONFIG, "autostart", fid)
        if os.path.exists(p) and not os.path.exists(os.path.join("/etc/xdg/autostart", fid)):
            os.remove(p)
        else:
            self.setStartupApp(fid, False)
        self.changed.emit()

    # ------------------------------------------------------------ Effects
    @Property("QVariantMap", notify=changed)
    def effects(self):
        def on(key, d):
            return kread("kwinrc", "Plugins", key, d).lower() == "true"
        return {"glass": on("blurEnabled", "true"), "genie": on("magiclampEnabled", "true"),
                "zoom": on("scaleEnabled", "true"), "wobbly": on("wobblywindowsEnabled", "false")}

    @Property(bool, notify=changed)
    def appStyle(self):
        return app_style_on()

    @Slot(bool)
    def setAppStyle(self, on):
        if on:
            self._job("appstyle", lambda: (sh(["mos-kvantum"], timeout=60)[0], "Open apps again to see the new look"))
        else:
            sh(["mos-kvantum", "--off"])
            self.toast.emit("Open apps again to see the change")
        self.changed.emit()

    @Slot(str, bool)
    def setEffect(self, name, on):
        key = {"glass": "blurEnabled", "genie": "magiclampEnabled", "zoom": "scaleEnabled",
               "wobbly": "wobblywindowsEnabled"}.get(name)
        if not key:
            return
        kwrite("kwinrc", "Plugins", key, on)
        if name == "genie":
            kwrite("kwinrc", "Plugins", "squashEnabled", not on)
        if name == "zoom":
            kwrite("kwinrc", "Plugins", "fadeEnabled", not on)
        kwin_reconfigure()
        self.changed.emit()

    # ------------------------------------------------------------ Accessibility
    @Slot(result="QVariantMap")
    def accessibility(self):
        font = kread("kdeglobals", "General", "font", "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
        try:
            size = int(float(font.split(",")[1]))
        except (IndexError, ValueError):
            size = 10
        return {"textSize": size,
                "reduceMotion": kread("kdeglobals", "KDE", "AnimationDurationFactor", "1") in ("0", "0.0"),
                "colourFilter": kread("kwinrc", "Plugins", "colorblindnesscorrectionEnabled", "false").lower() == "true",
                "zoom": kread("kwinrc", "Plugins", "zoomEnabled", "true").lower() == "true"}

    @Slot(int)
    def setTextSize(self, size):
        for key, base in (("font", "Noto Sans"), ("menuFont", "Noto Sans"), ("toolBarFont", "Noto Sans")):
            kwrite("kdeglobals", "General", key, f"{base},{size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
        self.changed.emit()
        self.toast.emit("New text size: open apps update when they restart")

    @Slot(bool)
    def setReduceMotion(self, on):
        kwrite("kdeglobals", "KDE", "AnimationDurationFactor", 0 if on else 1)
        self.changed.emit()

    @Slot(bool)
    def setColourFilter(self, on):
        kwrite("kwinrc", "Plugins", "colorblindnesscorrectionEnabled", on)
        kwin_reconfigure()
        self.changed.emit()

    # ------------------------------------------------------------ Reset
    @Slot()
    def resetLook(self):
        self._job("reset", lambda: (sh(["plasma-apply-lookandfeel", "-a", "org.mos.desktop", "--resetLayout"],
                                       timeout=60)[0], "mOS look and layout are back to normal"))

    @Slot()
    def restart(self):
        start(["systemctl", "reboot"])

    # ------------------------------------------------------------ mOS Account: backup & sync
    def _flatpak_apps(self):
        apps = set()
        for scope in ("--system", "--user"):
            ok, out = sh(["flatpak", "list", scope, "--app", "--columns=application"], timeout=20)
            apps.update(l.strip() for l in out.splitlines() if l.strip())
        return sorted(apps)

    def collect_backup(self):
        """Everything mOS backs up: your look, taskbar, effects, Night Shift, update options and app list."""
        style = load_json(os.path.join(MOS_CONFIG, "style.json"), {})
        wp = style.get("wallpaper", "")
        return {
            "v": 1,
            "theme": load_json(os.path.join(MOS_CONFIG, "theme.json"), {"mode": "dark" if is_dark() else "light"}),
            "accent": self.accent, "accentFromWallpaper": self.accentFromWallpaper,
            "iconShape": self.iconShape, "themedIcons": themed_icons_on(), "appStyle": app_style_on(),
            "wallpaper": wp if wp.startswith("/usr/share/wallpapers/") else "",
            "taskbar": self.taskbar, "effects": self.effects,
            "night": {k: kread("kwinrc", "NightColor", k, "") for k in
                      ("Active", "Mode", "EveningBeginFixed", "MorningBeginFixed", "NightTemperature")},
            "updates": {k: self.updates.options.get(k) for k in ("unit", "insider", "autoDownload")},
            "apps": self._flatpak_apps(),
        }

    def apply_backup(self, b):
        """Put a backup back (runs in the background)."""
        if b.get("theme"):
            self.setThemeMode(b["theme"])
        if b.get("accentFromWallpaper"):
            self.setAccentFromWallpaper(True)
        elif b.get("accent"):
            self.setAccent(b["accent"])
        if b.get("wallpaper") and os.path.exists(b["wallpaper"]):
            self.setWallpaper(b["wallpaper"])
        if b.get("iconShape"):
            self.setIconShape(b["iconShape"])
        if "themedIcons" in b and b["themedIcons"] != themed_icons_on():
            self.setThemedIcons(b["themedIcons"])
        if "appStyle" in b and b["appStyle"] != app_style_on():
            self.setAppStyle(b["appStyle"])
        for k, v in (b.get("effects") or {}).items():
            self.setEffect(k, bool(v))
        for k, v in (b.get("night") or {}).items():
            if v:
                kwrite("kwinrc", "NightColor", k, v)
        kwin_reconfigure()
        for k, v in (b.get("updates") or {}).items():
            if v is not None:
                self.updates.setOption(k, v)
        if b.get("taskbar"):
            self.setTaskbar(b["taskbar"])
        missing = [a for a in b.get("apps", []) if a not in set(self._flatpak_apps())]
        if missing and have("flatpak"):
            self.toast.emit(f"Getting your {len(missing)} apps back… (they'll appear when they're done)")
            ok, out = sh(["flatpak", "install", "--system", "-y", "--noninteractive", "flathub"] + missing, timeout=7200)
            return ok, "Your apps are back" if ok else "Some apps couldn't be put back"
        return True, "Your settings are back"

    @Slot(bool)
    def setSync(self, on):
        self.account.set_sync(on)
        if on:
            self.backupNow()

    @Slot()
    def backupNow(self):
        def go():
            try:
                self.account.backup(self.collect_backup(), platform.node())
                return True, "Backed up to your mOS Account"
            except RuntimeError as e:
                return False, str(e)
        self._job("backup", go)

    @Slot()
    def restoreBackup(self):
        def go():
            try:
                b = self.account.fetch_backup()
            except RuntimeError as e:
                return False, str(e)
            if not b:
                return False, "There's no backup in your account yet"
            return self.apply_backup(b)
        self.toast.emit("Restoring from your mOS Account…")
        self._job("restore", go)

    # ------------------------------------------------------------ Fonts
    @Property("QVariantMap", notify=changed)
    def fonts(self):
        def parse(v, d):
            p = (v or d).split(",")
            try:
                return p[0], float(p[1])
            except (IndexError, ValueError):
                return p[0], 10.0
        fam, size = parse(kread("kdeglobals", "General", "font", ""), "Inter,10")
        mono, msize = parse(kread("kdeglobals", "General", "fixed", ""), "Hack,10")
        return {"family": fam, "size": size, "mono": mono, "monoSize": msize,
                "antialias": kread("kdeglobals", "General", "XftAntialias", "true").lower() == "true"}

    @Property("QVariantList", constant=True)
    def fontFamilies(self):
        ok, out = sh(["fc-list", ":", "family"], timeout=10)
        fams = sorted({l.split(",")[0].strip() for l in out.splitlines() if l.strip() and not l.startswith(".")},
                      key=str.lower)
        return fams or ["Inter", "Noto Sans", "DejaVu Sans"]

    @Slot(str, float)
    def setFont(self, family, size):
        q = f"{family},{size:g},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
        small = f"{family},{max(6, size - 2):g},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
        for key, val in (("font", q), ("menuFont", q), ("toolBarFont", q), ("smallestReadableFont", small)):
            kwrite("kdeglobals", "General", key, val)
        kwrite("kdeglobals", "WM", "activeFont", f"{family},{size:g},-1,5,600,0,0,0,0,0,0,0,0,0,0,1")
        self.changed.emit()
        self.toast.emit("Font changed. Open apps again to see it everywhere")

    @Slot(str, float)
    def setMonoFont(self, family, size):
        kwrite("kdeglobals", "General", "fixed", f"{family},{size:g},-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
        self.changed.emit()

    # ------------------------------------------------------------ Keyboard shortcuts
    @Property("QVariantList", constant=True)
    def shortcuts(self):
        def get(component, action, default):
            v = kread("kglobalshortcutsrc", component, action, "")
            keys = v.split(",")[0].replace("\\t", "  or  ") if v else default
            return keys if keys and keys != "none" else default
        win = "Meta"
        return [
            {"what": "Search apps and files (Spotlight)", "keys": "Meta+Space  or  Alt+Space"},
            {"what": "Open Start", "keys": win},
            {"what": "Files", "keys": "Meta+E"},
            {"what": "Settings", "keys": "Meta+I"},
            {"what": "Lock the screen", "keys": get("ksmserver", "Lock Session", "Meta+L")},
            {"what": "Show the desktop", "keys": get("kwin", "Show Desktop", "Meta+D")},
            {"what": "Overview of open windows", "keys": get("kwin", "Overview", "Meta+W")},
            {"what": "Switch windows", "keys": "Alt+Tab"},
            {"what": "Snap window left / right", "keys": "Meta+Left / Meta+Right"},
            {"what": "Maximise window", "keys": "Meta+Up"},
            {"what": "Minimise window", "keys": get("kwin", "Window Minimize", "Meta+PgDown")},
            {"what": "Close window", "keys": "Alt+F4"},
            {"what": "Screenshot", "keys": "Print  or  Meta+Shift+S"},
            {"what": "Clipboard history", "keys": "Meta+V"},
            {"what": "Emoji", "keys": "Meta+."},
            {"what": "Log out, restart or shut down", "keys": "Ctrl+Alt+Delete"},
        ]

    @Slot()
    def openShortcutEditor(self):
        start(["kcmshell6", "kcm_keys"])

    # ------------------------------------------------------------ Printers
    @Slot(result="QVariantMap")
    def printers(self):
        res = {"available": have("lpstat"), "printers": [], "default": ""}
        if not res["available"]:
            return res
        ok, out = sh(["lpstat", "-d"], timeout=5)
        m = re.search(r":\s*(\S+)", out)
        if m:
            res["default"] = m.group(1)
        ok, out = sh(["lpstat", "-p"], timeout=5)
        for line in out.splitlines():
            m = re.match(r"printer (\S+) (.*)", line)
            if m:
                state = "Ready" if "idle" in m.group(2) else "Printing" if "printing" in m.group(2) else \
                        "Paused" if "disabled" in m.group(2) else m.group(2).split(".")[0]
                res["printers"].append({"name": m.group(1), "state": state, "default": m.group(1) == res["default"]})
        return res

    @Slot(str)
    def setDefaultPrinter(self, name):
        self._job("printer", lambda: (sh(["lpoptions", "-d", name])[0], f"{name} is now your main printer"))

    @Slot(str)
    def removePrinter(self, name):
        self._job("printer", lambda: (sh(["pkexec", "lpadmin", "-x", name], timeout=120)[0], f"Removed {name}"))

    @Slot()
    def addPrinter(self):
        # CUPS finds most network and USB printers by itself; its page adds the rest
        if not start(["kde-add-printer", "--add-printer"]):
            self.openUrl("http://localhost:631/admin")

    @Slot(str)
    def printTestPage(self, name):
        self._job("printer", lambda: (sh(["lp", "-d", name, "/usr/share/cups/data/testprint"], timeout=20)[0],
                                      "Test page sent"))

    # ------------------------------------------------------------ misc
    @Slot(str)
    def openUrl(self, url):
        start(["xdg-open", url])


def main():
    if "--backup" in sys.argv:
        # Daily automatic backup (mos-backup.timer), only when sync is on
        b = Backend()
        if b.account.signedIn and b.account.sync:
            try:
                b.account.backup(b.collect_backup(), platform.node())
                print("backed up")
            except RuntimeError as e:
                print(e)
        return
    QGuiApplication.setApplicationName("mOS Settings")
    QGuiApplication.setDesktopFileName("mos-settings")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("systemsettings"))
    backend = Backend(app)
    engine = QQmlApplicationEngine()
    engine.addImageProvider("icon", IconProvider())
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("startPage", sys.argv[1] if len(sys.argv) > 1 else "style")
    engine.load(os.path.join(HERE, "Main.qml"))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
