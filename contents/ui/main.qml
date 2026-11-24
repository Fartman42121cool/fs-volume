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
        || Plasmoid.location === PlasmaCore.Types.LeftEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
    readonly property bool showIcon: Boolean(Plasmoid.configuration.showIcon)

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

        if (muted || targetVolumePercent === 0) {
            statePath = mutedIconPath;
        } else if (targetVolumePercent >= 0 && targetVolumePercent <= 33) {
            statePath = lowIconPath;
        } else if (targetVolumePercent >= 0 && targetVolumePercent <= 66) {
            statePath = mediumIconPath;
        } else {
            statePath = highIconPath;
        }

        if (statePath.length > 0) {
            return statePath;
        }

        return !muted && targetVolumePercent !== 0 ? legacyIconPath : "";
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
                const thickness = root.verticalPanel ? width : height;
                return thickness > 0 ? thickness : Kirigami.Units.iconSizes.small / 0.68;
            }
            readonly property real iconSize: Math.max(12, Math.min(48, panelThickness * 0.68))
            readonly property int fontPixelSize: Math.max(10, Math.min(24, Math.round(iconSize * 0.72)))
            implicitWidth: contentLoader.implicitWidth
            implicitHeight: contentLoader.implicitHeight

            // Plasma uses the relevant axis: minimumWidth horizontally, minimumHeight vertically.
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight

            Loader {
                id: contentLoader

                anchors.fill: parent
                sourceComponent: root.verticalPanel ? verticalReadout : horizontalReadout
            }

            Component {
                id: iconRepresentation

                Item {
                    implicitWidth: readout.iconSize
                    implicitHeight: readout.iconSize

                    Image {
                        id: customIcon

                        anchors.fill: parent
                        source: root.customIconPath
                        visible: root.showIcon && root.customIconPath.length > 0 && status === Image.Ready
                        asynchronous: false
                        cache: false
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(readout.iconSize, readout.iconSize)
                    }

                    Kirigami.Icon {
                        visible: root.showIcon && !customIcon.visible

                        anchors.fill: parent
                        source: {
                            if (root.muted || root.targetVolumePercent === 0) {
                                return "audio-volume-muted";
                            }
                            if (root.targetVolumePercent < 0) {
                                return "audio-volume-high";
                            }
                            if (root.targetVolumePercent <= 33) {
                                return "audio-volume-low";
                            }
                            if (root.targetVolumePercent <= 66) {
                                return "audio-volume-medium";
                            }
                            return "audio-volume-high";
                        }
                    }
                }
            }

            Component {
                id: percentageRepresentation

                Text {
                    text: root.displayedVolumePercent >= 0
                        ? Math.round(root.displayedVolumePercent) + "%"
                        : "—"
                    color: Kirigami.Theme.textColor
                    font.family: root.customFontFamily
                    font.pixelSize: readout.fontPixelSize
                    font.weight: Font.Medium
                    font.strikeout: root.muted && !root.showIcon
                }
            }

            Component {
                id: horizontalReadout

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Loader {
                        active: root.showIcon
                        visible: root.showIcon
                        sourceComponent: iconRepresentation
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Loader {
                        sourceComponent: percentageRepresentation
                        Layout.alignment: root.showIcon
                            ? Qt.AlignVCenter
                            : Qt.AlignHCenter | Qt.AlignVCenter
                    }
                }
            }

            Component {
                id: verticalReadout

                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing / 2

                    Loader {
                        active: root.showIcon
                        visible: root.showIcon
                        sourceComponent: iconRepresentation
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Loader {
                        sourceComponent: percentageRepresentation
                        Layout.alignment: Qt.AlignHCenter
                    }
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
