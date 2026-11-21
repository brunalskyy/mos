import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    spacing: 18
    Card {
        pad: 10; gap: 2
        Repeater {
            model: win.generalPages.slice(0, 4)
            delegate: ListItem { required property var modelData; title: modelData.title; sub: modelData.sub; iconName: modelData.icon; tone: modelData.tone; onClicked: Nav.go(modelData.id) }
        }
    }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: win.generalPages.slice(4, 9)
            delegate: ListItem { required property var modelData; title: modelData.title; sub: modelData.sub; iconName: modelData.icon; tone: modelData.tone; onClicked: Nav.go(modelData.id) }
        }
    }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: win.generalPages.slice(9)
            delegate: ListItem { required property var modelData; title: modelData.title; sub: modelData.sub; iconName: modelData.icon; tone: modelData.tone; onClicked: Nav.go(modelData.id) }
        }
    }
}
