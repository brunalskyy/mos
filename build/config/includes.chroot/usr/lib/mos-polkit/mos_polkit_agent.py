#!/usr/bin/env python3
"""mOS password pop-up: the window that asks for your password when an app or
Software update needs to change the system.

It is a polkit authentication agent. It registers with polkitd over D-Bus, shows
an mOS-style dialog for each request, and checks the password with libpolkit-agent
(the same PAM helper every Linux desktop uses), so mOS never sees or stores it
beyond passing it on.

Safety net: KDE's own agent is the backup. If this one doesn't start, or ever
stops, systemd starts KDE's instead (see mos-polkit-agent.service).

SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import os
import pwd
import subprocess
import sys
import traceback

import gi
gi.require_version("Polkit", "1.0")
gi.require_version("PolkitAgent", "1.0")
from gi.repository import Gio, GLib, Polkit, PolkitAgent  # noqa: E402

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl  # noqa: E402
from PySide6.QtGui import QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SETTINGS_DIR = "/usr/lib/mos-settings"
sys.path.insert(0, SETTINGS_DIR)
from mos_settings import kread, is_dark  # noqa: E402

AGENT_PATH = "/org/mos/PolicyKit1/AuthenticationAgent"
CANCELLED = "org.freedesktop.PolicyKit1.Error.Cancelled"
FAILED = "org.freedesktop.PolicyKit1.Error.Failed"
INTERFACE = """
<node>
  <interface name="org.freedesktop.PolicyKit1.AuthenticationAgent">
    <method name="BeginAuthentication">
      <arg type="s" name="action_id" direction="in"/>
      <arg type="s" name="message" direction="in"/>
      <arg type="s" name="icon_name" direction="in"/>
      <arg type="a{ss}" name="details" direction="in"/>
      <arg type="s" name="cookie" direction="in"/>
      <arg type="a(sa{sv})" name="identities" direction="in"/>
    </method>
    <method name="CancelAuthentication">
      <arg type="s" name="cookie" direction="in"/>
    </method>
  </interface>
