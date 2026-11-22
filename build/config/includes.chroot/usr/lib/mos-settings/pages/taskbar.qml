import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var t: backend.taskbar
    function set(k, v) { var o = {}; o[k] = v; backend.setTaskbar(o) }

    // Live preview of the taskbar
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 220
        radius: 26
        clip: true
        gradient: Gradient {
            GradientStop { position: 0; color: "#3A1A55" }
            GradientStop { position: 0.6; color: "#C4513F" }
            GradientStop { position: 1; color: "#FFB24A" }
        }
        readonly property bool vertical: page.t.position === "left" || page.t.position === "right"
        readonly property real thick: page.t.size === "small" ? 30 : page.t.size === "large" ? 46 : 38
        readonly property real gap: page.t.floating || page.t.style === "dock" ? 10 : 0
        Rectangle {
            id: bar
            readonly property real thick: parent.thick
            readonly property real gap: parent.gap
            readonly property int n: 6
            readonly property real cell: thick * 0.72 + [2, 6, 12, 18][Math.max(0, Math.min(3, page.t.spacing))]
            width: parent.vertical ? thick : (page.t.style === "dock" ? n * cell + 24 : parent.width - gap * 2)
            height: parent.vertical ? (page.t.style === "dock" ? n * cell + 24 : parent.height - gap * 2) : thick
            x: page.t.position === "left" ? gap : page.t.position === "right" ? parent.width - width - gap : (parent.width - width) / 2
            y: page.t.position === "top" ? gap : page.t.position === "bottom" ? parent.height - height - gap : (parent.height - height) / 2
            radius: page.t.floating || page.t.style === "dock" ? thick / 2 : 0
            color: Qt.rgba(1, 1, 1, 0.78)
            opacity: page.t.autohide ? 0.55 : 1
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 220 } }
            Grid {
                anchors.centerIn: page.t.style === "windows" ? undefined : parent
                x: page.t.style === "windows" ? 10 : 0
                y: page.t.style === "windows" ? (parent.height - height) / 2 : 0
                columns: parent.parent.vertical ? 1 : bar.n
                spacing: [2, 6, 12, 18][Math.max(0, Math.min(3, page.t.spacing))]
                Repeater {
                    model: ["#7C5CFF", "#2F7BEA", "#3D8BF2", "#9B6CFF", "#8D939B", "#2A2930"]
                    delegate: Rectangle { required property string modelData; width: bar.thick * 0.72; height: width; radius: width / 2; color: modelData }
                }
            }
        }
    }

    Card {
        SectionTitle { text: "Style"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: "windows", label: "Windows" }, { value: "centred", label: "Centred" }, { value: "dock", label: "Dock" }]
            current: page.t.style
            onSelected: function (v) { page.set("style", v) }
        }
        Hint { text: page.t.style === "windows" ? "Start button and apps on the left, like Windows 10."
                   : page.t.style === "centred" ? "Apps in the middle, like Windows 11."
                   : "Only as wide as your apps, floating in the middle, like a Mac." }
    }
    Card {
        SettingRow {
            title: "Floating"
            sub: "A gap around the taskbar and round ends"
            MSwitch { enabled: page.t.style !== "dock"; checked: page.t.floating || page.t.style === "dock"; onToggled: function (v) { page.set("floating", v) } }
        }
        Divider {}
        SettingRow {
            title: "Show app names"
            sub: page.t.style === "dock" ? "The dock shows icons only" : "Open apps show their name next to the icon, like Windows 10"
            MSwitch { enabled: page.t.style !== "dock"; checked: page.t.labels !== false && page.t.style !== "dock"; onToggled: function (v) { page.set("labels", v) } }
        }
        Divider {}
        SettingRow {
            title: "Hide automatically"
            sub: "Shows when you move the pointer to the edge"
            MSwitch { checked: page.t.autohide; onToggled: function (v) { page.set("autohide", v) } }
        }
    }
    Card {
        SectionTitle { text: "Position"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }, { value: "top", label: "Top" }]
            current: page.t.position
            onSelected: function (v) { page.set("position", v) }
        }
        SectionTitle { text: "Size" }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: "small", label: "Small" }, { value: "medium", label: "Medium" }, { value: "large", label: "Large" }]
            current: page.t.size
            onSelected: function (v) { page.set("size", v) }
        }
        SectionTitle { text: "Space between apps" }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: 0, label: "Tight" }, { value: 1, label: "Normal" }, { value: 2, label: "Spread out" }, { value: 3, label: "Extra" }]
            current: page.t.spacing
            onSelected: function (v) { page.set("spacing", v) }
        }
    }
}
