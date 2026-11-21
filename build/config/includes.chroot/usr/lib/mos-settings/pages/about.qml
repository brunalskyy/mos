import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var a: backend.about
    Card {
        pad: 28
        RowLayout {
            spacing: 22
            Image { source: "file:///usr/share/icons/hicolor/256x256/apps/mos-logo.png"; Layout.preferredWidth: 96; Layout.preferredHeight: 96; sourceSize: Qt.size(192, 192) }
            ColumnLayout {
                spacing: 4
                Label { text: "mOS"; color: Theme.textColour; font.pixelSize: 32; font.weight: Font.Bold }
                Label { text: page.a.version || "mOS"; color: Theme.textVariant; font.pixelSize: 15 }
                Label { text: "Made by Bruno Woznicki"; color: Theme.textVariant; font.pixelSize: 13 }
            }
        }
    }
    Card {
        ListItem { title: "Computer name"; value: page.a.hostname; chevron: true; onClicked: { nameField.text = page.a.hostname; rename.open() } }
        Divider {}
        Repeater {
            model: [
                { k: "Computer", v: page.a.model },
                { k: "Processor", v: page.a.cpu },
                { k: "Graphics", v: page.a.gpu },
                { k: "Memory", v: page.a.memory },
                { k: "Storage", v: page.a.storage },
                { k: "Linux kernel", v: page.a.kernel },
                { k: "KDE Plasma", v: page.a.plasma }
            ]
            delegate: RowLayout {
                required property var modelData
                visible: modelData.v !== "" && modelData.v !== undefined
                Layout.fillWidth: true
                Layout.leftMargin: 12; Layout.rightMargin: 12
                Label { text: modelData.k; color: Theme.textVariant; font.pixelSize: 15; Layout.preferredWidth: 150 }
                Label { text: modelData.v || ""; color: Theme.textColour; font.pixelSize: 15; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
    }
    RowLayout {
        spacing: 12
        PillButton { text: "Software update"; onClicked: Nav.go("update") }
        PillButton { text: "mOS website"; tonal: true; onClicked: backend.openUrl("https://brunalskyy.github.io/mos/") }
    }
    Hint { text: "mOS is built on Debian and KDE Plasma, which are free and open source." }

    Sheet {
        id: rename
        title: "Rename this computer"
        MField { id: nameField; Layout.fillWidth: true; placeholderText: "e.g. Brunos-MacBook" }
        Hint { text: "Other devices on your network and Bluetooth see this name." }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Cancel"; outlined: true; onClicked: rename.close() }
            PillButton { text: "Save"; onClicked: { backend.setHostname(nameField.text); rename.close() } }
        }
    }
}
