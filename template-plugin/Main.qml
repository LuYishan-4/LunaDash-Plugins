import QtQuick

Item {
    required property var shell
    required property var settings
    required property var context

    Text {
        anchors.centerIn: parent
        text: settings.showLabel ? "LunaDash plugin" : ""
        color: "#ffffff"
    }
}
