import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var l: backend.language()
    Connections { target: backend; function onChanged() { page.l = backend.language() } }
    Hint { text: "The language for mOS and your apps, and how dates, times and numbers look." }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: page.l.choices
            delegate: ListItem {
                required property var modelData
                title: modelData.label
                iconName: "globe"; tone: modelData.code === page.l.current ? Theme.primary : "#90A4AE"
                selected: modelData.code === page.l.current
                chevron: false
                onClicked: backend.setLanguage(modelData.code)
            }
        }
    }
    Hint { text: "After changing the language, sign out and back in." }
}
