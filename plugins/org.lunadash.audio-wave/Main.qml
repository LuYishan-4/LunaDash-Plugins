import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var shell
    required property var settings
    required property var context
    anchors.fill: parent
    property bool pluginReady: true
    property var measuredBands: []
    property var levels: []
    property double lastFrame: 0
    property string monitorError: ""

    readonly property int bars: Math.max(24, Math.min(144, Number(settings.barCount ?? 88)))
    readonly property real gain: Math.max(0.4, Math.min(4, Number(settings.sensitivity ?? 2.4)))
    readonly property bool muted: Boolean((((shell.state.audio || {}).output || {}).muted) || false)
    readonly property color accent: (shell.state.appearance || {}).accent || "#9ccbfb"
    readonly property string defaultOutput: JSON.stringify(
        ((shell.state.audio || {}).outputDevices || []).filter(device => device.default).map(device => device.id))

    function adoptSpectrum(text) {
        try {
            const state = JSON.parse(text)
            if (!state.available || !Array.isArray(state.bands) || state.bands.length !== 32) {
                monitorError = String(state.error || "Audio monitor unavailable")
                measuredBands = []
                return
            }
            measuredBands = state.bands.map(value => Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0)
            lastFrame = Date.now()
            monitorError = ""
        } catch (error) {
            measuredBands = []
            monitorError = "Invalid audio monitor response"
        }
    }

    function advance(seconds) {
        const dt = Math.min(0.1, Math.max(0, seconds))
        const active = !muted && Date.now() - lastFrame < 350 && measuredBands.length === 32
        const next = []
        for (let i = 0; i < bars; ++i) {
            const position = (i + 0.5) / bars
            const frequency = (settings.mirror ?? true) ? Math.abs(position * 2 - 1) : position
            const sample = frequency * 31
            const low = Math.floor(sample)
            const fraction = sample - low
            const amplitude = active ? measuredBands[low] * (1 - fraction)
                + measuredBands[Math.min(31, low + 1)] * fraction : 0
            const target = Math.min(1, Math.pow(amplitude, 0.8) * gain)
            const previous = levels[i] || 0
            const blend = 1 - Math.exp(-dt / (target > previous ? 0.035 : 0.18))
            next.push(previous + (target - previous) * blend)
        }
        levels = next
    }

    onDefaultOutputChanged: {
        measuredBands = []
        spectrum.running = false
    }
    Component.onCompleted: spectrum.running = visible
    onVisibleChanged: {
        if (visible)
            spectrum.running = true
        if (!visible) {
            spectrum.running = false
            measuredBands = []
            levels = []
        }
    }

    Process {
        id: spectrum
        command: [root.shell.shellToolExecutable, "audio-spectrum"]
        stdout: SplitParser { onRead: data => root.adoptSpectrum(data) }
        onExited: {
            root.measuredBands = []
            if (root.visible && root.monitorError === "")
                root.monitorError = "Audio monitor stopped; reconnecting"
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible && !spectrum.running
        onTriggered: spectrum.running = true
    }

    FrameAnimation {
        running: root.visible
        onTriggered: root.advance(frameTime)
    }

    Item {
        id: wave
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(0, Number(settings.bottomMargin ?? 0))
        height: Math.min(parent.height * 0.72, Math.max(80, Number(settings.height ?? 320)))
        opacity: Math.max(0.15, Math.min(1, Number(settings.opacity ?? 0.86)))
        clip: true

        Repeater {
            model: root.bars
            delegate: Rectangle {
                required property int index
                readonly property real level: root.levels[index] || 0
                width: Math.max(1, (wave.width - (root.bars - 1) * 2) / root.bars)
                x: index * (width + 2)
                anchors.bottom: parent.bottom
                height: Math.max(2, wave.height * level)
                radius: Math.min(5, width / 2)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.95) }
                    GradientStop { position: 1; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25) }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: Math.min(parent.width - 32, 600)
            text: root.monitorError
            visible: text !== ""
            color: root.accent
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 13
        }
    }
}
