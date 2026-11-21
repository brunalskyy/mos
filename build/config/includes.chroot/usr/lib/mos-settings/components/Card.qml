import QtQuick
import QtQuick.Layouts

// Rounded Material card; put rows inside
Rectangle {
    default property alias content: inner.data
    property int pad: 20
    property int gap: 14
    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + pad * 2
    radius: 26
    color: Theme.surfaceHigh
    border.width: Theme.dark ? 0 : 1
    border.color: Qt.rgba(0, 0, 0, 0.05)
    ColumnLayout {
        id: inner
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.pad }
        spacing: parent.gap
    }
}
