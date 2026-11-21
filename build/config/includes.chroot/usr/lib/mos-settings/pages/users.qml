import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var list: backend.users()
    Connections { target: backend; function onJobDone(key) { if (key === "users") page.list = backend.users() } }

    Card {
        pad: 10; gap: 2
        Repeater {
            model: page.list
            delegate: ListItem {
                required property var modelData
                title: modelData.name
                sub: modelData.me ? "You · " + modelData.login : modelData.login
                iconName: "person"; tone: modelData.me ? Theme.primary : "#7E57C2"
                onClicked: { sheet.user = modelData; nameF.text = modelData.name; sheet.open() }
            }
        }
    }
    RowLayout { PillButton { text: "Add a person"; onClicked: addSheet.open() } }

    Sheet {
        id: sheet
        property var user: ({})
        title: user.name || ""
        MField { id: nameF; Layout.fillWidth: true; placeholderText: "Full name" }
        PillButton { text: "Save name"; tonal: true; onClicked: backend.setFullName(sheet.user.login, nameF.text) }
        Divider {}
        MField { id: newPw; Layout.fillWidth: true; placeholderText: "New password"; echoMode: TextInput.Password }
        MField { id: newPw2; Layout.fillWidth: true; placeholderText: "Type it again"; echoMode: TextInput.Password }
        Hint { visible: newPw.text !== "" && newPw.text !== newPw2.text; text: "The passwords don't match"; color: Theme.error }
        RowLayout {
            Layout.fillWidth: true
            PillButton { visible: !sheet.user.me; text: "Remove"; danger: true; onClicked: { backend.removeUser(sheet.user.login); sheet.close() } }
            Item { Layout.fillWidth: true }
            PillButton { text: "Close"; outlined: true; onClicked: sheet.close() }
            PillButton { text: "Change password"; enabled: newPw.text.length >= 4 && newPw.text === newPw2.text
                         onClicked: { backend.setPassword(sheet.user.login, newPw.text); newPw.text = ""; newPw2.text = ""; sheet.close() } }
        }
    }
    Sheet {
        id: addSheet
        title: "Add a person"
        MField { id: fullN; Layout.fillWidth: true; placeholderText: "Name"; onTextChanged: loginN.text = text.toLowerCase().replace(/[^a-z0-9]/g, "") }
        MField { id: loginN; Layout.fillWidth: true; placeholderText: "Username" }
        MField { id: pw1; Layout.fillWidth: true; placeholderText: "Password"; echoMode: TextInput.Password }
        RowLayout {
            MSwitch { id: admin }
            Label { text: "Can change settings and install apps (admin)"; color: Theme.textColour; Layout.fillWidth: true; wrapMode: Text.WordWrap } }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Cancel"; outlined: true; onClicked: addSheet.close() }
            PillButton { text: "Add"; enabled: fullN.text !== "" && loginN.text !== "" && pw1.text.length >= 4
                         onClicked: { backend.addUser(fullN.text, loginN.text, pw1.text, admin.checked); addSheet.close(); fullN.text = ""; pw1.text = "" } }
        }
    }
}
