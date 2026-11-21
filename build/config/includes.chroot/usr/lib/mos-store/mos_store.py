#!/usr/bin/env python3
"""mOS Store: the app store for mOS.

The whole Flathub catalogue comes from the AppStream file Flatpak already keeps on
the computer (what Flathub asks app stores to use), so browsing and searching work
offline and fast. Installs, updates and removals go through libflatpak, which gives
real progress: percent, speed (MB/s or Mbps) and time left. Ratings and reviews come
from ODRS, the open review service GNOME Software and KDE Discover use too.

SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import glob
import gzip
import hashlib
import html
import json
import os
import pwd
import random
import re
import shutil
import subprocess
import sys
import threading
import time
import urllib.request
import xml.etree.ElementTree as ET

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
SETTINGS_DIR = "/usr/lib/mos-settings"
sys.path.insert(0, SETTINGS_DIR)
from mos_settings import kread, is_dark  # noqa: E402

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "mos-store")
OPTIONS = os.path.join(HOME, ".config", "mos", "updates.json")   # shared with Software update (MB/s or Mbps)
ACCOUNT = os.path.join(HOME, ".config", "mos", "account.json")
REMOTE = "flathub"
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"
ODRS = "https://odrs.gnome.org/1.0/reviews/api"
UA = "mOS-Store/1.0 (+https://brunalskyy.github.io/mos)"

try:
    import gi
    gi.require_version("Flatpak", "1.0")
    from gi.repository import Flatpak, GLib, Gio
    HAVE_GI = True
except Exception:  # noqa: BLE001  (no libflatpak: fall back to the flatpak command)
    HAVE_GI = False

# Hand-picked apps for Today and the top of each list (only shown if they're on Flathub)
ESSENTIALS = ["com.google.Chrome", "org.mozilla.firefox", "com.spotify.Client", "com.discordapp.Discord",
              "org.videolan.VLC", "com.obsproject.Studio", "org.libreoffice.LibreOffice", "org.onlyoffice.desktopeditors",
              "org.telegram.desktop", "com.slack.Slack", "us.zoom.Zoom", "com.visualstudio.code", "md.obsidian.Obsidian",
              "org.gimp.GIMP", "org.kde.krita", "org.inkscape.Inkscape", "org.blender.Blender", "org.kde.kdenlive",
              "org.audacityteam.Audacity", "com.github.tchx84.Flatseal", "io.github.zen_browser.zen", "com.brave.Browser",
              "org.signal.Signal", "com.github.IsmaelMartinez.teams_for_linux", "org.chromium.Chromium",
              "io.missioncenter.MissionCenter", "com.bitwarden.desktop", "org.mozilla.Thunderbird"]
GAMES = ["com.valvesoftware.Steam", "org.prismlauncher.PrismLauncher", "com.heroicgameslauncher.hgl", "net.lutris.Lutris",
         "io.github.mcpelauncher-dev.mcpelauncher", "org.luanti.luanti", "net.supertuxkart.SuperTuxKart",
         "com.github.k4zmu2a.spacecadetpinball", "io.itch.itch", "org.libretro.RetroArch", "net.veloren.airshipper",
         "org.openttd.OpenTTD", "info.beyondallreason.bar", "net.minetest.Minetest", "org.gnome.Chess",
         "io.github.ryubing.Ryujinx", "net.pcsx2.PCSX2", "org.DolphinEmu.dolphin-emu", "com.moonlight_stream.Moonlight",
         "io.github.lime3ds.Lime3DS", "com.usebottles.bottles", "net.davidotek.pupgui2"]
CATEGORIES = [  # id, name, Flathub categories
    {"id": "create", "name": "Create", "icon": "palette", "cats": ["Graphics", "AudioVideo", "Video", "Audio"]},
    {"id": "work", "name": "Productivity", "icon": "general", "cats": ["Office"]},
    {"id": "social", "name": "Social & web", "icon": "globe", "cats": ["Network", "Chat", "InstantMessaging", "WebBrowser"]},
    {"id": "learn", "name": "Learn", "icon": "info", "cats": ["Education", "Science"]},
    {"id": "dev", "name": "Developer tools", "icon": "shortcut", "cats": ["Development"]},
    {"id": "tools", "name": "Utilities", "icon": "shapes", "cats": ["Utility", "System"]},
    {"id": "games", "name": "Games", "icon": "game", "cats": ["Game"]},
]


def have(tool):
    return shutil.which(tool) is not None


def run(cmd, timeout=30):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode == 0, p.stdout
    except (OSError, subprocess.TimeoutExpired):
        return False, ""


def human_size(n):
    if not n:
        return ""
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1000 or unit == "GB":
            return f"{n:.0f} {unit}" if unit in ("B", "KB") else f"{n:.1f} {unit}"
        n /= 1000
    return ""


def human_eta(sec):
    sec = int(max(0, sec))
    if sec < 60:
        return f"{max(1, sec)}s left"
    if sec < 3600:
        return f"{sec // 60} min {sec % 60:02d}s left"
    return f"{sec // 3600} h {sec % 3600 // 60} min left"


def http_json(url, data=None, timeout=12):
    req = urllib.request.Request(url, data=json.dumps(data).encode() if data is not None else None,
                                 headers={"User-Agent": UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


# ---------------------------------------------------------------- the catalogue
def appstream_files():
    """Flathub's AppStream on this computer (system first, then your own)."""
    out = []
    for base in ("/var/lib/flatpak/appstream", os.path.join(HOME, ".local/share/flatpak/appstream")):
        for f in glob.glob(os.path.join(base, REMOTE, "*", "active", "appstream.xml*")):
            if f.endswith((".xml", ".xml.gz")):
                out.append(f)
    return out


