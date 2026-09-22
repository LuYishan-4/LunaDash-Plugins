import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var shell
    required property var settings
    required property var context
    anchors.fill: parent
    property bool pluginReady: true
    property bool mediaPlaying: false
    property real phase: 0

    readonly property int bars: Math.max(24, Math.min(120, Number(settings.barCount ?? 72)))
    readonly property real outputVolume: Math.max(0, Math.min(1,
        Number((((shell.state.audio || {}).output || {}).volume || 0)) / 100))
    readonly property bool muted: Boolean((((shell.state.audio || {}).output || {}).muted) || false)
    readonly property real activity: mediaPlaying && !muted
        ? Math.min(1, outputVolume * Number(settings.sensitivity ?? 1.15))
        : 0
    readonly property color accent: (shell.state.appearance || {}).accent || "#9ccbfb"

    function adoptMedia(text) {
        try {
            const state = JSON.parse(String(text || "{}"))
            mediaPlaying = Boolean(state.available && state.playing)
        } catch (error) {
            mediaPlaying = false
        }
    }

    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 1550
        loops: Animation.Infinite
        running: root.visible
    }

    Process {
        id: mediaProbe
        command: [root.shell.shellToolExecutable, "media-status", "", ""]
        stdout: StdioCollector { onStreamFinished: root.adoptMedia(text) }
    }

    Timer {
        interval: 900
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: if (!mediaProbe.running) mediaProbe.running = true
    }

    Item {
        id: wave
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(0, Number(settings.bottomMargin ?? 0))
        height: Math.max(80, Math.min(parent.height * 0.65, Number(settings.height ?? 210)))
        opacity: Math.max(0.15, Math.min(1, Number(settings.opacity ?? 0.78)))

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
        }

        Repeater {
            model: root.bars
            delegate: Rectangle {
                required property int index
                readonly property real centerDistance: Math.abs((index + 0.5) / root.bars - 0.5) * 2
                readonly property real envelope: settings.mirror ?? true
                    ? 0.30 + 0.70 * Math.pow(Math.sin(Math.PI * (1 - centerDistance)), 0.7)
                    : 0.45 + 0.55 * Math.sin(Math.PI * (index + 0.5) / root.bars)
                readonly property real harmonic:
                    0.52
                    + 0.25 * Math.sin(root.phase * 2.1 + index * 0.43)
                    + 0.15 * Math.sin(root.phase * 3.7 - index * 0.21)
                    + 0.08 * Math.cos(root.phase * 1.4 + index * 0.77)
                width: Math.max(2, (wave.width - (root.bars - 1) * 3) / root.bars)
                x: index * (width + 3)
                anchors.bottom: parent.bottom
                height: Math.max(3, wave.height * root.activity * envelope * Math.max(0.08, harmonic))
                radius: width / 2
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b,
                               0.42 + 0.50 * root.activity)
                Behavior on height {
                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }
    }
}
