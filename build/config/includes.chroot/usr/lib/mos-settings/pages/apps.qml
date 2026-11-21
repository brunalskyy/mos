import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var list: []
    property var defaults: []
    property string filter: ""
    Component.onCompleted: Qt.callLater(function () { page.list = backend.apps(); page.defaults = backend.defaultApps() })
    Connections { target: backend; function onJobDone(key) { if (key === "apps") page.list = backend.apps() }
                  function onChanged() { page.defaults = backend.defaultApps() } }

    SectionTitle { text: "Default apps"; Layout.topMargin: 0 }
    Card {
        Repeater {
            model: page.defaults
            delegate: SettingRow {
                required property var modelData
                title: modelData.label
                ComboBox {
                    id: cb
                    implicitWidth: 240
                    model: modelData.choices
                    textRole: "name"
                    enabled: modelData.choices.length > 0
                    currentIndex: { for (var i = 0; i < modelData.choices.length; i++) if (modelData.choices[i].id === modelData.current) return i; return -1 }
                    displayText: currentIndex >= 0 ? currentText : (modelData.choices.length ? "Choose…" : "None installed")
                    onActivated: function (i) { backend.setDefaultApp(modelData.kind, modelData.choices[i].id) }
                    background: Rectangle { radius: 22; color: Theme.surfaceContainer; border.width: 1; border.color: Theme.outline }
                    contentItem: Label { leftPadding: 16; text: cb.displayText; color: Theme.onSurface; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                }
            }
        }
    }

    RowLayout {
        SectionTitle { text: "Installed apps (" + page.list.length + ")" }
        MField { placeholderText: "Search apps"; implicitWidth: 220; onTextChanged: page.filter = text.toLowerCase() }
    }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: page.list.filter(function (a) { return page.filter === "" || a.name.toLowerCase().indexOf(page.filter) !== -1 })
            delegate: ListItem {
                required property var modelData
                title: modelData.name
                sub: modelData.removable ? "From the mOS Store" : "Built into mOS"
                image: "image://icon/" + modelData.icon
                chevron: false
                PillButton { text: "Open"; tonal: true; onClicked: backend.openApp(modelData.id) }
                PillButton { visible: modelData.removable; text: "Uninstall"; outlined: true; onClicked: { confirm.app = modelData; confirm.open() } }
            }
        }
    }
    Sheet {
        id: confirm
        property var app: ({})
        title: "Uninstall " + (app.name || "") + "?"
        Hint { text: "The app and its data on this computer will be removed. You can install it again from the mOS Store." }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Cancel"; outlined: true; onClicked: confirm.close() }
            PillButton { text: "Uninstall"; danger: true; onClicked: { backend.uninstallApp(confirm.app.flatpak); confirm.close() } }
        }
    }
}
