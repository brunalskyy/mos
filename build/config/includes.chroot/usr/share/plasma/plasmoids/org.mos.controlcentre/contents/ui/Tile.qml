import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A Material 3 quick-settings tile: a pill with an icon circle, a title and a subtitle.
// Tap to switch, press and hold (or the arrow) for more.
Rectangle {
    id: tile
    property string title
    property string subtitle
    property string iconName
    property string fallbackIcon: "configure"
    property bool on: false
    property bool more: false
    property color accent
    property color onAccent
    property color off
    property color textColour
    signal toggled()
    signal opened()

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 3.6
    radius: height / 2
    color: on ? accent : off
    Behavior on color { ColorAnimation { duration: 180 } }

    // Liquid: squishes flat when you press it and wobbles back like jelly
    transform: Scale {
        id: squish
        origin.x: tile.width / 2; origin.y: tile.height / 2
        xScale: ma.pressed ? 1.04 : 1
        yScale: ma.pressed ? 0.88 : 1
        Behavior on xScale { SpringAnimation { spring: 5; damping: 0.22; epsilon: 0.002 } }
        Behavior on yScale { SpringAnimation { spring: 5; damping: 0.22; epsilon: 0.002 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing * 2
        Rectangle {
            Layout.preferredWidth: tile.height - Kirigami.Units.smallSpacing * 4
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: tile.on ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(tile.textColour.r, tile.textColour.g, tile.textColour.b, 0.08)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium; height: width
                source: tile.iconName
                fallback: tile.fallbackIcon
                color: tile.on ? tile.onAccent : tile.textColour
                isMask: true
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: tile.title; elide: Text.ElideRight
                color: tile.on ? tile.onAccent : tile.textColour
                font.pixelSize: Kirigami.Units.gridUnit * 0.78; font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.subtitle; elide: Text.ElideRight
                color: tile.on ? tile.onAccent : tile.textColour
                opacity: 0.8
                font.pixelSize: Kirigami.Units.gridUnit * 0.66
            }
        }
        Kirigami.Icon {
            visible: tile.more
            Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Layout.preferredWidth
            source: "go-next"
            color: tile.on ? tile.onAccent : tile.textColour
            isMask: true
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: function (m) {
            if (tile.more && m.x > tile.width - tile.height * 0.8) tile.opened()
            else tile.toggled()
        }
        onPressAndHold: tile.opened()
    }
}
