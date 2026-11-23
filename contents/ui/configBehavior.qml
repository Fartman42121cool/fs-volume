import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_updateBehavior: updateBehaviorCombo.currentIndex
    property alias cfg_customInterval: customIntervalSpin.value
    property alias cfg_tweeningEnabled: tweeningCheck.checked
    property alias cfg_tweenSpeed: tweenSpeedCombo.currentIndex

    QQC2.ComboBox {
        id: updateBehaviorCombo

        Kirigami.FormData.label: i18n("UI update behavior:")
        model: [
            i18n("Every Update"),
            i18n("When Finished Changing"),
            i18n("Custom Interval")
        ]
        Layout.fillWidth: true
    }

    QQC2.Label {
        text: {
            if (updateBehaviorCombo.currentIndex === 1) {
                return i18n("Updates 1.5 seconds after the last detected volume change.");
            }
            if (updateBehaviorCombo.currentIndex === 2) {
                return i18n("Uses your custom interval to check for volume changes.");
            }
            return i18n("Updates whenever a volume change is detected (checked every 250 ms).");
        }
        wrapMode: Text.WordWrap
        opacity: 0.75
        Layout.fillWidth: true
    }

    RowLayout {
        visible: updateBehaviorCombo.currentIndex === 2
        Kirigami.FormData.label: i18n("Custom interval:")

        QQC2.SpinBox {
            id: customIntervalSpin

            from: 100
            to: 2000
            stepSize: 50
            editable: true
        }

        QQC2.Label {
            text: i18n("ms")
        }
    }

    QQC2.CheckBox {
        id: tweeningCheck

        Kirigami.FormData.label: i18n("Volume tweening:")
        text: i18n("Enable smooth transitions")
    }

    QQC2.ComboBox {
        id: tweenSpeedCombo

        visible: tweeningCheck.checked
        Kirigami.FormData.label: i18n("Tween speed:")
        model: [
            i18n("Fast"),
            i18n("Medium"),
            i18n("Slow")
        ]
        Layout.fillWidth: true
    }

    QQC2.Label {
        visible: tweeningCheck.checked
        text: i18n("Large volume changes take longer overall but move faster per percentage point. The animation slows near its target.")
        wrapMode: Text.WordWrap
        opacity: 0.75
        Layout.fillWidth: true
    }
}
