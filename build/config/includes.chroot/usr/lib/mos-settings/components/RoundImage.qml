import QtQuick
import QtQuick.Effects

// A picture cut into a circle (profile pictures)
Item {
    property alias source: img.source
    Image { id: img; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; visible: false; smooth: true; asynchronous: true }
    Item {
        id: mask; anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: width / 2; color: "black" }
    }
    MultiEffect { anchors.fill: parent; source: img; maskEnabled: true; maskSource: mask }
}
