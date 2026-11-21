import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ListView {
    id: list
    property color card
    property color textColour
    property color accent
    clip: true
    spacing: Kirigami.Units.smallSpacing * 2
    boundsBehavior: Flickable.StopAtBounds

    add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0.6; to: 1; duration: 220; easing.type: Easing.OutBack } }
    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 160 } }
    displaced: Transition { NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic } }

    delegate: Rectangle {
        id: item
        required property int index
        required property var model
        width: ListView.view.width
        implicitHeight: body.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.gridUnit * 1.1
        color: list.card
        RowLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: Layout.preferredWidth
                source: item.model.applicationIconName || item.model.iconName || "preferences-desktop-notification"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: item.model.applicationName || ""
                        elide: Text.ElideRight
                        color: list.textColour; opacity: 0.7
                        font.pixelSize: Kirigami.Units.gridUnit * 0.66
                    }
                    Text {
                        text: item.model.created ? Qt.formatTime(item.model.created, Qt.locale().timeFormat(Locale.ShortFormat).replace(":ss", "")) : ""
                        color: list.textColour; opacity: 0.6
                        font.pixelSize: Kirigami.Units.gridUnit * 0.62
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: item.model.summary || ""
                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    color: list.textColour
                    font.pixelSize: Kirigami.Units.gridUnit * 0.78; font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: item.model.body || ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                    color: list.textColour; opacity: 0.85
                    font.pixelSize: Kirigami.Units.gridUnit * 0.72
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: list.model.open(item.index)
        }
        // close button
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.3; height: width; radius: width / 2
            anchors.top: parent.top; anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing * 1.5
            color: list.textColour
            opacity: hov.hovered ? 0.18 : 0.08
            HoverHandler { id: hov }
            Kirigami.Icon { anchors.centerIn: parent; width: Kirigami.Units.iconSizes.small * 0.75; height: width
                            source: "window-close"; color: list.textColour; isMask: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: list.model.closeAt(item.index) }
        }
    }
}
