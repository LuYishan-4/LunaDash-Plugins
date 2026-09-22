import QtQuick

Item {
    id: root
    required property var shell
    required property var settings
    required property var context

    readonly property string edge: (context.style || {}).edge || "top"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property var clients: ((shell.interaction || {}).clients || shell.state.clients || [])
        .filter(client => client.mapped && !client.minimized &&
                client.workspace === ((shell.interaction || {}).workspace ?? shell.state.workspace))
    readonly property int workspace: Number((shell.interaction || {}).workspace ?? shell.state.workspace)
    property string clockText: ""

    Rectangle {
        anchors.fill: parent
        radius: root.vertical ? 14 : height / 2
        color: "#e622252a"
        border.width: 1
        border.color: "#665f6368"
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 5
        sourceComponent: root.vertical ? verticalPanel : horizontalPanel
    }

    Component {
        id: launcherButton
        Rectangle {
            width: root.vertical ? 34 : 40
            height: 34
            radius: 8
            color: launcherMouse.containsMouse ? "#ff3b82f6" : "#dd30343a"
            Text {
                anchors.centerIn: parent
                text: "K"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.openLauncherFromMouse()
            }
        }
    }

    Component {
        id: workspaceButtons
        Repeater {
            model: settings.showWorkspaceSwitcher
                ? Math.max((root.shell.state.appearance || {}).workspaceCount || 4, root.workspace + 1)
                : 0
            delegate: Rectangle {
                required property int index
                width: 28
                height: 28
                radius: 6
                color: index === root.workspace ? "#ff3b82f6" : "#553f444b"
                Text {
                    anchors.centerIn: parent
                    text: String(parent.index + 1)
                    color: "white"
                    font.pixelSize: 10
                    font.bold: parent.index === root.workspace
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shell.command("workspace", parent.index)
                }
            }
        }
    }

    Component {
        id: taskButton
        Rectangle {
            property var client: ({})
            width: root.vertical ? 36 : (settings.compact ? 38 : settings.showLabels ? 150 : 42)
            height: 32
            radius: 6
            color: client.focused ? "#ff3b82f6" : taskMouse.containsMouse ? "#99515a66" : "#66383d44"
            border.width: client.focused ? 1 : 0
            border.color: "#aaddffff"
            Text {
                anchors.fill: parent
                anchors.margins: 6
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: root.vertical || !settings.showLabels
                    ? Text.AlignHCenter : Text.AlignLeft
                text: root.vertical || !settings.showLabels
                    ? String(client.title || client.appId || "?").slice(0, 1).toUpperCase()
                    : String(client.title || client.appId || "Window")
                color: "white"
                elide: Text.ElideRight
                font.pixelSize: 11
            }
            MouseArea {
                id: taskMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.command("focus", client.id)
            }
        }
    }

    Component {
        id: horizontalPanel
        Row {
            anchors.fill: parent
            spacing: 5

            Loader { sourceComponent: launcherButton }

            Row {
                spacing: 3
                Loader { sourceComponent: workspaceButtons }
            }

            Rectangle { width: 1; height: 22; anchors.verticalCenter: parent.verticalCenter; color: "#445f6368" }

            Row {
                height: parent.height
                spacing: 4
                Repeater {
                    model: root.clients
                    delegate: Loader {
                        required property var modelData
                        sourceComponent: taskButton
                        onLoaded: item.client = modelData
                    }
                }
            }

            Item { width: Math.max(0, parent.width - childrenRect.width - 150); height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.clockText
                color: "white"
                font.pixelSize: 11
            }

            Rectangle {
                width: 34
                height: 30
                radius: 6
                color: settingsMouse.containsMouse ? "#77515a66" : "transparent"
                Text { anchors.centerIn: parent; text: "⚙"; color: "white"; font.pixelSize: 14 }
                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shell.settingsOpen = !root.shell.settingsOpen
                }
            }
        }
    }

    Component {
        id: verticalPanel
        Column {
            anchors.fill: parent
            spacing: 4
            Loader { anchors.horizontalCenter: parent.horizontalCenter; sourceComponent: launcherButton }

            Repeater {
                model: settings.showWorkspaceSwitcher
                    ? Math.max((root.shell.state.appearance || {}).workspaceCount || 4, root.workspace + 1)
                    : 0
                delegate: Rectangle {
                    required property int index
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    width: 30
                    height: 24
                    radius: 6
                    color: index === root.workspace ? "#ff3b82f6" : "#553f444b"
                    Text { anchors.centerIn: parent; text: String(parent.index + 1); color: "white"; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: root.shell.command("workspace", parent.index) }
                }
            }

            Repeater {
                model: root.clients
                delegate: Loader {
                    required property var modelData
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    sourceComponent: taskButton
                    onLoaded: item.client = modelData
                }
            }

            Item { width: 1; height: Math.max(0, parent.height - childrenRect.height - 70) }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.clockText
                color: "white"
                font.pixelSize: 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⚙"
                color: "white"
                font.pixelSize: 15
                MouseArea { anchors.fill: parent; onClicked: root.shell.settingsOpen = !root.shell.settingsOpen }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.clockText = Qt.formatDateTime(
            new Date(), root.shell.state.appearance?.clock24Hour === false ? "h:mm AP" : "HH:mm")
    }
}
