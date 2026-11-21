import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components

// Scrolling page with a big title, centred and not too wide
Flickable {
    id: pg
    default property alias content: col.data
    property string title
    property string subtitle
    signal open(string id)
    contentWidth: width
    contentHeight: col.implicitHeight + 150
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    ColumnLayout {
        id: col
        width: Math.min(1040, pg.width - 64)
        x: (pg.width - width) / 2
        y: 36
        spacing: 30
        ColumnLayout {
            spacing: 2
            visible: pg.title !== ""
            Label { visible: text !== ""; text: pg.subtitle.toUpperCase(); color: Theme.textVariant
                    font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1 }
            Label { text: pg.title; color: Theme.textColour; font.pixelSize: 36; font.weight: Font.Bold }
        }
    }
}
