import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.private.volume

PlasmoidItem {
    id: root

    property int targetVolumePercent: -1
    property real displayedVolumePercent: -1
    property bool muted: false
    readonly property var preferredSink: PreferredDevice.sink

    readonly property int updateBehavior: Math.max(0, Math.min(2, Number(Plasmoid.configuration.updateBehavior) || 0))
    readonly property int customInterval: Math.max(100, Math.min(2000, Number(Plasmoid.configuration.customInterval) || 250))
    readonly property bool tweeningEnabled: Plasmoid.configuration.tweeningEnabled
    readonly property int tweenSpeed: Math.max(0, Math.min(2, Number(Plasmoid.configuration.tweenSpeed) || 0))

    readonly property string customIconPath: String(Plasmoid.configuration.iconPath || "")
    readonly property string customFontFamily: String(Plasmoid.configuration.fontFamily || "")

    toolTipMainText: i18n("Output volume")
    toolTipSubText: displayedVolumePercent >= 0
        ? (muted ? i18n("%1% (muted)", Math.round(displayedVolumePercent)) : i18n("%1%", Math.round(displayedVolumePercent)))
        : i18n("Waiting for audio service")

    function tweenDurationForDistance(distance) {
        let baseDuration = 150;
        let distanceFactor = 28;

        if (tweenSpeed === 0) {
            baseDuration = 90;
            distanceFactor = 18;
        } else if (tweenSpeed === 2) {
            baseDuration = 220;
            distanceFactor = 38;
        }

        return Math.round(baseDuration + Math.sqrt(distance) * distanceFactor);
    }

    function applyDisplayedVolume(value) {
        if (value < 0) {
            volumeTween.stop();
            displayedVolumePercent = -1;
            return;
        }

        if (!tweeningEnabled || displayedVolumePercent < 0) {
            volumeTween.stop();
            displayedVolumePercent = value;
            return;
        }

        const distance = Math.abs(value - displayedVolumePercent);
        if (distance === 0) {
            return;
        }

        volumeTween.stop();
        volumeTween.from = displayedVolumePercent;
        volumeTween.to = value;
        volumeTween.duration = tweenDurationForDistance(distance);
        volumeTween.start();
    }

    function clearVolumeState() {
        settleTimer.stop();
        customUpdateTimer.stop();
        volumeTween.stop();
        targetVolumePercent = -1;
        displayedVolumePercent = -1;
        muted = false;
    }

    function updateVolumeFromSink() {
        const sink = preferredSink;

        if (!sink || sink.name === "auto_null") {
            clearVolumeState();
            return;
        }

        const volume = Number(sink.volume);
        const normalVolume = Number(PulseAudio.NormalVolume);

        if (!Number.isFinite(volume) || volume < 0
            || !Number.isFinite(normalVolume) || normalVolume <= 0) {
            clearVolumeState();
            return;
        }

        const newVolumePercent = Math.round(volume / normalVolume * 100.0);
        muted = Boolean(sink.muted);

        if (newVolumePercent === targetVolumePercent) {
            return;
        }

        targetVolumePercent = newVolumePercent;

        if (displayedVolumePercent < 0) {
            settleTimer.stop();
            customUpdateTimer.stop();
            applyDisplayedVolume(newVolumePercent);
        } else if (updateBehavior === 1) {
            customUpdateTimer.stop();
            volumeTween.stop();
            settleTimer.restart();
        } else if (updateBehavior === 2) {
            settleTimer.stop();

            if (!customUpdateTimer.running) {
                customUpdateTimer.start();
            }
        } else {
            settleTimer.stop();
            customUpdateTimer.stop();
            applyDisplayedVolume(newVolumePercent);
        }
    }

    onPreferredSinkChanged: updateVolumeFromSink()

    onUpdateBehaviorChanged: {
        settleTimer.stop();
        customUpdateTimer.stop();

        if (targetVolumePercent < 0) {
            return;
        }

        if (updateBehavior === 1 && Math.round(displayedVolumePercent) !== targetVolumePercent) {
            volumeTween.stop();
            settleTimer.restart();
        } else {
            applyDisplayedVolume(targetVolumePercent);
        }
    }

    onCustomIntervalChanged: {
        if (customUpdateTimer.running) {
            customUpdateTimer.restart();
        }
    }

    onTweeningEnabledChanged: {
        if (!tweeningEnabled) {
            volumeTween.stop();
            customUpdateTimer.stop();

            if (targetVolumePercent >= 0 && (updateBehavior !== 1 || !settleTimer.running)) {
                displayedVolumePercent = targetVolumePercent;
            }
        }
    }

    Component {
        id: volumeReadout

        Item {
            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight

            RowLayout {
                id: content

                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Image {
                    id: customIcon

                    source: root.customIconPath
                    visible: root.customIconPath.length > 0
                        && status === Image.Ready
                        && !root.muted
                        && root.displayedVolumePercent !== 0
                    asynchronous: true
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(
                        Kirigami.Units.iconSizes.small,
                        Kirigami.Units.iconSizes.small
                    )

                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    Layout.alignment: Qt.AlignVCenter
                }

                Kirigami.Icon {
                    visible: !customIcon.visible

                    source: {
                        if (root.muted || root.displayedVolumePercent === 0) {
                            return "audio-volume-muted";
                        }
                        if (root.displayedVolumePercent < 0) {
                            return "audio-volume-high";
                        }
                        if (root.displayedVolumePercent <= 33) {
                            return "audio-volume-low";
                        }
                        if (root.displayedVolumePercent <= 66) {
                            return "audio-volume-medium";
                        }
                        return "audio-volume-high";
                    }

                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.displayedVolumePercent >= 0
                        ? Math.round(root.displayedVolumePercent) + "%"
                        : "—"
                    color: Kirigami.Theme.textColor
                    font.family: root.customFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium

                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: plasmoid.expanded = !plasmoid.expanded
            }
        }
    }

    compactRepresentation: volumeReadout
    fullRepresentation: volumeReadout

    Timer {
        id: settleTimer

        interval: 1500
        repeat: false
        onTriggered: root.applyDisplayedVolume(root.targetVolumePercent)
    }

    NumberAnimation {
        id: volumeTween

        target: root
        property: "displayedVolumePercent"
        easing.type: Easing.OutCubic
    }

    Timer {
        id: customUpdateTimer

        interval: root.customInterval
        repeat: false
        onTriggered: root.applyDisplayedVolume(root.targetVolumePercent)
    }

    Connections {
        target: root.preferredSink
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            root.updateVolumeFromSink();
        }

        function onMutedChanged() {
            root.updateVolumeFromSink();
        }
    }

    Component.onCompleted: updateVolumeFromSink()
}