</node>
"""


def log(*a):
    print("mos-polkit-agent:", *a, file=sys.stderr, flush=True)


def friendly(action_id, message):
    """A plain-English line for the most common requests."""
    known = {
        "org.freedesktop.Flatpak.app-install": "The mOS Store wants to install an app.",
        "org.freedesktop.Flatpak.runtime-install": "The mOS Store wants to install something an app needs.",
        "org.freedesktop.Flatpak.app-uninstall": "The mOS Store wants to remove an app.",
        "org.freedesktop.Flatpak.app-update": "The mOS Store wants to update an app.",
        "org.mos.update": "Software update wants to install the new version of mOS.",
        "org.freedesktop.NetworkManager.settings.modify.system": "Settings wants to change a network for everyone on this computer.",
        "org.freedesktop.timedate1.set-timezone": "Settings wants to change the time zone.",
        "org.freedesktop.hostname1.set-static-hostname": "Settings wants to rename this computer.",
        "org.freedesktop.login1.power-off-multiple-sessions": "Someone else is logged in. Shut down anyway?",
        "org.freedesktop.login1.reboot-multiple-sessions": "Someone else is logged in. Restart anyway?",
    }
    return known.get(action_id, message or "An app wants to make changes to this computer.")


class Bridge(QObject):
    """What the QML dialog shows, and what it can do."""
    changed = Signal()
    showDialog = Signal()
    hideDialog = Signal()
    wrongPassword = Signal()

    def __init__(self, agent):
        super().__init__()
        self.agent = agent
        self._d = {"message": "", "title": "Password needed", "detail": "", "action": "", "user": "", "fullName": "",
                   "avatar": "", "users": [], "error": "", "busy": False, "prompt": "Password"}

    def set(self, **kw):
        self._d.update(kw)
        self.changed.emit()

    @Property("QVariantMap", notify=changed)
    def d(self):
        return dict(self._d)

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

    @Slot(str)
    def submit(self, password):
        self.agent.submit(password)

    @Slot()
    def cancel(self):
        self.agent.cancel_current(by_user=True)

    @Slot(int)
    def chooseUser(self, i):
        self.agent.choose_user(i)


class Agent:
    def __init__(self, app):
        self.app = app
        self.queue = []          # waiting requests
        self.cur = None          # the request on screen
        self.bridge = Bridge(self)
        self.engine = QQmlApplicationEngine()
        self.engine.addImportPath(SETTINGS_DIR)
        ctx = self.engine.rootContext()
        ctx.setContextProperty("agent", self.bridge)
        ctx.setContextProperty("backend", self.bridge)   # the shared mOS theme reads backend.dark / accent
        self.engine.load(QUrl.fromLocalFile(os.path.join(HERE, "Dialog.qml")))
        if not self.engine.rootObjects():
            raise RuntimeError("the dialog didn't load")

    # ---- D-Bus: register with polkitd
    def register(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        node = Gio.DBusNodeInfo.new_for_xml(INTERFACE)
        self.reg_id = self.bus.register_object(AGENT_PATH, node.interfaces[0], self.on_call, None, None)
        subject = None
        try:
            subject = Polkit.UnixSession.new_for_process_sync(os.getpid(), None)
        except GLib.Error as e:
            log("no session for this process, using the display session:", e.message)
        if subject is None or not subject.get_session_id():
            sid = subprocess.run(["loginctl", "show-user", str(os.getuid()), "-p", "Display", "--value"],
                                 capture_output=True, text=True).stdout.strip()
            if not sid:
                raise RuntimeError("couldn't find the login session")
            subject = Polkit.UnixSession.new(sid)
        locale = os.environ.get("LANG") or "en_GB.UTF-8"
        authority = Polkit.Authority.get_sync(None)
        authority.register_authentication_agent_sync(subject, locale, AGENT_PATH, None)
        log("registered for session", subject.get_session_id())

    def on_call(self, conn, sender, path, iface, method, params, invocation):
        try:
            if method == "BeginAuthentication":
                action_id, message, icon_name, details, cookie, identities = params.unpack()
                self.queue.append({"action": action_id, "message": message, "icon": icon_name,
                                   "details": details, "cookie": cookie, "identities": identities,
                                   "invocation": invocation, "session": None})
                if self.cur is None:
                    self.next()
            elif method == "CancelAuthentication":
                (cookie,) = params.unpack()
                if self.cur and self.cur["cookie"] == cookie:
                    self.cancel_current(by_user=False)
                else:
                    for r in list(self.queue):
                        if r["cookie"] == cookie:
                            self.queue.remove(r)
                            r["invocation"].return_dbus_error(CANCELLED, "Cancelled")
                invocation.return_value(None)
            else:
                invocation.return_dbus_error("org.freedesktop.DBus.Error.UnknownMethod", method)
        except Exception as e:  # noqa: BLE001  (never leave polkit waiting)
            log("error handling", method, e)
            traceback.print_exc()
            try:
                invocation.return_dbus_error(FAILED, str(e))
            except Exception:  # noqa: BLE001
                pass

    # ---- one request at a time
    def users_for(self, identities):
        users = []
        for kind, props in identities:
            if kind != "unix-user":
                continue
            try:
                pw = pwd.getpwuid(int(props.get("uid")))
            except (KeyError, TypeError, ValueError):
                continue
            avatar = ""
            for p in (os.path.join(pw.pw_dir, ".face.icon"), os.path.join(pw.pw_dir, ".face"),
                      f"/var/lib/AccountsService/icons/{pw.pw_name}"):
                if os.path.exists(p):
                    avatar = "file://" + os.path.realpath(p)
                    break
            users.append({"uid": pw.pw_uid, "name": pw.pw_name,
                          "fullName": (pw.pw_gecos or "").split(",")[0] or pw.pw_name, "avatar": avatar})
        # you first, if you're allowed
        users.sort(key=lambda u: (u["uid"] != os.getuid(), u["uid"] == 0, u["name"]))
        return users

    def next(self):
        if not self.queue:
            self.cur = None
            self.bridge.hideDialog.emit()
            return
        r = self.queue.pop(0)
        r["users"] = self.users_for(r["identities"])
        if not r["users"]:
            r["invocation"].return_dbus_error(FAILED, "No one who can approve this")
            return self.next()
        r["user"] = 0
        self.cur = r
        u = r["users"][0]
        self.bridge.set(title="Password needed", message=friendly(r["action"], r["message"]),
                        detail=r["message"], action=r["action"], user=u["name"], fullName=u["fullName"],
                        avatar=u["avatar"], users=[x["fullName"] for x in r["users"]], error="", busy=False,
                        prompt="Password")
        self.bridge.showDialog.emit()

    def choose_user(self, i):
        if self.cur and 0 <= i < len(self.cur["users"]):
            self.cur["user"] = i
            u = self.cur["users"][i]
            self.bridge.set(user=u["name"], fullName=u["fullName"], avatar=u["avatar"], error="")

    # ---- checking the password (libpolkit-agent runs the PAM helper)
    def submit(self, password):
        r = self.cur
        if r is None or self.bridge._d["busy"]:
            return
        if r["session"] is not None:      # a second question from PAM (rare)
            r["session"].response(password)
            self.bridge.set(busy=True, error="")
            return
        try:
            identity = Polkit.UnixUser.new(r["users"][r["user"]]["uid"])
            s = PolkitAgent.Session.new(identity, r["cookie"])
        except Exception as e:  # noqa: BLE001
            log("couldn't start checking:", e)
            self.bridge.set(error="Something went wrong. Try again.")
            return
        r["session"] = s
        r["answered"] = False

        def on_request(session, request, echo_on):
            if not r.get("answered"):
                r["answered"] = True
                session.response(password)
            else:
                # PAM asks something else: show its question
                self.bridge.set(busy=False, prompt=request.strip().rstrip(":") or "Password")

        def on_error(session, text):
            self.bridge.set(error=text.strip())

        def on_completed(session, gained):
            if self.cur is not r:
                return
            r["session"] = None
            if gained:
                r["invocation"].return_value(None)
                self.next()
            else:
                self.bridge.set(busy=False, error="That password isn't right. Try again.", prompt="Password")
                self.bridge.wrongPassword.emit()

        s.connect("request", on_request)
        s.connect("show-error", on_error)
        s.connect("show-info", lambda session, text: None)
        s.connect("completed", on_completed)
        self.bridge.set(busy=True, error="")
        s.initiate()

    def cancel_current(self, by_user):
        r = self.cur
        if r is None:
            return
        if r["session"] is not None:
            try:
                r["session"].cancel()
            except Exception:  # noqa: BLE001
                pass
        r["invocation"].return_dbus_error(CANCELLED, "Cancelled by the user" if by_user else "Cancelled")
        self.cur = None
        self.next()


def main():
    if os.path.exists(os.path.expanduser("~/.config/mos/classic-password-dialog")):
        log("classic (KDE) password dialog chosen")
        sys.exit(3)
    QGuiApplication.setApplicationName("mOS")
    QGuiApplication.setDesktopFileName("mos-polkit-agent")
    QGuiApplication.setQuitOnLastWindowClosed(False)
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon.fromTheme("mos-logo"))
    try:
        agent = Agent(app)
        agent.register()
    except Exception as e:  # noqa: BLE001  (KDE's agent takes over)
        log("couldn't start, KDE's password dialog will be used:", e)
        sys.exit(1)
    # tell systemd we're ready (Type=dbus): own our name on the session bus
    Gio.bus_own_name(Gio.BusType.SESSION, "org.mos.PolkitAgent", Gio.BusNameOwnerFlags.NONE, None, None,
                     lambda *a: (log("lost the session bus name"), app.exit(1)))
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
