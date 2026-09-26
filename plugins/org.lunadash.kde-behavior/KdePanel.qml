import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var shell
    required property var settings
    required property var context

    readonly property var style: context.style || ({})
    readonly property string edge: ["top", "bottom", "left", "right"].includes(style.edge)
        ? style.edge : "top"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property int workspace: Number((shell.interaction || {}).workspace ?? shell.state.workspace ?? 0)
    readonly property var allClients: ((shell.interaction || {}).clients || shell.state.clients || [])
        .filter(client => client.mapped && !client.minimized)
    readonly property var clients: allClients.filter(client => client.workspace === workspace)
    readonly property int workspaceCount: Math.max(
        Number((shell.state.appearance || {}).workspaceCount || 4), workspace + 1)
    readonly property var workspaceIndices: {
        const result = []
        for (let index = 0; index < workspaceCount; ++index) {
            const occupied = allClients.some(client => Number(client.workspace) === index)
            if (!(settings.occupiedWorkspacesOnly ?? true) || occupied || index === workspace)
                result.push(index)
        }
        return result
    }
    readonly property var audio: shell.state.audio || ({})
    readonly property var network: shell.state.network || ({})
    readonly property color accent: style.accent && style.accent !== "inherit"
        ? style.accent : "#69a7ff"
    readonly property color foreground: style.foreground && style.foreground !== "inherit"
        ? style.foreground : "#eef5ff"
    readonly property real capsuleOpacity: Math.max(0.45, Math.min(1, Number(settings.panelOpacity ?? 0.88)))
    readonly property int iconSize: Math.max(16, Math.min(32, Number(settings.iconSize ?? 22)))
    property string clockText: ""
    property string dateText: ""
    property bool pluginReady: true

    function iconSource(value) {
        const supplied = String(value || "")
        if (/^(file:|image:|qrc:|data:)/.test(supplied))
            return supplied
        if (supplied.startsWith("/"))
            return "file://" + supplied
        const themed = String(Quickshell.iconPath(supplied) || "")
        return themed.includes("qs-blackhole") ? "" : themed
    }

    function appIcon(client) {
        let source = iconSource(client.icon)
        if (source.length)
            return source
        source = iconSource(client.appId)
        return source
    }

    function capsuleColor(alpha) {
        return Qt.rgba(0.055, 0.075, 0.12, alpha * capsuleOpacity)
    }

    function borderColor(alpha) {
        return Qt.rgba(accent.r, accent.g, accent.b, alpha)
    }

    function trayIcon(item) {
        let source = iconSource(item.icon)
        if (source.length)
            return source
        return iconSource(item.id)
    }

    function stepWorkspace(delta) {
        if (!(settings.workspaceScroll ?? true) || workspaceCount < 2)
            return
        const next = (workspace + delta + workspaceCount) % workspaceCount
        shell.command("workspace", next)
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            root.clockText = Qt.formatDateTime(
                now, root.shell.state.appearance?.clock24Hour === false ? "h:mm AP" : "HH:mm")
            root.dateText = Qt.formatDateTime(now, "ddd MM.dd")
        }
    }

    Component {
        id: capsuleBackground
        Rectangle {
            radius: root.vertical ? Math.min(width, 16) : height / 2
            color: root.capsuleColor(0.96)
            border.width: 1
            border.color: root.borderColor(0.30)
        }
    }

    Component {
        id: workspaceChip
        Item {
            required property int index
            readonly property bool active: index === root.workspace
            width: root.vertical ? 30 : (active ? 31 : 20)
            height: root.vertical ? (active ? 29 : 20) : 30
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: root.vertical ? parent.height : (parent.active ? 10 : 7)
                radius: height / 2
                color: parent.active ? root.accent
                                     : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.17)
                border.width: parent.active ? 0 : 1
                border.color: root.borderColor(0.22)
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.command("workspace", parent.index)
            }
        }
    }

    Component {
        id: appButton
        Item {
            property var client: ({})
            width: root.vertical ? 38 : (settings.showLabels && !settings.compact ? 132 : 38)
            height: 36
            readonly property string source: root.appIcon(client)
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: client.focused
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
                    : appMouse.containsMouse
                        ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
                        : "transparent"
                border.width: client.focused ? 1 : 0
                border.color: root.borderColor(0.46)
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Row {
                anchors.centerIn: parent
                spacing: 7
                Image {
                    width: root.iconSize
                    height: root.iconSize
                    source: parent.parent.source
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: source.toString().length > 0 && status === Image.Ready
                }
                Text {
                    visible: settings.showLabels && !settings.compact && !root.vertical
                    width: 88
                    text: String(parent.parent.client.title || parent.parent.client.appId || "Window")
                    color: root.foreground
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 11
                }
            }
            Text {
                anchors.centerIn: parent
                visible: parent.source.length === 0
                text: String(client.title || client.appId || "?").slice(0, 1).toUpperCase()
                color: root.foreground
                font.bold: true
                font.pixelSize: 13
            }
            Rectangle {
                visible: client.focused
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: 14
                height: 2
                radius: 1
                color: root.accent
            }
            MouseArea {
                id: appMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton)
                        root.shell.command("close", client.id)
                    else
                        root.shell.command("activate-window", client.id)
                }
            }
            ToolTip.visible: appMouse.containsMouse
            ToolTip.delay: 400
            ToolTip.text: client.title || client.appId || "Window"
        }
    }

    Component {
        id: launcherButton
        Item {
            width: 38
            height: 36
            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 10
                color: launcherMouse.containsMouse || root.shell.launcherOpen
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30)
                    : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                border.width: 1
                border.color: root.borderColor(0.55)
            }
            Text {
                anchors.centerIn: parent
                text: "◆"
                color: root.accent
                font.pixelSize: 15
            }
            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.openLauncherFromMouse()
            }
            ToolTip.visible: launcherMouse.containsMouse
            ToolTip.delay: 400
            ToolTip.text: "Applications"
        }
    }

    Component {
        id: dashboardButton
        Item {
            width: settings.showDashboard ?? true ? 34 : 0
            height: 34
            visible: settings.showDashboard ?? true
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: dashboardMouse.containsMouse || root.shell.overviewOpen
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                    : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: "◈"
                color: root.shell.overviewOpen ? root.accent : root.foreground
                font.pixelSize: 14
            }
            MouseArea {
                id: dashboardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.setAppearance({overview: !root.shell.overviewOpen})
            }
            ToolTip.visible: dashboardMouse.containsMouse
            ToolTip.delay: 400
            ToolTip.text: "Dashboard"
        }
    }

    Component {
        id: settingsButton
        Item {
            width: 34
            height: 34
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: settingsMouse.containsMouse || root.shell.settingsOpen
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                    : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: "⚙"
                color: root.foreground
                font.pixelSize: 15
            }
            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shell.settingsOpen = !root.shell.settingsOpen
            }
            ToolTip.visible: settingsMouse.containsMouse
            ToolTip.delay: 400
            ToolTip.text: "Settings"
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.vertical ? verticalPanel : horizontalPanel
    }

    Component {
        id: horizontalPanel
        Item {
            anchors.fill: parent

            Item {
                id: workspacesCapsule
                visible: settings.showWorkspaceSwitcher
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(34, parent.height - 6)
                width: workspaceRow.implicitWidth + 16
                Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: root.workspaceIndices
                        delegate: Loader {
                            required property int modelData
                            sourceComponent: workspaceChip
                            onLoaded: item.index = modelData
                        }
                    }
                    Rectangle {
                        width: 1
                        height: 17
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.borderColor(0.20)
                    }
                    Item {
                        visible: settings.showPowerButton ?? true
                        width: visible ? 28 : 0
                        height: 28
                        Text { anchors.centerIn: parent; text: "⏻"; color: "#ff8c9d"; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shell.logoutOpen = !root.shell.logoutOpen
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => root.stepWorkspace(
                        wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0 ? -1 : 1)
                }
            }

            Item {
                id: dockCapsule
                anchors.centerIn: parent
                height: Math.max(36, parent.height - 6)
                width: Math.min(parent.width * 0.48, dockRow.implicitWidth + 14)
                clip: true
                Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                Row {
                    id: dockRow
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 4
                    Loader { sourceComponent: launcherButton }
                    Loader { sourceComponent: dashboardButton }
                    Repeater {
                        model: root.clients
                        delegate: Loader {
                            required property var modelData
                            sourceComponent: appButton
                            onLoaded: item.client = modelData
                        }
                    }
                    Loader { sourceComponent: settingsButton }
                }
            }

            Row {
                id: rightCluster
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(34, parent.height - 6)
                spacing: 7

                Item {
                    visible: settings.showSystemTray
                    height: parent.height
                    width: visible ? trayRow.implicitWidth + 14 : 0
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Row {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                            model: SystemTray.items
                            delegate: Item {
                                id: trayButton
                                required property var modelData
                                readonly property string source: root.trayIcon(modelData)
                                visible: modelData.status !== Status.Passive
                                width: visible ? 28 : 0
                                height: 28
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: trayMouse.containsMouse
                                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                                        : "transparent"
                                }
                                Image {
                                    anchors.centerIn: parent
                                    width: 17
                                    height: 17
                                    source: trayButton.source
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: source.toString().length > 0 && status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: trayButton.source.length === 0
                                    text: "•"
                                    color: root.foreground
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    id: trayMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton)
                                            trayButton.modelData.activate()
                                        else
                                            trayButton.modelData.secondaryActivate()
                                    }
                                    onWheel: wheel => trayButton.modelData.scroll(
                                        wheel.angleDelta.y || wheel.angleDelta.x,
                                        wheel.angleDelta.x !== 0)
                                }
                                ToolTip.visible: trayMouse.containsMouse
                                ToolTip.delay: 400
                                ToolTip.text: modelData.tooltipTitle || modelData.title || modelData.id
                            }
                        }
                    }
                }

                Item {
                    visible: settings.showStatus
                    height: parent.height
                    width: visible ? statusRow.implicitWidth + 14 : 0
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Row {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 1
                        Item {
                            width: 29
                            height: 28
                            Text {
                                anchors.centerIn: parent
                                text: ((root.audio.output || {}).muted) ? "×" : "◖"
                                color: root.foreground
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shell.volumePopupOpen = !root.shell.volumePopupOpen
                                onWheel: wheel => {
                                    if (!(settings.volumeScroll ?? true))
                                        return
                                    const current = Number((root.audio.output || {}).volume || 0)
                                    const next = Math.max(0, Math.min(100,
                                        current + (wheel.angleDelta.y > 0 ? 5 : -5)))
                                    root.shell.command("audio", JSON.stringify({device:"output", volume:next}))
                                }
                            }
                        }
                        Item {
                            width: 29
                            height: 28
                            Text {
                                anchors.centerIn: parent
                                text: root.network.connected ? "⌁" : "×"
                                color: root.network.connected ? root.accent : "#9aa4b8"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shell.wifiPopupOpen = !root.shell.wifiPopupOpen
                            }
                        }
                        Item {
                            width: 29
                            height: 28
                            Text { anchors.centerIn: parent; text: "▣"; color: root.foreground; font.pixelSize: 12 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shell.clipboardPopupOpen = !root.shell.clipboardPopupOpen
                            }
                        }
                        Text {
                            visible: Number((root.shell.state.system || {}).batteryPercent ?? -1) >= 0
                            text: Math.round(Number((root.shell.state.system || {}).batteryPercent || 0)) + "%"
                            color: root.foreground
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Item {
                    visible: settings.showClock
                    height: parent.height
                    width: visible ? Math.max(92, clockColumn.implicitWidth + 20) : 0
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Column {
                        id: clockColumn
                        anchors.centerIn: parent
                        spacing: -2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.clockText
                            color: root.foreground
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.dateText
                            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.62)
                            font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shell.calendarOpen = !root.shell.calendarOpen
                    }
                }
            }
        }
    }

    Component {
        id: verticalPanel
        Item {
            anchors.fill: parent

            Column {
                id: verticalStack
                anchors.fill: parent
                anchors.margins: 5
                spacing: 7

                Item {
                    width: parent.width
                    height: launcherColumn.implicitHeight + 12
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Column {
                        id: launcherColumn
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Loader { anchors.horizontalCenter: parent.horizontalCenter; sourceComponent: launcherButton }
                        Repeater {
                            model: settings.showWorkspaceSwitcher ? root.workspaceIndices : []
                            delegate: Loader {
                                required property int modelData
                                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                                sourceComponent: workspaceChip
                                onLoaded: item.index = modelData
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(80, Math.min(parent.height * 0.48, appColumn.implicitHeight + 12))
                    clip: true
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Column {
                        id: appColumn
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        spacing: 3
                        Repeater {
                            model: root.clients
                            delegate: Loader {
                                required property var modelData
                                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                                sourceComponent: appButton
                                onLoaded: item.client = modelData
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: statusColumn.implicitHeight + 14
                    Loader { anchors.fill: parent; sourceComponent: capsuleBackground }
                    Column {
                        id: statusColumn
                        anchors.centerIn: parent
                        spacing: 4
                        Loader { anchors.horizontalCenter: parent.horizontalCenter; sourceComponent: dashboardButton }
                        Loader { anchors.horizontalCenter: parent.horizontalCenter; sourceComponent: settingsButton }
                        Text {
                            visible: settings.showStatus
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.network.connected ? "⌁" : "×"
                            color: root.network.connected ? root.accent : "#9aa4b8"
                            font.pixelSize: 13
                        }
                        Text {
                            visible: settings.showClock
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.clockText
                            color: root.foreground
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
