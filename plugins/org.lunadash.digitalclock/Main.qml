import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: plugin
    required property var shell
    required property var settings
    required property var context
    width: 0
    height: 0

    readonly property var appearance: shell ? (shell.state.appearance || {}) : ({})
    readonly property color accent: appearance.accent || "#9ccbfb"
    readonly property color primary: Qt.lighter(accent, 1.06)
    readonly property color secondary: Qt.lighter(accent, 1.42)
    readonly property string uiFont: appearance.fontFamily || Qt.application.font.family
    readonly property string position: String(settings.position || "bottomRight")
    readonly property bool atLeft: position.endsWith("Left")
    readonly property bool atTop: position.startsWith("top")
    readonly property int marginX: Math.max(0, Number(settings.marginX ?? 34))
    readonly property int marginY: Math.max(0, Number(settings.marginY ?? 34))
    readonly property bool use24Hour: settings.use24Hour ?? true
    readonly property bool showSeconds: settings.showSeconds ?? false
    readonly property bool showDate: settings.showDate ?? true
    readonly property real clockScale: Math.max(0.7, Math.min(1.5, Number(settings.scale ?? 1.0)))
    readonly property real clockOpacity: Math.max(0.3, Math.min(1.0, Number(settings.opacity ?? 1.0)))
    readonly property var locale: Qt.locale((shell.state || {}).language || "en_US")
    property date now: new Date()

    Timer {
        interval: plugin.showSeconds ? 250 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: plugin.now = new Date()
    }

    PanelWindow {
        anchors.left: plugin.atLeft
        anchors.right: !plugin.atLeft
        anchors.top: plugin.atTop
        anchors.bottom: !plugin.atTop
        margins.left: plugin.atLeft ? plugin.marginX : 0
        margins.right: plugin.atLeft ? 0 : plugin.marginX
        margins.top: plugin.atTop ? plugin.marginY : 0
        margins.bottom: plugin.atTop ? 0 : plugin.marginY
        implicitWidth: Math.round(405 * plugin.clockScale)
        implicitHeight: Math.round((plugin.showDate ? 112 : 88) * plugin.clockScale)
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "lunadash-plugin-digital-clock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        RowLayout {
            anchors.fill: parent
            spacing: Math.round(17 * plugin.clockScale)
            opacity: plugin.clockOpacity

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: plugin.locale.toString(
                    plugin.now,
                    plugin.use24Hour
                        ? (plugin.showSeconds ? "HH:mm:ss" : "HH:mm")
                        : (plugin.showSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
                color: plugin.primary
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.38)
                font.family: plugin.uiFont
                font.pixelSize: Math.round((plugin.showSeconds ? 50 : 62) * plugin.clockScale)
                font.weight: Font.Bold
            }

            Rectangle {
                visible: plugin.showDate
                Layout.preferredWidth: Math.max(1, Math.round(2 * plugin.clockScale))
                Layout.preferredHeight: Math.round(72 * plugin.clockScale)
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: Qt.rgba(plugin.accent.r, plugin.accent.g, plugin.accent.b, 0.78)
            }

            ColumnLayout {
                visible: plugin.showDate
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: -1

                Text {
                    text: plugin.locale.toString(plugin.now, "MMMM").toUpperCase()
                    color: plugin.secondary
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.30)
                    font.family: plugin.uiFont
                    font.pixelSize: Math.round(14 * plugin.clockScale)
                    font.weight: Font.Bold
                    font.letterSpacing: 3.2 * plugin.clockScale
                }
                Text {
                    text: plugin.locale.toString(plugin.now, "dd")
                    color: plugin.primary
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.32)
                    font.family: plugin.uiFont
                    font.pixelSize: Math.round(24 * plugin.clockScale)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5 * plugin.clockScale
                }
                Text {
                    text: plugin.locale.toString(plugin.now, "dddd")
                    color: plugin.secondary
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.28)
                    font.family: plugin.uiFont
                    font.pixelSize: Math.round(13 * plugin.clockScale)
                    font.letterSpacing: 1.3 * plugin.clockScale
                }
            }
        }
    }
}
