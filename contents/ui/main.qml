import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.volume

PlasmoidItem {
    id: root

    property int targetVolumePercent: -1
    property real displayedVolumePercent: -1
    property bool muted: false
    readonly property var preferredSink: PreferredDevice.sink
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property int updateBehavior: Math.max(0, Math.min(2, Number(Plasmoid.configuration.updateBehavior) || 0))
    readonly property int customInterval: Math.max(100, Math.min(2000, Number(Plasmoid.configuration.customInterval) || 250))
    readonly property bool tweeningEnabled: Plasmoid.configuration.tweeningEnabled
    readonly property int tweenSpeed: Math.max(0, Math.min(2, Number(Plasmoid.configuration.tweenSpeed) || 0))

    readonly property string legacyIconPath: String(Plasmoid.configuration.iconPath || "")
    readonly property string highIconPath: String(Plasmoid.configuration.iconHighPath || "")
    readonly property string mediumIconPath: String(Plasmoid.configuration.iconMediumPath || "")
    readonly property string lowIconPath: String(Plasmoid.configuration.iconLowPath || "")
    readonly property string mutedIconPath: String(Plasmoid.configuration.iconMutedPath || "")
    readonly property string customIconPath: {
        let statePath = "";

        if (muted || displayedVolumePercent === 0) {
            statePath = mutedIconPath;
        } else if (displayedVolumePercent >= 0 && displayedVolumePercent <= 33) {
            statePath = lowIconPath;
        } else if (displayedVolumePercent >= 0 && displayedVolumePercent <= 66) {
            statePath = mediumIconPath;
        } else {
            statePath = highIconPath;
        }

        if (statePath.length > 0) {
            return statePath;
        }

        return !muted && displayedVolumePercent !== 0 ? legacyIconPath : "";
    }
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
            id: readout

            readonly property real panelThickness: {
                if (root.verticalPanel) {
                    return width;
                }
                if (Plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
                    return height;
                }
                return Kirigami.Units.iconSizes.small / 0.68;
            }
            readonly property real iconSize: Math.max(12, Math.min(48, panelThickness * 0.68))
            readonly property int fontPixelSize: Math.max(10, Math.min(24, Math.round(iconSize * 0.72)))

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            Layout.preferredWidth: root.verticalPanel ? Kirigami.Units.iconSizes.small : implicitWidth
            Layout.preferredHeight: root.verticalPanel ? implicitHeight : Kirigami.Units.iconSizes.small
            Layout.minimumWidth: root.verticalPanel ? 0 : implicitWidth
            Layout.minimumHeight: root.verticalPanel ? implicitHeight : 0

            GridLayout {
                id: content

                anchors.fill: parent
                columns: root.verticalPanel ? 1 : 2
                rows: root.verticalPanel ? 2 : 1
                columnSpacing: root.verticalPanel ? 0 : Kirigami.Units.smallSpacing
                rowSpacing: root.verticalPanel ? Kirigami.Units.smallSpacing / 2 : 0

                Item {
                    Layout.preferredWidth: readout.iconSize
                    Layout.preferredHeight: readout.iconSize
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Image {
                        id: customIcon

                        anchors.fill: parent
                        source: root.customIconPath
                        visible: root.customIconPath.length > 0 && status === Image.Ready
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(readout.iconSize, readout.iconSize)
                    }

                    Kirigami.Icon {
                        visible: !customIcon.visible

                        anchors.fill: parent
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
                    }
                }

                Text {
                    text: root.displayedVolumePercent >= 0
                        ? Math.round(root.displayedVolumePercent) + "%"
                        : "—"
                    color: Kirigami.Theme.textColor
                    font.family: root.customFontFamily
                    font.pixelSize: readout.fontPixelSize
                    font.weight: Font.Medium

                    Layout.alignment: root.verticalPanel
                        ? Qt.AlignHCenter | Qt.AlignVCenter
                        : Qt.AlignVCenter
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
