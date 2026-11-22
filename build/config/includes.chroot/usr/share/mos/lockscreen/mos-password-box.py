#!/usr/bin/env python3
"""mOS: restyle the password box on the lock screen (MainBlock.qml) and the
sign-in screen (SDDM Login.qml), Windows 7 style: one clean field in the mOS
colours with the arrow button joined onto its right, in your accent colour.
Usage: mos-password-box.py <file.qml>. Leaves the file alone if it can't match.
SPDX-FileCopyrightText: 2026 Bruno Woznicki
SPDX-License-Identifier: GPL-3.0-or-later
"""
import re
import sys

path = sys.argv[1]
s = open(path).read()
if "mOS password box" in s:
    sys.exit(0)
orig = s


def sub(pattern, repl):
    global s
    s2, n = re.subn(pattern, repl, s, count=1, flags=re.S)
    if n == 0:
        print("W: password box: no match for %r in %s; keeping KDE's" % (pattern[:50], path), file=sys.stderr)
        sys.exit(0)
    s = s2


# The row: narrower, centred, field and button touching
sub(r"RowLayout \{\n(\s*)Layout\.fillWidth: true\n(\s*\n)?(\s*)PlasmaExtras\.PasswordField \{\n(\s*)id: passwordBox\n",
    r"""RowLayout {
\1// mOS password box
\1Layout.fillWidth: true
\1Layout.maximumWidth: Kirigami.Units.gridUnit * 15
\1Layout.alignment: Qt.AlignHCenter
\1spacing: 0

\3PlasmaExtras.PasswordField {
\4id: passwordBox
\4Kirigami.Theme.colorSet: Kirigami.Theme.View
\4Kirigami.Theme.inherit: false
\4Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
\4leftPadding: Kirigami.Units.gridUnit * 0.8
\4font.family: "Inter"
\4background: Item {
\4    Rectangle {
\4        anchors.fill: parent
\4        radius: Kirigami.Units.gridUnit * 0.45
\4        color: Kirigami.Theme.backgroundColor
\4        opacity: 0.94
\4    }
\4    Rectangle {
\4        anchors.right: parent.right
\4        width: Kirigami.Units.gridUnit
\4        height: parent.height
\4        color: Kirigami.Theme.backgroundColor
\4        opacity: 0.94
\4    }
\4    Rectangle {
\4        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
\4        anchors.leftMargin: Kirigami.Units.gridUnit * 0.45
\4        height: 2
\4        color: Kirigami.Theme.highlightColor
\4        opacity: passwordBox.activeFocus ? 1 : 0
\4    }
\4}
""")

# The arrow button: accent colour, square on the left so it joins the field
sub(r"PlasmaComponents3\.Button \{\n(\s*)id: loginButton\n(.*?)\n\s*Layout\.preferredHeight: passwordBox\.implicitHeight\n",
    r"""PlasmaComponents3.Button {
\1id: loginButton
\2
\1Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
\1background: Item {
\1    opacity: loginButton.pressed ? 0.78 : loginButton.hovered ? 0.9 : 1
\1    Rectangle {
\1        anchors.fill: parent
\1        radius: Kirigami.Units.gridUnit * 0.45
\1        color: Kirigami.Theme.highlightColor
\1    }
\1    Rectangle {
\1        anchors.left: parent.left
\1        width: Kirigami.Units.gridUnit
\1        height: parent.height
\1        color: Kirigami.Theme.highlightColor
\1    }
\1}
\1contentItem: Item {
\1    implicitWidth: mosLoginText.text.length > 0 ? mosLoginText.implicitWidth + Kirigami.Units.gridUnit * 1.6 : Kirigami.Units.gridUnit * 2.2
\1    implicitHeight: Kirigami.Units.gridUnit * 2.2
\1    Kirigami.Icon {
\1        anchors.centerIn: parent
\1        width: Kirigami.Units.iconSizes.smallMedium; height: width
\1        visible: loginButton.text.length === 0
\1        source: loginButton.icon.name || "go-next"
\1        color: Kirigami.Theme.highlightedTextColor
\1        isMask: true
\1    }
\1    Text {
\1        id: mosLoginText
\1        anchors.centerIn: parent
\1        text: loginButton.text
\1        color: Kirigami.Theme.highlightedTextColor
\1        font.family: "Inter"; font.weight: Font.DemiBold
\1    }
\1}
""")

open(path, "w").write(s)
print("I: mOS password box in " + path)
