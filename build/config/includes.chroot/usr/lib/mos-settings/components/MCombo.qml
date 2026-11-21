import QtQuick
import QtQuick.Controls.Basic

// Material 3 drop-down: a pill that opens a rounded menu
ComboBox {
    id: c
    implicitHeight: 44
    font.pixelSize: 14
    leftPadding: 18; rightPadding: 40
    contentItem: Label { text: c.displayText; color: Theme.textColour; font: c.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    indicator: Image { x: c.width - 32; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18
                       source: Theme.ink("chevron"); sourceSize: Qt.size(36, 36); rotation: 90 }
    background: Rectangle { radius: height / 2; color: c.hovered ? Theme.secondaryContainer : Theme.surfaceContainer
                            border.width: c.activeFocus ? 2 : 0; border.color: Theme.primary }
    delegate: ItemDelegate {
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : c.width
        height: 40
        contentItem: Label { text: modelData; color: Theme.textColour; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { radius: 12; color: highlighted || c.currentIndex === index ? Theme.secondaryContainer : "transparent" }
        highlighted: c.highlightedIndex === index
    }
    popup: Popup {
        y: c.height + 6
        width: c.width
        implicitHeight: Math.min(contentItem.implicitHeight + 16, 360)
        padding: 8
        contentItem: ListView { clip: true; implicitHeight: contentHeight; model: c.popup.visible ? c.delegateModel : null
                                currentIndex: c.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator {} }
        background: Rectangle { radius: 20; color: Theme.surfaceHigh; border.width: 1; border.color: Theme.outline }
    }
}
