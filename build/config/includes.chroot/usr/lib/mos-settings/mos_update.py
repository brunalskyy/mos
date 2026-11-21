"""mOS Software update (the part that runs as you).

Checking needs no password:
  * mOS updates: the update list on the mOS website (updates/stable.json, or
    insider.json for mOS Insiders) compared with /usr/share/mos/version
  * system updates: apt's list of upgradable packages (kept fresh daily by apt)
  * app updates: Flatpak

Installing runs /usr/lib/mos-settings/mos-update-helper through pkexec (you type
your password once). The helper fetches the update list itself, checks the
download's SHA-256, then installs, and reports progress line by line.

SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import json
import os
import re
import shutil
import subprocess
import threading
import time
import urllib.request

from PySide6.QtCore import QObject, Property, Signal, Slot

UPDATES_URL = "https://brunalskyy.github.io/mos/updates/{channel}.json"
VERSION_FILE = "/usr/share/mos/version"
HOME = os.path.expanduser("~")
SETTINGS = os.path.join(HOME, ".config", "mos", "updates.json")
HELPER = "/usr/lib/mos-settings/mos-update-helper"
RESTART_PKGS = re.compile(r"^(linux-image|linux-headers|systemd|libc6|dbus|plasma-workspace|kwin|sddm|mesa)")


def local_version():
    try:
        with open(VERSION_FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"version": "0", "build": 0}


def human_size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.0f} {unit}" if unit in ("B", "KB") else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n} B"


def human_time(sec):
    sec = int(sec)
    if sec < 60:
        return f"about {max(1, sec)} sec left"
    if sec < 3600:
        return f"about {sec // 60} min left"
    return f"about {sec // 3600} h {sec % 3600 // 60} min left"


class Updates(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._s = {"state": "idle", "message": "", "progress": 0, "speed": "", "eta": "", "phase": "",
                   "mos": {}, "system": [], "apps": [], "downloadSize": 0, "restart": False}
        self._opts = {"autoDownload": True, "nightly": False, "insider": False, "unit": "MB/s",
                      "lastChecked": 0, "history": []}
        try:
            with open(SETTINGS) as f:
                self._opts.update(json.load(f))
        except (OSError, ValueError):
            pass
        self._proc = None

    def _set(self, **kw):
        self._s.update(kw)
        self.changed.emit()

    def _save(self):
        os.makedirs(os.path.dirname(SETTINGS), exist_ok=True)
        with open(SETTINGS, "w") as f:
            json.dump(self._opts, f, indent=2)

    # ---- properties for QML
    @Property("QVariantMap", notify=changed)
    def info(self):
        d = dict(self._s)
        d["current"] = local_version().get("version", "")
        d["lastChecked"] = time.strftime("%-d %b, %H:%M", time.localtime(self._opts["lastChecked"])) \
            if self._opts["lastChecked"] else "never"
        d["downloadSizeText"] = human_size(self._s["downloadSize"]) if self._s["downloadSize"] else ""
        d["count"] = (1 if self._s["mos"] else 0) + len(self._s["system"]) + len(self._s["apps"])
        return d

    @Property("QVariantMap", notify=changed)
    def options(self):
        return dict(self._opts)

    @Slot(str, "QVariant")
    def setOption(self, key, value):
        self._opts[key] = value
        self._save()
        self.changed.emit()

    # ---- checking
    @Slot()
    def check(self):
        if self._s["state"] in ("checking", "installing", "downloading"):
            return
        self._set(state="checking", message="Checking for updates…")
        threading.Thread(target=self._check, daemon=True).start()

    def _check(self):
        mos, system, apps, size = {}, [], [], 0
        channel = "insider" if self._opts.get("insider") else "stable"
        try:
            with urllib.request.urlopen(UPDATES_URL.format(channel=channel) + f"?t={int(time.time())}", timeout=15) as r:
                latest = json.loads(r.read().decode())
            if int(latest.get("build", 0)) > int(local_version().get("build", 0)):
                mos = {"name": latest.get("name", "mOS " + latest.get("version", "")),
                       "version": latest.get("version", ""), "notes": latest.get("notes", []),
                       "size": human_size(int(latest.get("size", 0)))}
                size += int(latest.get("size", 0))
        except Exception:
            pass  # offline or the site is down: still check the rest

        try:
            out = subprocess.run(["apt", "list", "--upgradable"], capture_output=True, text=True, timeout=30).stdout
            for line in out.splitlines():
                m = re.match(r"^([^/]+)/\S+\s+(\S+)", line)
                if m and m.group(1) != "mos-desktop":
                    system.append({"name": m.group(1), "version": m.group(2)})
            uris = subprocess.run(["apt-get", "-o", "Debug::NoLocking=1", "--print-uris", "-qq", "dist-upgrade"],
                                  capture_output=True, text=True, timeout=30).stdout
            size += sum(int(p[2]) for p in (l.split() for l in uris.splitlines()) if len(p) >= 3 and p[2].isdigit())
        except (OSError, subprocess.TimeoutExpired):
            pass

        if shutil.which("flatpak"):
            for scope in ("--system", "--user"):
                try:
                    out = subprocess.run(["flatpak", "remote-ls", scope, "--updates", "--app",
                                          "--columns=name,application"], capture_output=True, text=True,
                                         timeout=60).stdout
                    for line in out.splitlines():
                        parts = line.split("\t")
                        if len(parts) >= 2 and parts[1] and parts[1] != "Application ID":
                            apps.append({"name": parts[0], "id": parts[1], "scope": scope})
                except (OSError, subprocess.TimeoutExpired):
                    pass

        self._opts["lastChecked"] = time.time()
        self._save()
        restart = any(RESTART_PKGS.match(p["name"]) for p in system)
        count = (1 if mos else 0) + len(system) + len(apps)
        self._set(state="available" if count else "uptodate", mos=mos, system=system, apps=apps,
                  downloadSize=size, restart=restart,
                  message=(f"{count} update{'s' if count != 1 else ''} ready" if count else "You're up to date"))

    # ---- installing
    @Slot()
    def install(self):
        if self._s["state"] in ("installing", "downloading"):
            return
        self._set(state="downloading", progress=0, speed="", eta="", phase="Getting ready…",
                  message="Waiting for your password…")
        threading.Thread(target=self._install, daemon=True).start()

    def _install(self):
        channel = "insider" if self._opts.get("insider") else "stable"
        ok_all = True
        if self._s["mos"] or self._s["system"] or any(a["scope"] == "--system" for a in self._s["apps"]):
            ok_all = self._run_helper(channel)
        if ok_all and any(a["scope"] == "--user" for a in self._s["apps"]):
            ok_all = self._run_user_flatpak()
        if ok_all:
            entry = {"when": time.strftime("%-d %b %Y, %H:%M"),
                     "what": ", ".join(filter(None, [self._s["mos"].get("name") if self._s["mos"] else "",
                                                     f"{len(self._s['system'])} system updates" if self._s["system"] else "",
                                                     f"{len(self._s['apps'])} app updates" if self._s["apps"] else ""]))}
            self._opts["history"] = ([entry] + self._opts.get("history", []))[:20]
            self._save()
            self._set(state="restart" if self._s["restart"] or self._s["mos"] else "done", progress=100,
                      speed="", eta="", phase="",
                      message="Restart to finish updating" if self._s["restart"] or self._s["mos"] else "All done",
                      mos={}, system=[], apps=[], downloadSize=0)

    def _progress(self, done, total, started):
        elapsed = max(0.5, time.time() - started)
        rate = done / elapsed
        unit = self._opts.get("unit", "MB/s")
        speed = (f"{rate * 8 / 1e6:.1f} Mbps" if unit == "Mbps" else f"{rate / 1e6:.1f} MB/s") if done else ""
        eta = human_time((total - done) / rate) if rate > 0 and total > done else ""
        return speed, eta

    def _run_helper(self, channel):
        cmd = ["pkexec", HELPER, "--channel", channel]
        try:
            self._proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        except OSError as e:
            self._set(state="error", message=f"Couldn't start the updater ({e})")
            return False
        started, ok = time.time(), False
        for line in self._proc.stdout:
            parts = line.strip().split(" ", 4)
            if not parts:
                continue
            if parts[0] == "PROGRESS" and len(parts) >= 5:
                # PROGRESS <percent> <bytes done> <bytes total> <phase text>
                pct, done, total, phase = int(float(parts[1])), int(parts[2]), int(parts[3]), parts[4]
                speed, eta = self._progress(done, total, started) if total else ("", "")
                self._set(state="downloading" if "Download" in phase else "installing", progress=pct,
                          speed=speed, eta=eta, phase=phase,
                          message=f"{phase} {pct}%")
            elif parts[0] == "PHASE":
                started = time.time()
                self._set(phase=line.strip()[6:], message=line.strip()[6:])
            elif parts[0] == "DONE":
                ok = len(parts) > 1 and parts[1] == "ok"
            elif parts[0] == "ERROR":
                self._set(state="error", message=line.strip()[6:])
        self._proc.wait()
        if self._proc.returncode in (126, 127):
            self._set(state="available", message="Update cancelled")
            return False
        if not ok and self._s["state"] != "error":
            self._set(state="error", message="Something went wrong while updating. Nothing was lost; try again.")
        return ok

    def _run_user_flatpak(self):
        self._set(state="installing", phase="Updating your apps", message="Updating your apps…", progress=0)
        p = subprocess.Popen(["flatpak", "update", "--user", "-y", "--noninteractive"], stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True, bufsize=1)
        for line in p.stdout:
            m = re.search(r"(\d+)%", line)
            if m:
                self._set(progress=int(m.group(1)))
        return p.wait() == 0

    @Slot()
    def restart(self):
        subprocess.Popen(["systemctl", "reboot"])
