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
    property real smoothedActivity: 0

    readonly property int bars: Math.max(24, Math.min(144, Number(settings.barCount ?? 88)))
    readonly property real outputVolume: Math.max(0, Math.min(1,
        Number((((shell.state.audio || {}).output || {}).volume || 0)) / 100))
    readonly property bool muted: Boolean((((shell.state.audio || {}).output || {}).muted) || false)
    readonly property real targetActivity: mediaPlaying && !muted
        ? Math.min(1, Math.max(0.12, outputVolume * Number(settings.sensitivity ?? 2.4)))
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
        duration: 920
        loops: Animation.Infinite
        running: root.visible
    }

    Timer {
        interval: 16
        repeat: true
        running: root.visible
        onTriggered: {
            const target = root.targetActivity
            const speed = target > root.smoothedActivity ? 0.28 : 0.095
            root.smoothedActivity += (target - root.smoothedActivity) * speed
            if (Math.abs(root.smoothedActivity - target) < 0.001)
                root.smoothedActivity = target
        }
    }

    Process {
        id: mediaProbe
        command: [root.shell.shellToolExecutable, "media-status", "", ""]
        stdout: StdioCollector { onStreamFinished: root.adoptMedia(text) }
    }

    Timer {
        interval: 500
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
        height: Math.max(100, Math.min(parent.height * 0.72, Number(settings.height ?? 280)))
        opacity: Math.max(0.20, Math.min(1, Number(settings.opacity ?? 0.86)))

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
        }

        Repeater {
            model: root.bars
            delegate: Rectangle {
                required property int index
                readonly property real normalized: (index + 0.5) / root.bars
                readonly property real mirroredDistance: Math.abs(normalized - 0.5) * 2
                readonly property real envelope: settings.mirror ?? true
                    ? 0.38 + 0.82 * Math.pow(Math.max(0, Math.sin(Math.PI * (1 - mirroredDistance))), 0.52)
                    : 0.48 + 0.62 * Math.sin(Math.PI * normalized)
                readonly property real harmonic:
                    0.72
                    + 0.34 * Math.sin(root.phase * 2.4 + index * 0.37)
                    + 0.22 * Math.sin(root.phase * 4.7 - index * 0.19)
                    + 0.14 * Math.cos(root.phase * 1.65 + index * 0.71)
                    + 0.08 * Math.sin(root.phase * 7.3 + index * 0.11)
                readonly property real idlePulse:
                    root.mediaPlaying ? 0
                        : 0.010 + 0.010 * (0.5 + 0.5 * Math.sin(root.phase + index * 0.16))
                width: Math.max(2, (wave.width - (root.bars - 1) * 2) / root.bars)
                x: index * (width + 2)
                anchors.bottom: parent.bottom
                height: Math.max(
                    3,
                    wave.height * (
                        root.smoothedActivity * envelope * Math.max(0.18, harmonic)
                        + idlePulse
                    )
                )
                radius: Math.max(1, width / 2)
                color: Qt.rgba(
                    root.accent.r,
                    root.accent.g,
                    root.accent.b,
                    0.30 + 0.62 * Math.max(root.smoothedActivity, 0.08)
                )
            }
        }
    }
}
