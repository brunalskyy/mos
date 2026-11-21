import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    spacing: 18
    Card {
        SectionTitle { text: "Wallpaper"; Layout.topMargin: 0 }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 14; rowSpacing: 14
            Repeater {
                model: backend.wallpapers
                delegate: ColumnLayout {
                    required property var modelData
                    readonly property bool chosen: backend.wallpaper === modelData.image
                    spacing: 8
                    Layout.fillWidth: true
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: width * 10 / 16
                        radius: 20
                        color: Theme.surfaceContainer
                        clip: true
                        scale: wpMa.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Image { anchors.fill: parent; source: modelData.preview; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 480 }
                        Rectangle { anchors.fill: parent; radius: 20; color: "transparent"; border.width: chosen ? 4 : 0; border.color: Theme.primary }
                        Rectangle {
                            visible: chosen
                            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                            width: 28; height: 28; radius: 14; color: Theme.primary
                            Image { anchors.centerIn: parent; source: Theme.icon("check"); width: 18; height: 18; sourceSize: Qt.size(36, 36) }
                        }
                        MouseArea { id: wpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.setWallpaper(modelData.image) }
                    }
                    Label { text: modelData.name; color: Theme.textVariant; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }
    }
    Card {
        SectionTitle { text: "Appearance"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: "light", label: "Light" }, { value: "dark", label: "Dark" },
                      { value: "auto", label: "Auto" }, { value: "custom", label: "Schedule" }]
            current: backend.themeMode.mode
            onSelected: function (v) { backend.setThemeMode({ mode: v }) }
        }
        Hint {
            text: backend.themeMode.mode === "auto" ? "Dark from sunset (" + backend.themeMode.sunset + ") to sunrise (" + backend.themeMode.sunrise + ")."
                : backend.themeMode.mode === "custom" ? "Dark between the times you pick."
                : backend.themeMode.mode === "dark" ? "Dark backgrounds with light text everywhere." : "Light backgrounds everywhere."
        }
        RowLayout {
            visible: backend.themeMode.mode === "custom"
            spacing: 10
            Label { text: "Dark from"; color: Theme.textColour }
            MField { implicitWidth: 100; text: backend.themeMode.darkAt; inputMask: "99:99"
                     onEditingFinished: backend.setThemeMode({ darkAt: text }) }
            Label { text: "until"; color: Theme.textColour }
            MField { implicitWidth: 100; text: backend.themeMode.lightAt; inputMask: "99:99"
                     onEditingFinished: backend.setThemeMode({ lightAt: text }) }
        }
        Divider {}
        SettingRow {
            title: "Colours from wallpaper"
            sub: "Buttons, highlights and widgets match your wallpaper (Material You)"
            MSwitch { checked: backend.accentFromWallpaper; onToggled: function (v) { backend.setAccentFromWallpaper(v) } }
        }
        ColumnLayout {
            visible: !backend.accentFromWallpaper
            Layout.fillWidth: true
            Hint { text: "Pick your colour" }
            Flow {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: ["#E8833A", "#E8505B", "#D9488B", "#8E5CF6", "#5C6BC0", "#2F7BEA", "#00ACC1", "#00897B", "#43A047", "#C0A000", "#6D4C41", "#607D8B"]
                    delegate: Rectangle {
                        required property string modelData
                        width: 44; height: 44; radius: 22; color: modelData
                        border.width: backend.accent.toUpperCase() === modelData.toUpperCase() ? 4 : 0
                        border.color: Theme.surfaceHigh
                        Rectangle { anchors.fill: parent; anchors.margins: -3; radius: width / 2; color: "transparent"; border.width: backend.accent.toUpperCase() === modelData.toUpperCase() ? 2 : 0; border.color: modelData }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.setAccent(modelData) }
                    }
                }
            }
        }
        Divider {}
        SettingRow {
            title: "Your colours"
            sub: backend.accentFromWallpaper ? "Picked from your wallpaper" : "Your chosen colour"
            Row {
                spacing: 6
                Repeater {
                    model: [Theme.primary, Theme.primaryContainer, Theme.secondaryContainer, Theme.surfaceContainer]
                    delegate: Rectangle { required property color modelData; width: 30; height: 30; radius: 15; color: modelData; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.08) }
                }
            }
        }
    }
    Card {
        SectionTitle { text: "Effects"; Layout.topMargin: 0 }
        SettingRow { title: "Material buttons in apps"; sub: "Round buttons, fields and menus in your colours inside apps like Files and Terminal"
                     MSwitch { checked: backend.appStyle; onToggled: function (v) { backend.setAppStyle(v) } } }
        SettingRow { title: "Liquid glass"; sub: "See-through frosted taskbar, menus and pop-ups"
                     MSwitch { checked: backend.effects.glass; onToggled: function (v) { backend.setEffect("glass", v) } } }
        SettingRow { title: "Zoom windows open and closed"
                     MSwitch { checked: backend.effects.zoom; onToggled: function (v) { backend.setEffect("zoom", v) } } }
        SettingRow { title: "Genie when minimising"; sub: "Like a Mac"
                     MSwitch { checked: backend.effects.genie; onToggled: function (v) { backend.setEffect("genie", v) } } }
        SettingRow { title: "Wobbly windows"; sub: "Just for fun"
                     MSwitch { checked: backend.effects.wobbly; onToggled: function (v) { backend.setEffect("wobbly", v) } } }
    }
    Card {
        ListItem { title: "Icon shape"; sub: "Circle, squircle or rounded square"; iconName: "shapes"; tone: "#D9488B"; onClicked: Nav.top("icons") }
        ListItem { title: "Taskbar"; sub: "Style, floating, size and position"; iconName: "taskbar"; tone: "#5C6BC0"; onClicked: Nav.top("taskbar") }
    }
}
