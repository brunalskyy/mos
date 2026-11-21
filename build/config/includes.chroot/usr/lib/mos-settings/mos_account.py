"""mOS Account inside mOS.

Signing in happens on the mOS website (Google, email or phone all work there).
The website then hands the account back to this computer:

  1. Settings starts a tiny web server on 127.0.0.1 (this computer only) with a
     random one-time code, and opens the sign-in page with that port and code.
  2. After you sign in, the page sends the browser to
     http://127.0.0.1:<port>/callback#state=<code>&rt=<refresh token>.
     The part after # never leaves this computer.
  3. That local page posts the token to our server, which checks the code,
     swaps the token for your profile (name, email, picture) with Firebase,
     and saves it to ~/.config/mos/account.json (readable only by you).

SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import http.server
import json
import os
import secrets
import shutil
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl

API_KEY = "AIzaSyB2_U65oZbMrrhRC0D5ZcBunF2P3IQVZNQ"  # public web key of the mos-data project
SIGN_IN_PAGE = "https://brunalskyy.github.io/mos/account.html"
# Backup & sync: one private document per person in Firestore (only you can read or write yours)
FIRESTORE = "https://firestore.googleapis.com/v1/projects/mos-data/databases/(default)/documents/users/{uid}"
HOME = os.path.expanduser("~")
STORE = os.path.join(HOME, ".config", "mos", "account.json")
AVATAR = os.path.join(HOME, ".config", "mos", "avatar.png")
FACE = os.path.join(HOME, ".face.icon")

CALLBACK_PAGE = """<!doctype html><html lang="en-GB"><head><meta charset="utf-8"><title>mOS</title>
<style>body{margin:0;height:100vh;display:flex;align-items:center;justify-content:center;
font-family:Inter,system-ui,sans-serif;background:#FBFAFF;color:#1B1B21}
.c{text-align:center;padding:32px;border-radius:28px;background:#fff;box-shadow:0 18px 48px rgba(60,40,120,.12);max-width:360px}
h1{font-size:22px;margin:12px 0 6px}p{color:#5D5A6B;margin:0}</style></head>
<body><div class="c"><h1 id="t">Signing in to mOS…</h1><p id="s">One moment.</p></div>
<script>
const h = new URLSearchParams(location.hash.slice(1));
history.replaceState(null, "", "/callback");
fetch("/token", {method: "POST", headers: {"Content-Type": "application/json"},
  body: JSON.stringify({state: h.get("state"), rt: h.get("rt")})})
 .then(r => r.ok ? r.json() : Promise.reject())
 .then(d => { document.getElementById("t").textContent = "You're signed in to mOS";
              document.getElementById("s").textContent = "Hey " + d.name + "! You can close this window."; })
 .catch(() => { document.getElementById("t").textContent = "That didn't work";
                document.getElementById("s").textContent = "Go back to Settings and try again."; });
</script></body></html>"""


def _post(url, data, form=False, timeout=15):
    body = urllib.parse.urlencode(data).encode() if form else json.dumps(data).encode()
    req = urllib.request.Request(url, data=body, method="POST", headers={
        "Content-Type": "application/x-www-form-urlencoded" if form else "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


def _save(data):
    os.makedirs(os.path.dirname(STORE), exist_ok=True)
    fd = os.open(STORE + ".tmp", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(data, f)
    os.replace(STORE + ".tmp", STORE)


def _load():
    try:
        with open(STORE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


class Account(QObject):
    changed = Signal()
    status = Signal(str)        # "waiting", "signed-in", "error:<text>"

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = _load()
        self._server = None
        self._state = None

    # ---- what QML shows
    @Property(bool, notify=changed)
    def signedIn(self):
        return bool(self._data.get("uid"))

    @Property(str, notify=changed)
    def name(self):
        return self._data.get("name") or (self._data.get("email") or "").split("@")[0] or self._data.get("phone", "")

    @Property(str, notify=changed)
    def email(self):
        return self._data.get("email") or self._data.get("phone") or ""

    @Property(str, notify=changed)
    def photo(self):
        return QUrl.fromLocalFile(AVATAR).toString() + f"?v={int(self._data.get('photoAt', 0))}" \
            if os.path.exists(AVATAR) and self.signedIn else ""

    @Property(str, notify=changed)
    def since(self):
        try:
            return time.strftime("%-d %B %Y", time.localtime(int(self._data.get("createdAt", 0)) / 1000))
        except (ValueError, OverflowError):
            return ""

    # ---- sign in
    @Slot()
    def signIn(self):
        self.cancel()
        self._state = secrets.token_urlsafe(24)
        account = self

        class Handler(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _send(self, code, body, ctype="text/html; charset=utf-8"):
                b = body.encode()
                self.send_response(code)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(b)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(b)

            def do_GET(self):
                if self.path.split("?")[0] == "/callback":
                    self._send(200, CALLBACK_PAGE)
                else:
                    self._send(404, "Not found", "text/plain")

            def do_POST(self):
                if self.path != "/token":
                    return self._send(404, "Not found", "text/plain")
                try:
                    n = int(self.headers.get("Content-Length", "0"))
                    data = json.loads(self.rfile.read(min(n, 16384)).decode())
                except (ValueError, UnicodeDecodeError):
                    return self._send(400, "{}", "application/json")
                if not account._state or not secrets.compare_digest(str(data.get("state", "")), account._state):
                    return self._send(403, "{}", "application/json")
                ok = account._finish(str(data.get("rt", "")))
                if not ok:
                    return self._send(400, "{}", "application/json")
                self._send(200, json.dumps({"name": account.name}), "application/json")
                threading.Thread(target=account.cancel, daemon=True).start()

        try:
            self._server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
        except OSError as e:
            self.status.emit("error:" + str(e))
            return
        port = self._server.server_address[1]
        threading.Thread(target=self._server.serve_forever, daemon=True).start()
        url = f"{SIGN_IN_PAGE}?mos={port}&state={urllib.parse.quote(self._state)}"
        if shutil.which("chromium"):
            subprocess.Popen(["chromium", f"--app={url}", "--class=mos-account"], start_new_session=True,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen(["xdg-open", url], start_new_session=True,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.status.emit("waiting")
        # stop waiting after 10 minutes
        threading.Timer(600, self.cancel).start()

    @Slot()
    def cancel(self):
        srv, self._server, self._state = self._server, None, None
        if srv:
            try:
                srv.shutdown()
                srv.server_close()
            except OSError:
                pass

    def _finish(self, refresh_token):
        try:
            tok = _post(f"https://securetoken.googleapis.com/v1/token?key={API_KEY}",
                        {"grant_type": "refresh_token", "refresh_token": refresh_token}, form=True)
            info = _post(f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={API_KEY}",
                         {"idToken": tok["id_token"]})["users"][0]
        except Exception as e:  # network or bad token
            self.status.emit("error:Couldn't reach mOS Account. Check your internet.")
            return False
        self._data = {"uid": info.get("localId"), "name": info.get("displayName", ""),
                      "email": info.get("email", ""), "phone": info.get("phoneNumber", ""),
                      "photoUrl": info.get("photoUrl", ""), "createdAt": info.get("createdAt", "0"),
                      "refreshToken": tok.get("refresh_token", refresh_token), "photoAt": time.time()}
        self._fetch_photo()
        _save(self._data)
        self.changed.emit()
        self.status.emit("signed-in")
        return True

    def _fetch_photo(self):
        url = self._data.get("photoUrl")
        if not url or not url.startswith("https://"):
            return
        try:
            with urllib.request.urlopen(url, timeout=15) as r:
                img = r.read(5_000_000)
            os.makedirs(os.path.dirname(AVATAR), exist_ok=True)
            with open(AVATAR, "wb") as f:
                f.write(img)
            # Your picture on the lock screen, login screen and Start menu too
            if not os.path.exists(FACE) or os.path.islink(FACE):
                if os.path.islink(FACE):
                    os.unlink(FACE)
                os.symlink(AVATAR, FACE)
                self._data["faceLinked"] = True
        except Exception:
            pass

    @Slot()
    def refresh(self):
        """Pick up a new name or picture from the account."""
        rt = self._data.get("refreshToken")
        if rt:
            threading.Thread(target=self._finish, args=(rt,), daemon=True).start()

    @Slot()
    def signOut(self):
        if self._data.get("faceLinked") and os.path.islink(FACE):
            os.unlink(FACE)
        for p in (STORE, AVATAR):
            try:
                os.remove(p)
            except OSError:
                pass
        self._data = {}
        self.changed.emit()
        self.status.emit("signed-out")

    # ---- backup & sync (Firestore, through its REST API)
    @Property(bool, notify=changed)
    def sync(self):
        return bool(self._data.get("sync"))

    @Property(str, notify=changed)
    def lastBackup(self):
        t = self._data.get("lastBackup")
        if not t:
            return ""
        return time.strftime("%-d %b at %H:%M", time.localtime(t)) + (" from " + self._data["lastDevice"]
                                                                      if self._data.get("lastDevice") else "")

    def set_sync(self, on):
        self._data["sync"] = bool(on)
        _save(self._data)
        self.changed.emit()

    def _id_token(self):
        tok = _post(f"https://securetoken.googleapis.com/v1/token?key={API_KEY}",
                    {"grant_type": "refresh_token", "refresh_token": self._data["refreshToken"]}, form=True)
        if tok.get("refresh_token") and tok["refresh_token"] != self._data.get("refreshToken"):
            self._data["refreshToken"] = tok["refresh_token"]
            _save(self._data)
        return tok["id_token"]

    def _cloud(self, method, body=None, query=""):
        url = FIRESTORE.format(uid=urllib.parse.quote(self._data["uid"])) + query
        req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                     headers={"Authorization": "Bearer " + self._id_token(),
                                              "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.loads(r.read().decode() or "{}")
        except urllib.error.HTTPError as e:
            if e.code == 404 and method == "GET":
                return None
            detail = ""
            try:
                detail = json.loads(e.read().decode()).get("error", {}).get("status", "")
            except Exception:
                pass
            if e.code in (403, 404) or detail in ("PERMISSION_DENIED", "NOT_FOUND", "FAILED_PRECONDITION"):
                raise RuntimeError("Backup isn't switched on for mOS Account yet")
            raise RuntimeError("Couldn't reach mOS Account")

    def backup(self, payload, device):
        """Save a backup (settings + app list) to your account."""
        if not self.signedIn:
            raise RuntimeError("Sign in first")
        now = time.time()
        self._cloud("PATCH", {"fields": {
            "backup": {"stringValue": json.dumps(payload)},
            "device": {"stringValue": device},
            "updatedAt": {"timestampValue": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now))}}},
            "?updateMask.fieldPaths=backup&updateMask.fieldPaths=device&updateMask.fieldPaths=updatedAt")
        self._data["lastBackup"], self._data["lastDevice"] = now, device
        _save(self._data)
        self.changed.emit()

    def fetch_backup(self):
        """Your last backup, or None."""
        if not self.signedIn:
            raise RuntimeError("Sign in first")
        doc = self._cloud("GET")
        if not doc:
            return None
        raw = doc.get("fields", {}).get("backup", {}).get("stringValue")
        return json.loads(raw) if raw else None

    @Slot()
    def manage(self):
        subprocess.Popen(["xdg-open", SIGN_IN_PAGE], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
