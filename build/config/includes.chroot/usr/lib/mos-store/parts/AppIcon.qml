import QtQuick
import QtQuick.Effects
import components

// App icon in your mOS icon shape (circle, squircle or rounded), like on the desktop
Item {
    id: ic
    property string source
    property int size: 64
    implicitWidth: size; implicitHeight: size
    // Without a GPU (software drawing) effects don't show, so draw things plainly instead
    readonly property bool fx: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real r: store.iconShape === "circle" ? size / 2 : store.iconShape === "rounded" ? size * 0.22 : size * 0.3
    Rectangle {
        id: tile
        anchors.fill: parent
        radius: ic.r
        color: Theme.dark ? "#2B2930" : "#FFFFFF"
        border.width: Theme.dark ? 0 : 1
        border.color: Qt.rgba(0, 0, 0, 0.06)
    }
    Image {
        id: img
        anchors.centerIn: parent
        width: ic.size * 0.8; height: width
        source: ic.source !== "" ? ic.source : Theme.ink("apps")
        sourceSize: Qt.size(256, 256)
        fillMode: Image.PreserveAspectFit
        asynchronous: true; smooth: true; mipmap: true
        visible: !ic.fx
    }
    Item {
        id: mask; anchors.fill: img; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: ic.r * 0.8; color: "black" }
    }
    MultiEffect { anchors.fill: img; source: img; maskEnabled: true; maskSource: mask; visible: ic.fx }
}
