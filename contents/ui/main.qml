import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property int volumePercent: -1
    property bool muted: false

    preferredRepresentation: fullRepresentation

    toolTipMainText: i18n("Output volume")
    toolTipSubText: volumePercent >= 0
        ? (muted ? i18n("%1% (muted)", volumePercent) : i18n("%1%", volumePercent))
        : i18n("Waiting for audio service")

    fullRepresentation: RowLayout {
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: {
                if (root.muted || root.volumePercent === 0) {
                    return "audio-volume-muted";
                }
                if (root.volumePercent <= 33) {
                    return "audio-volume-low";
                }
                if (root.volumePercent <= 66) {
                    return "audio-volume-medium";
                }
                return "audio-volume-high";
            }

            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.volumePercent >= 0 ? root.volumePercent + "%" : "—"
            color: Kirigami.Theme.textColor
            font.pixelSize: 12
            font.weight: Font.Medium

            Layout.alignment: Qt.AlignVCenter
        }
    }

    Plasma5Support.DataSource {
        id: volumeSource

        engine: "executable"
        connectedSources: ["wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        interval: 1500

        onNewData: (sourceName, data) => {
            const exitCode = Number(data["exit code"]);
            const output = String(data["stdout"] || "");

            if (exitCode !== 0) {
                root.volumePercent = -1;
                root.muted = false;
                return;
            }

            const match = output.match(/Volume:\s*(\d+(?:\.\d+)?)/);
            if (!match) {
                root.volumePercent = -1;
                root.muted = false;
                return;
            }

            const volume = Number(match[1]);
            if (isNaN(volume)) {
                root.volumePercent = -1;
                root.muted = false;
                return;
            }

            root.volumePercent = Math.round(volume * 100);
            root.muted = output.indexOf("[MUTED]") !== -1;
        }
    }
}