def text_of(el):
    return re.sub(r"\s+", " ", "".join(el.itertext())).strip() if el is not None else ""


def english(parent, tag):
    for el in parent.findall(tag):
        if el.get(XML_LANG) in (None, "en", "en_GB", "C"):
            return el
    return None


def description_html(el):
    """AppStream description (<p>, <ul><li>) to simple rich text for QML."""
    if el is None:
        return ""
    parts = []
    for child in el:
        if child.get(XML_LANG) not in (None, "en", "C"):
            continue
        if child.tag == "p":
            parts.append("<p>" + html.escape(text_of(child)) + "</p>")
        elif child.tag in ("ul", "ol"):
            items = [li for li in child if li.get(XML_LANG) in (None, "en", "C")]
            parts.append("<ul>" + "".join("<li>" + html.escape(text_of(li)) + "</li>" for li in items) + "</ul>")
    return "".join(parts)


def parse_component(c, icon_dir):
    kind = c.get("type", "")
    if kind not in ("desktop-application", "desktop", "console-application"):
        return None
    cid = (c.findtext("id") or "").strip()
    if cid.endswith(".desktop"):
        cid = cid[:-8]
    name = text_of(english(c, "name"))
    if not cid or not name:
        return None
    app = {"id": cid, "name": name, "summary": text_of(english(c, "summary")),
           "description": description_html(english(c, "description")),
           "developer": "", "icon": "", "categories": [], "keywords": "", "screenshots": [],
           "homepage": "", "license": c.findtext("project_license") or "", "version": "", "released": 0,
           "releaseNotes": "", "ref": "", "verified": False, "console": kind == "console-application"}
    dev = c.find("developer")
    app["developer"] = text_of(english(dev, "name")) if dev is not None else text_of(english(c, "developer_name"))
    # icon: the cached 128px one on disk, else a remote one
    best = None
    for ic in c.findall("icon"):
        t = ic.get("type")
        if t == "cached":
            size = int(ic.get("height") or ic.get("width") or 64)
            path = os.path.join(icon_dir, f"{size}x{size}", (ic.text or "").strip())
            if os.path.exists(path) and (best is None or (best[0] != "remote" and size > best[1])):
                best = ("cached", size, "file://" + path)
        elif t == "remote" and best is None:
            best = ("remote", 0, (ic.text or "").strip())
    if best:
        app["icon"] = best[2]
    cats = c.find("categories")
    if cats is not None:
        app["categories"] = [x.text for x in cats.findall("category") if x.text]
    kw = c.find("keywords")
    if kw is not None:
        app["keywords"] = " ".join(x.text or "" for x in kw.findall("keyword") if x.get(XML_LANG) is None)
    shots = c.find("screenshots")
    if shots is not None:
        for s in shots.findall("screenshot"):
            images = [(int(i.get("width") or 0), i.get("type"), (i.text or "").strip()) for i in s.findall("image")
                      if i.get(XML_LANG) is None]
            if not images:
                continue
            full = next((u for w, t, u in images if t == "source"), images[0][2])
            thumbs = sorted([(w, u) for w, t, u in images if t == "thumbnail" and w], key=lambda x: x[0])
            thumb = next((u for w, u in thumbs if w >= 600), thumbs[-1][1] if thumbs else full)
            app["screenshots"].append({"thumb": thumb, "full": next((u for w, u in thumbs if w >= 1200), full),
                                       "caption": text_of(english(s, "caption"))})
    for u in c.findall("url"):
        if u.get("type") == "homepage":
            app["homepage"] = (u.text or "").strip()
    rel = c.find("releases")
    if rel is not None:
        first = rel.find("release")
        if first is not None:
            app["version"] = first.get("version", "")
            try:
                app["released"] = int(first.get("timestamp") or 0)
            except ValueError:
                pass
            app["releaseNotes"] = description_html(first.find("description"))
    for b in c.findall("bundle"):
        if b.get("type") == "flatpak":
            app["ref"] = (b.text or "").strip()
    custom = c.find("custom")
    if custom is not None:
        for v in custom.findall("value"):
            if v.get("key") == "flathub::verification::verified" and (v.text or "").strip() == "true":
                app["verified"] = True
    if not app["ref"]:
        app["ref"] = f"app/{cid}/x86_64/stable"
    return app


