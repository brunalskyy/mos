import QtQuick
import QtQuick.Controls.Basic

// Reviewer picture: their initials on a colour picked from their name
Rectangle {
    id: av
    property string name
    property int size: 40
    width: size; height: size; radius: size / 2
    readonly property var tones: ["#E8833A", "#2F7BEA", "#43A047", "#D9488B", "#7C5CFF", "#00897B", "#F4511E", "#5C6BC0"]
    color: {
        var h = 0
        for (var i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 9973
        return tones[h % tones.length]
    }
    Label {
        anchors.centerIn: parent
        text: {
            var p = av.name.trim().split(/\s+/)
            return ((p[0] || "?")[0] + (p.length > 1 ? p[p.length - 1][0] : "")).toUpperCase()
        }
        color: "white"
        font.pixelSize: av.size * 0.38; font.weight: Font.Bold
    }
}
