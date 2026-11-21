import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var k: backend.keyboard()
    Connections { target: backend; function onChanged() { page.k = backend.keyboard() } }
    function codes() { return page.k.layouts.map(function (x) { return x.code }) }

    SectionTitle { text: "Keyboard layouts"; Layout.topMargin: 0 }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: page.k.layouts
            delegate: ListItem {
                required property var modelData
                required property int index
                title: modelData.label
                sub: index === 0 ? "Main layout" : ""
                iconName: "keyboard"; tone: index === 0 ? Theme.primary : "#90A4AE"
                chevron: false
                Rectangle {
                    visible: page.k.layouts.length > 1
                    width: 40; height: 40; radius: 20; color: rmk.containsMouse ? Theme.alpha(Theme.onSurface, 0.08) : "transparent"
                    Image { anchors.centerIn: parent; source: Theme.ink("trash"); width: 20; height: 20; sourceSize: Qt.size(40, 40) }
                    MouseArea { id: rmk; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: backend.setLayouts(page.codes().filter(function (c) { return c !== modelData.code })) }
                }
            }
        }
    }
    RowLayout {
        PillButton { text: "Add a layout"; onClicked: add.open() }
    }
    Hint { text: "With more than one layout, switch with Win + Alt + K." }
    Sheet {
        id: add
        title: "Add a layout"
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            model: page.k.choices
            delegate: ListItem {
                required property var modelData
                width: ListView.view.width
                title: modelData.label; chevron: false
                onClicked: { backend.setLayouts(page.codes().concat([modelData.code])); add.close() }
            }
        }
    }
}