def load_catalogue():
    files = appstream_files()
    if not files:
        return []
    src = max(files, key=os.path.getmtime)
    stamp = f"{os.path.getmtime(src):.0f}"
    cache = os.path.join(CACHE, "catalogue.json")
    try:
        with open(cache) as f:
            data = json.load(f)
        if data.get("stamp") == stamp and data.get("v") == 2:
            return data["apps"]
    except (OSError, ValueError):
        pass
    icon_dir = os.path.join(os.path.dirname(src), "icons")
    opener = gzip.open if src.endswith(".gz") else open
    apps = {}
    with opener(src, "rb") as f:
        for event, el in ET.iterparse(f, events=("end",)):
            if el.tag == "component":
                a = parse_component(el, icon_dir)
                if a:
                    apps[a["id"]] = a
                el.clear()
    out = sorted(apps.values(), key=lambda a: a["name"].lower())
    os.makedirs(CACHE, exist_ok=True)
    with open(cache + ".tmp", "w") as f:
        json.dump({"v": 2, "stamp": stamp, "apps": out}, f)
    os.replace(cache + ".tmp", cache)
    return out


# ---------------------------------------------------------------- backend
class Store(QObject):
    changed = Signal()            # catalogue / installed / updates changed
    jobsChanged = Signal()
    reviewsReady = Signal(str, "QVariantMap")
    sizeReady = Signal(str, "QVariantMap")
    toast = Signal(str)
    openApp = Signal(str)         # ask the window to show an app page

    def __init__(self, parent=None):
        super().__init__(parent)
        self._apps = []
        self._by_id = {}
        self._loading = True
        self._status = "Getting the app list ready…"
        self._installed = {}      # id -> {"ref", "installation", "version"}
        self._updates = {}        # id -> new version
        self._jobs = {}           # id -> progress info
        self._cancels = {}        # id -> Gio.Cancellable
        self._queue = []
        self._lock = threading.Lock()
        self._busy = False
        threading.Thread(target=self._start, daemon=True).start()

    # ---- startup
    def _start(self):
        self._load()
        self._refresh_installed()
        # Fresh app list from Flathub once a day (Flatpak's own AppStream download)
        files = appstream_files()
        if not files or time.time() - max(os.path.getmtime(f) for f in files) > 86400:
            self._status = "Updating the app list…"
            self.changed.emit()
            if have("flatpak"):
                run(["flatpak", "update", "--appstream", REMOTE], timeout=300)
            self._load()
        self._check_updates()

    def _load(self):
        try:
            apps = load_catalogue()
        except (OSError, ET.ParseError) as e:
            apps = []
            print("mos-store: couldn't read the app list:", e, file=sys.stderr)
        self._apps = apps
        self._by_id = {a["id"]: a for a in apps}
        self._loading = False
        self._status = "" if apps else "Couldn't load apps. Check your internet connection, then try again."
        self.changed.emit()

    def _refresh_installed(self):
        inst = {}
        if have("flatpak"):
            for scope in ("--system", "--user"):
                ok, out = run(["flatpak", "list", scope, "--app", "--columns=application,ref,version"])
                for line in out.splitlines():
                    p = line.split("\t")
                    if len(p) >= 2 and p[0]:
                        inst[p[0]] = {"ref": p[1], "installation": scope.strip("-"), "version": p[2] if len(p) > 2 else ""}
        self._installed = inst
        self.changed.emit()

    def _check_updates(self):
        ups = {}
        if have("flatpak"):
            for scope in ("--system", "--user"):
                ok, out = run(["flatpak", "remote-ls", scope, "--updates", "--app", "--columns=application,version"], timeout=90)
                for line in out.splitlines():
                    p = line.split("\t")
                    if p and p[0]:
                        ups[p[0]] = p[1] if len(p) > 1 else ""
        self._updates = ups
        self.changed.emit()

    # ---- small helpers
    def _card(self, a):
        return {"id": a["id"], "name": a["name"], "summary": a["summary"], "icon": a["icon"],
                "developer": a["developer"], "verified": a["verified"],
                "shot": a["screenshots"][0]["thumb"] if a["screenshots"] else "",
                "category": self._category_name(a)}

    def _category_name(self, a):
        for c in CATEGORIES:
            if any(x in a["categories"] for x in c["cats"]):
                return c["name"]
        return "Apps"

    def _rank(self, apps, picks=()):
        """Hand-picked first, then verified apps with screenshots, then the rest."""
        order = {pid: i for i, pid in enumerate(picks)}
        return sorted(apps, key=lambda a: (order.get(a["id"], 10_000), not a["verified"], not a["screenshots"],
                                           a["name"].lower()))

    # ---- properties
    @Property(bool, notify=changed)
    def loading(self):
        return self._loading

    @Property(str, notify=changed)
    def status(self):
        return self._status

    @Property(int, notify=changed)
    def appCount(self):
        return len(self._apps)

    @Property(bool, constant=True)
    def dark(self):
        return is_dark()

    @Property(str, constant=True)
    def accent(self):
        for key in ("LastUsedCustomAccentColor", "AccentColor"):
            parts = [p.strip() for p in kread("kdeglobals", "General", key).split(",")]
            if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
                return "#%02X%02X%02X" % tuple(int(x) for x in parts[:3])
        return "#E8833A"

    @Property(str, constant=True)
    def iconShape(self):
        return kread("kdeglobals", "Icons", "mosShape", "circle")

    @Property("QVariantMap", notify=jobsChanged)
    def jobs(self):
        return dict(self._jobs)

    @Property("QVariantList", notify=changed)
    def categories(self):
        return [{"id": c["id"], "name": c["name"], "icon": c["icon"]} for c in CATEGORIES]

    @Property(int, notify=changed)
    def updateCount(self):
        return len(self._updates)

    @Property(str, notify=changed)
    def speedUnit(self):
        try:
            return json.load(open(OPTIONS)).get("unit", "MB/s")
        except (OSError, ValueError):
            return "MB/s"

    @Slot(str)
    def setSpeedUnit(self, unit):
        try:
            d = json.load(open(OPTIONS))
        except (OSError, ValueError):
            d = {}
        d["unit"] = unit
        os.makedirs(os.path.dirname(OPTIONS), exist_ok=True)
        json.dump(d, open(OPTIONS, "w"), indent=2)
        self.changed.emit()

    # ---- lists for the pages
    @Slot(result="QVariantMap")
    def today(self):
        apps = [a for a in self._apps if not a["console"]]
        day = int(time.time() // 86400)
        picks = [self._by_id[i] for i in ESSENTIALS if i in self._by_id and self._by_id[i]["screenshots"]]
        games = [self._by_id[i] for i in GAMES if i in self._by_id and self._by_id[i]["screenshots"]]
        fresh = sorted([a for a in apps if a["verified"] and a["screenshots"] and a["released"]],
                       key=lambda a: -a["released"])[:12]
        rnd = random.Random(day)
        hidden_gems = [a for a in apps if a["verified"] and a["screenshots"] and a["id"] not in ESSENTIALS + GAMES]
        rnd.shuffle(hidden_gems)
        return {
            "appOfTheDay": self._card(picks[day % len(picks)]) if picks else {},
            "gameOfTheDay": self._card(games[day % len(games)]) if games else {},
            "essentials": [self._card(a) for a in picks[:12]],
            "whatsNew": [dict(self._card(a), version=a["version"],
                              when=time.strftime("%-d %b", time.localtime(a["released"]))) for a in fresh],
            "discover": [self._card(a) for a in hidden_gems[:8]],
        }

    @Slot(str, int, result="QVariantList")
    def category(self, cat_id, limit):
        c = next((c for c in CATEGORIES if c["id"] == cat_id), None)
        if not c:
            return []
        if cat_id == "games":
            apps = [a for a in self._apps if "Game" in a["categories"]]
            picks = GAMES
        else:
            apps = [a for a in self._apps if any(x in a["categories"] for x in c["cats"]) and "Game" not in a["categories"]]
            picks = ESSENTIALS
        apps = self._rank(apps, picks)
        return [self._card(a) for a in (apps[:limit] if limit > 0 else apps)]

    @Slot(str, result="QVariantList")
    def search(self, q):
        q = q.strip().lower()
        if not q:
            return []
        words = q.split()
        scored = []
        for a in self._apps:
            name = a["name"].lower()
            hay = " ".join((name, a["summary"].lower(), a["keywords"].lower(), a["developer"].lower(), a["id"].lower()))
            if not all(w in hay for w in words):
                continue
            score = 0 if name == q else 1 if name.startswith(q) else 2 if q in name else 3
            scored.append((score, not a["verified"], a["id"] not in ESSENTIALS + GAMES, name, a))
        scored.sort(key=lambda x: x[:4])
        return [self._card(x[4]) for x in scored[:80]]

    @Slot(str, result="QVariantMap")
    def app(self, app_id):
        a = self._by_id.get(app_id)
        if not a:
            inst = self._installed.get(app_id)
            if not inst:
                return {}
            a = {"id": app_id, "name": app_id.split(".")[-1], "summary": "", "description": "", "developer": "",
                 "icon": "", "categories": [], "screenshots": [], "homepage": "", "license": "", "version": inst["version"],
                 "released": 0, "releaseNotes": "", "ref": inst["ref"], "verified": False}
        d = dict(a)
        d["category"] = self._category_name(a)
        d["releasedText"] = time.strftime("%-d %B %Y", time.localtime(a["released"])) if a.get("released") else ""
        return d

    @Slot(result="QVariantList")
    def installed(self):
        out = []
        for app_id, info in sorted(self._installed.items()):
            a = self._by_id.get(app_id)
            card = self._card(a) if a else {"id": app_id, "name": app_id.split(".")[-1], "summary": "", "icon": "",
                                            "developer": "", "verified": False, "shot": "", "category": "Apps"}
            card["version"] = info["version"]
            card["newVersion"] = self._updates.get(app_id, "")
            out.append(card)
        out.sort(key=lambda c: (not c["newVersion"], c["name"].lower()))
        return out

    @Slot(str, result=str)
    def stateOf(self, app_id):
        if app_id in self._jobs and self._jobs[app_id].get("state") not in ("done", "error"):
            return "busy"
        if app_id in self._updates:
            return "update"
        if app_id in self._installed:
            return "installed"
        return "get"

    # ---- sizes and reviews (in the background)
    @Slot(str)
    def fetchSize(self, app_id):
        a = self._by_id.get(app_id)
        if not a or not HAVE_GI:
            return

        def go():
            try:
                kind, name, arch, branch = a["ref"].split("/")
                inst = Flatpak.Installation.new_system(None)
                rr = inst.fetch_remote_ref_sync(REMOTE, Flatpak.RefKind.APP, name, arch, branch, None)
                self.sizeReady.emit(app_id, {"download": human_size(rr.get_download_size()),
                                             "installed": human_size(rr.get_installed_size())})
            except Exception as e:  # noqa: BLE001  (no size is fine)
                print("mos-store: size:", e, file=sys.stderr)
        threading.Thread(target=go, daemon=True).start()

    def _user_hash(self):
        try:
            mid = open("/etc/machine-id").read().strip()
        except OSError:
            mid = "mos"
        return hashlib.sha1(f"mos-store[{pwd.getpwuid(os.getuid()).pw_name}:{mid}]".encode()).hexdigest()

    @Slot(str)
    def fetchReviews(self, app_id):
        def go():
            res = {"reviews": [], "average": 0, "total": 0, "stars": [0, 0, 0, 0, 0], "skey": ""}
            try:
                r = http_json(f"{ODRS}/ratings/{app_id}")
                stars = [int(r.get(f"star{i}", 0)) for i in range(1, 6)]
                total = sum(stars)
                res["stars"], res["total"] = stars, total
                res["average"] = round(sum((i + 1) * n for i, n in enumerate(stars)) / total, 1) if total else 0
            except Exception as e:  # noqa: BLE001
                print("mos-store: ratings:", e, file=sys.stderr)
            try:
                data = http_json(f"{ODRS}/fetch", {
                    "user_hash": self._user_hash(), "app_id": app_id, "locale": "en_GB", "distro": "mOS",
                    "version": (self._by_id.get(app_id) or {}).get("version") or "unknown", "limit": 30})
                for rv in data if isinstance(data, list) else []:
                    res["skey"] = rv.get("user_skey", res["skey"])
                    if not rv.get("review_id") or not rv.get("description"):
                        continue
                    who = (rv.get("user_display") or "").strip() or "Someone"
                    res["reviews"].append({
                        "name": who, "rating": round(int(rv.get("rating", 0)) / 20),
                        "title": rv.get("summary", ""), "text": rv.get("description", ""),
                        "date": time.strftime("%-d %b %Y", time.localtime(int(rv.get("date_created", 0)))),
                        "helpful": int(rv.get("karma_up", 0)), "version": rv.get("version", "")})
                res["reviews"].sort(key=lambda r: -r["helpful"])
            except Exception as e:  # noqa: BLE001
                print("mos-store: reviews:", e, file=sys.stderr)
            self.reviewsReady.emit(app_id, res)
        threading.Thread(target=go, daemon=True).start()

    @Property(str, constant=True)
    def reviewerName(self):
        """Your mOS Account name (or your computer user name) for reviews."""
        try:
            n = json.load(open(ACCOUNT)).get("name", "")
            if n:
                return n
        except (OSError, ValueError):
            pass
        return (pwd.getpwuid(os.getuid()).pw_gecos or "").split(",")[0] or pwd.getpwuid(os.getuid()).pw_name

    @Slot(str, int, str, str, str)
    def submitReview(self, app_id, stars, title, text, skey):
        def go():
            try:
                a = self._by_id.get(app_id) or {}
                http_json(f"{ODRS}/submit", {
                    "user_hash": self._user_hash(), "user_skey": skey, "app_id": app_id, "locale": "en_GB",
                    "distro": "mOS", "version": (self._installed.get(app_id) or {}).get("version") or a.get("version") or "unknown",
                    "user_display": self.reviewerName, "summary": title[:70], "description": text[:3000],
                    "rating": max(1, min(5, stars)) * 20})
                self.toast.emit("Thanks! Your review has been sent")
                self.fetchReviews(app_id)
            except Exception as e:  # noqa: BLE001
                print("mos-store: submit:", e, file=sys.stderr)
                self.toast.emit("Couldn't send your review. Try again later")
        threading.Thread(target=go, daemon=True).start()

    # ---- install / update / remove
    @Slot(str)
    def install(self, app_id):
        self._enqueue(app_id, "install")

    @Slot(str)
    def update(self, app_id):
        self._enqueue(app_id, "update")

    @Slot()
    def updateAll(self):
        for app_id in list(self._updates):
            self._enqueue(app_id, "update")

    @Slot(str)
    def remove(self, app_id):
        self._enqueue(app_id, "remove")

    @Slot(str)
    def cancel(self, app_id):
        job = self._jobs.get(app_id)
        if app_id in self._cancels:
            self._cancels[app_id].cancel()
        elif job and job.get("state") == "queued":
            with self._lock:
                self._queue = [q for q in self._queue if q[0] != app_id]
            self._jobs.pop(app_id, None)
            self.jobsChanged.emit()

    @Slot(str)
    def launch(self, app_id):
        subprocess.Popen(["flatpak", "run", app_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)

    @Slot()
    def openSoftwareUpdate(self):
        subprocess.Popen(["mos-settings", "update"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)

    @Slot(str)
    def openUrl(self, url):
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)

    @Slot()
    def refresh(self):
        threading.Thread(target=lambda: (self._refresh_installed(), self._check_updates()), daemon=True).start()

    def _set_job(self, app_id, **kw):
        job = dict(self._jobs.get(app_id, {}))
        job.update(kw)
        self._jobs[app_id] = job
        self.jobsChanged.emit()

    def _enqueue(self, app_id, action):
        if app_id in self._jobs and self._jobs[app_id].get("state") not in ("done", "error"):
            return
        with self._lock:
            self._queue.append((app_id, action))
        self._set_job(app_id, state="queued", action=action, percent=0, speed="", eta="", message="Waiting…")
        if not self._busy:
            self._busy = True
            threading.Thread(target=self._worker, daemon=True).start()

    def _worker(self):
        while True:
            with self._lock:
                if not self._queue:
                    self._busy = False
                    break
                app_id, action = self._queue.pop(0)
            try:
                ok, msg = (self._run_gi if HAVE_GI else self._run_cli)(app_id, action)
            except Exception as e:  # noqa: BLE001
                ok, msg = False, str(e)
            name = (self._by_id.get(app_id) or {}).get("name", app_id)
            self._cancels.pop(app_id, None)
            if ok:
                self._set_job(app_id, state="done", percent=100, speed="", eta="", message="")
                self.toast.emit({"install": f"{name} is installed", "update": f"{name} is up to date",
                                 "remove": f"{name} was removed"}[action])
            else:
                self._set_job(app_id, state="error", message=msg, speed="", eta="")
                self.toast.emit(f"Couldn't {action} {name}" + (": " + msg if msg and len(msg) < 80 else ""))
            if ok and action == "update":
                self._updates.pop(app_id, None)
            if ok:
                self._jobs.pop(app_id, None)
            self._refresh_installed()
            self.jobsChanged.emit()

    def _ref_for(self, app_id):
        if app_id in self._installed:
            return self._installed[app_id]["ref"], self._installed[app_id]["installation"]
        a = self._by_id.get(app_id)
        return (a["ref"] if a else f"app/{app_id}/x86_64/stable"), "system"

    def _run_gi(self, app_id, action):
        """Run the job with libflatpak so we get real progress."""
        ctx = GLib.MainContext.new()
        ctx.push_thread_default()
        try:
            ref, where = self._ref_for(app_id)
            inst = Flatpak.Installation.new_user(None) if where == "user" else Flatpak.Installation.new_system(None)
            cancel = Gio.Cancellable()
            self._cancels[app_id] = cancel
            self._set_job(app_id, state="preparing", message="Getting ready…")
            # (interaction stays on, so mOS can ask for your password if it needs to)
            t = Flatpak.Transaction.new_for_installation(inst, cancel)
            if action == "install":
                t.add_install(REMOTE, ref, None)
            elif action == "update":
                t.add_update(ref, None, None)
            else:
                t.add_uninstall(ref)

            st = {"total": 0, "done": 0, "ops": [], "cur": 0, "last_bytes": 0, "last_t": time.monotonic(),
                  "rate": 0.0, "error": ""}

            def ready(tr):
                st["ops"] = tr.get_operations()
                st["total"] = sum(op.get_download_size() for op in st["ops"]) or 0
                return True

            def new_op(tr, op, progress):
                st["cur"] = op.get_download_size()
                st["last_bytes"] = 0
                st["last_t"] = time.monotonic()
                kind = op.get_operation_type()
                verb = "Removing" if kind == Flatpak.TransactionOperationType.UNINSTALL else \
                       "Updating" if kind == Flatpak.TransactionOperationType.UPDATE else "Downloading"
                what = op.get_ref().split("/")[1] if "/" in op.get_ref() else op.get_ref()
                is_app = what == app_id
                progress.set_update_frequency(250)

                def changed(p):
                    now = time.monotonic()
                    got = p.get_bytes_transferred()
                    dt = now - st["last_t"]
                    if dt >= 0.5:
                        inst_rate = max(0, got - st["last_bytes"]) / dt
                        st["rate"] = inst_rate if st["rate"] == 0 else st["rate"] * 0.7 + inst_rate * 0.3
                        st["last_bytes"], st["last_t"] = got, now
                    pct_op = p.get_progress()
                    if st["total"]:
                        overall = (st["done"] + st["cur"] * pct_op / 100) / st["total"] * 100
                    else:
                        overall = pct_op
                    left = max(0, st["total"] - st["done"] - st["cur"] * pct_op / 100)
                    unit = self.speedUnit
                    rate = st["rate"]
                    speed = "" if rate < 1 else (f"{rate * 8 / 1e6:.1f} Mbps" if unit == "Mbps" else f"{rate / 1e6:.1f} MB/s")
                    self._set_job(app_id, state="downloading" if action != "remove" else "removing",
                                  percent=int(min(99, overall)), speed=speed,
                                  eta=human_eta(left / rate) if rate > 1000 and left > 0 else "",
                                  done=human_size(st["done"] + st["cur"] * pct_op / 100), total=human_size(st["total"]),
                                  message=f"{verb} {'the app' if is_app else 'what it needs'}…")
                progress.connect("changed", changed)

            def op_done(tr, op, commit, result):
                st["done"] += op.get_download_size()

            def op_error(tr, op, err, details):
                st["error"] = err.message if err else ""
                return False   # stop

            t.connect("ready", ready)
            t.connect("new-operation", new_op)
            t.connect("operation-done", op_done)
            t.connect("operation-error", op_error)
            t.connect("choose-remote-for-ref", lambda tr, r, rr, remotes: 0)
            t.connect("add-new-remote", lambda *a: False)
            try:
                t.run(cancel)
                return True, ""
            except GLib.Error as e:
                if cancel.is_cancelled():
                    return False, "Cancelled"
                msg = st["error"] or e.message
                if "already installed" in msg.lower():
                    return True, ""
                return False, msg.split("\n")[0]
        finally:
            ctx.pop_thread_default()

    def _run_cli(self, app_id, action):
        """Without libflatpak: run the flatpak command (no speed shown)."""
        ref, where = self._ref_for(app_id)
        self._set_job(app_id, state="downloading", percent=0, message="Downloading…")
        cmd = {"install": ["flatpak", "install", "--" + where, "-y", "--noninteractive", REMOTE, ref],
               "update": ["flatpak", "update", "--" + where, "-y", "--noninteractive", ref],
               "remove": ["flatpak", "uninstall", "--" + where, "-y", "--noninteractive", ref]}[action]
        ok, out = run(cmd, timeout=3600)
        return ok, "" if ok else "Something went wrong"


def main():
    QGuiApplication.setApplicationName("mOS Store")
    QGuiApplication.setDesktopFileName("mos-store")
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("mos-store", QIcon.fromTheme("system-software-install")))
    store = Store(app)
    engine = QQmlApplicationEngine()
    engine.addImportPath(SETTINGS_DIR)
    ctx = engine.rootContext()
    ctx.setContextProperty("store", store)
    ctx.setContextProperty("backend", store)   # the shared Material theme reads backend.dark / backend.accent
    # mos-store <app id>, or a .flatpakref from the Flathub website
    start = sys.argv[1] if len(sys.argv) > 1 else ""
    if start.startswith("appstream:"):
        start = start.split(":", 1)[1].lstrip("/")
    if start.endswith(".flatpakref") and os.path.exists(start):
        m = re.search(r"^Name=(\S+)", open(start, errors="replace").read(), re.M)
        start = m.group(1) if m else ""
    if start.endswith(".desktop"):
        start = start[:-8]
    ctx.setContextProperty("startApp", start)
    engine.load(os.path.join(HERE, "Main.qml"))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
