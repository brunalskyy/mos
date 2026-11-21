import QtQuick

// A white symbol on a coloured circle (like Pixel settings)
Rectangle {
    property string name: "info"
    property color tone: "#757575"
    property int size: 36
    width: size; height: size; radius: size / 2
    color: tone
    Image {
        anchors.centerIn: parent
        source: Theme.icon(parent.name)
        width: parent.size * 0.56; height: width
        sourceSize: Qt.size(width * 2, height * 2)
    }
}
