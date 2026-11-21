import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    readonly property var acc: backend.accountApi
    property string state: ""
    Connections { target: backend.accountApi; function onStatus(s) { page.state = s; if (s === "signed-in") win.toast("Signed in as " + backend.accountApi.name) } }

    // Signed out
    Card {
        visible: !page.acc.signedIn
        pad: 28
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Image { Layout.alignment: Qt.AlignHCenter; source: "file:///usr/share/icons/hicolor/256x256/apps/mos-logo.png"; Layout.preferredWidth: 80; Layout.preferredHeight: 80; sourceSize: Qt.size(160, 160) }
            Label { Layout.alignment: Qt.AlignHCenter; text: "One account for all your mOS stuff"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.DemiBold }
            Hint { horizontalAlignment: Text.AlignHCenter; text: "Your name and picture on mOS, mOS Insider updates, and soon settings sync and app backup." }
        }
        PillButton {
            Layout.alignment: Qt.AlignHCenter
            text: page.state === "waiting" ? "Finish signing in in the browser…" : "Sign in or create an account"
            onClicked: backend.accountApi.signIn()
        }
        Hint { visible: page.state === "waiting"; horizontalAlignment: Text.AlignHCenter
               text: "A sign-in window opened. Sign in with Google, email or phone, then tap Continue." }
        Hint { visible: page.state.indexOf("error:") === 0; color: Theme.error; horizontalAlignment: Text.AlignHCenter
               text: page.state.slice(6) }
    }

    // Signed in
    Card {
        visible: page.acc.signedIn
        pad: 28
        RowLayout {
            spacing: 20
            Rectangle {
                width: 88; height: 88; radius: 44
                gradient: Gradient {
                    GradientStop { position: 0; color: "#FFD36B" }
                    GradientStop { position: 0.5; color: "#FF9A3C" }
                    GradientStop { position: 1; color: "#E8505B" }
                }
                Label { anchors.centerIn: parent; visible: page.acc.photo === ""; text: page.acc.name.charAt(0).toUpperCase(); color: "white"; font.pixelSize: 36; font.weight: Font.Bold }
                RoundImage { anchors.fill: parent; visible: page.acc.photo !== ""; source: page.acc.photo }
            }
            ColumnLayout {
                spacing: 3
                Label { text: page.acc.name; color: Theme.textColour; font.pixelSize: 24; font.weight: Font.DemiBold }
                Label { text: page.acc.email; color: Theme.textVariant }
                Label { visible: page.acc.since !== ""; text: "Member since " + page.acc.since; color: Theme.textVariant; font.pixelSize: 13 }
            }
        }
    }
    Card {
        visible: page.acc.signedIn
        SettingRow { title: "Name and picture on mOS"; sub: "Shown on the lock screen, login screen and Start menu"
                     Label { text: "On"; color: Theme.good; font.weight: Font.DemiBold } }
        Divider {}
        ListItem { title: "mOS Insider"; sub: "Get new features early"; iconName: "update"; tone: "#1E88E5"; onClicked: { Nav.top("general"); Nav.go("update") } }
        ListItem { title: "Manage your account"; sub: "Name, password, delete account"; iconName: "account"; tone: "#E8833A"; onClicked: backend.accountApi.manage() }
    }
    RowLayout {
        visible: page.acc.signedIn
        PillButton { text: "Refresh"; tonal: true; onClicked: backend.accountApi.refresh() }
        PillButton { text: "Sign out"; outlined: true; onClicked: backend.accountApi.signOut() }
    }
}
