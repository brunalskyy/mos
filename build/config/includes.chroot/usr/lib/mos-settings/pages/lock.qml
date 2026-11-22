import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var l: backend.lockScreen()
    Connections { target: backend; function onChanged() { page.l = backend.lockScreen() } }

    Card {
        SettingRow {
            title: "Lock automatically"
            sub: "Lock mOS when you're away"
            MSwitch { checked: page.l.autolock; onToggled: function (v) { backend.setLock("Autolock", v) } }
        }
        ColumnLayout {
            visible: page.l.autolock
            Layout.fillWidth: true
            Hint { text: "Lock after" }
            Segmented {
                Layout.fillWidth: true
                options: [{ value: 1, label: "1 min" }, { value: 2, label: "2 min" }, { value: 5, label: "5 min" }, { value: 10, label: "10 min" }, { value: 30, label: "30 min" }]
                current: page.l.timeout
                onSelected: function (v) { backend.setLock("Timeout", v) }
            }
        }
        Divider {}
        SettingRow {
            title: "Lock after sleep"
            sub: "Ask for your password when the computer wakes up"
            MSwitch { checked: page.l.lockOnResume; onToggled: function (v) { backend.setLock("LockOnResume", v) } }
        }
    }
    Card {
        SettingRow {
            title: "Big clock"
            sub: "The big time and date you see before you sign in"
            MSwitch { checked: page.l.showClock; onToggled: function (v) { backend.setLock("alwaysShowClock", v) } }
        }
        Divider {}
        SettingRow {
            title: "Music controls"
            sub: "Play, pause and skip on the lock screen"
            MSwitch { checked: page.l.mediaControls; onToggled: function (v) { backend.setLock("showMediaControls", v) } }
        }
    }
    // Lock screen picture: the same as the desktop, or its own
    Card {
        SectionTitle { text: "Lock screen picture"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: "same", label: "Same as desktop" }, { value: "own", label: "Its own picture" }]
            current: backend.lockWallpaper === "" ? "same" : "own"
            onSelected: function (v) {
                if (v === "same") backend.setLockWallpaper("")
                else if (backend.lockWallpaper === "") backend.setLockWallpaper(backend.wallpapers.length ? backend.wallpapers[0].image : "")
            }
        }
        GridLayout {
            visible: backend.lockWallpaper !== ""
            Layout.fillWidth: true
            Layout.topMargin: 6
            columns: 3
            columnSpacing: 12; rowSpacing: 12
            Repeater {
                model: backend.wallpapers
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool chosen: backend.lockWallpaper === modelData.image
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 10 / 16
                    radius: 16
                    color: Theme.surfaceContainer
                    clip: true
                    Image { anchors.fill: parent; source: modelData.preview; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 360 }
                    Rectangle { anchors.fill: parent; radius: 16; color: "transparent"; border.width: chosen ? 4 : 0; border.color: Theme.primary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.setLockWallpaper(modelData.image) }
                }
            }
        }
        RowLayout {
            visible: backend.lockWallpaper !== ""
            PillButton { tonal: true; text: "Choose a picture…"; onClicked: picker.open() }
            Label {
                Layout.fillWidth: true
                visible: backend.lockWallpaper !== "" && backend.lockWallpaper.indexOf("/usr/share/wallpapers/") !== 0
                text: backend.lockWallpaper.split("/").pop()
                elide: Text.ElideMiddle
                color: Theme.textVariant; font.pixelSize: 13
            }
        }
        Divider {}
        SettingRow {
            title: "Use on the sign-in screen too"
            sub: "The screen you see when mOS starts. Changing it asks for your password"
            MSwitch { checked: backend.loginFollowsLock; onToggled: function (v) { backend.setLoginFollowsLock(v) } }
        }
    }
    FileDialog {
        id: picker
        title: "Choose a lock screen picture"
        nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: backend.setLockWallpaper(selectedFile.toString())
    }
    RowLayout {
        PillButton { text: "Lock now"; onClicked: backend.lockNow() }
        PillButton { text: "Desktop wallpaper"; tonal: true; onClicked: Nav.top("style") }
    }
    Hint { text: "Tip: press Win + L (⌘ + L on a Mac keyboard) to lock any time." }
}
