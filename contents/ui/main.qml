import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property int targetVolumePercent: -1
    property real displayedVolumePercent: -1
    property bool muted: false

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
        volumeTween.stop();
        targetVolumePercent = -1;
        displayedVolumePercent = -1;
        muted = false;
    }

    onUpdateBehaviorChanged: {
        settleTimer.stop();

        if (targetVolumePercent < 0) {
            return;
        }

        if (updateBehavior === 1 && Math.round(displayedVolumePercent) !== targetVolumePercent) {
            settleTimer.restart();
        } else if (updateBehavior !== 1) {
            applyDisplayedVolume(targetVolumePercent);
        }
    }

    onTweeningEnabledChanged: {
        if (!tweeningEnabled && updateBehavior !== 1) {
            volumeTween.stop();
            if (targetVolumePercent >= 0) {
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

    Plasma5Support.DataSource {
        id: volumeSource

        engine: "executable"
        connectedSources: ["wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        interval: root.updateBehavior === 2 ? root.customInterval : 250

        onNewData: (sourceName, data) => {
            const exitCode = Number(data["exit code"]);
            const output = String(data["stdout"] || "");

            if (exitCode !== 0) {
                root.clearVolumeState();
                return;
            }

            const match = output.match(/Volume:?\s*(\d+(?:\.\d+)?)/);
            if (!match) {
                root.clearVolumeState();
                return;
            }

            const volume = Number(match[1]);
            if (isNaN(volume)) {
                root.clearVolumeState();
                return;
            }

            const newVolumePercent = Math.round(volume * 100);
            root.muted = output.indexOf("[MUTED]") !== -1;

            if (newVolumePercent === root.targetVolumePercent) {
                return;
            }

            root.targetVolumePercent = newVolumePercent;

            if (root.displayedVolumePercent < 0 || root.updateBehavior !== 1) {
                settleTimer.stop();
                root.applyDisplayedVolume(newVolumePercent);
            } else if (Math.round(root.displayedVolumePercent) === newVolumePercent) {
                settleTimer.stop();
            } else {
                settleTimer.restart();
            }
        }
    }
}
