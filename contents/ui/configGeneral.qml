import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    signal settingValueChanged()

    property alias cfg_iconHighPath: highIconPathField.text
    property alias cfg_iconMediumPath: mediumIconPathField.text
    property alias cfg_iconLowPath: lowIconPathField.text
    property alias cfg_iconMutedPath: mutedIconPathField.text
    property alias cfg_showIcon: showIconCheckBox.checked
    property alias cfg_fontFamily: fontFamilyField.text

    function browseForIcon(setting) {
        iconDialog.targetSetting = setting;
        iconDialog.open();
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Appearance")
    }

    QQC2.CheckBox {
        id: showIconCheckBox

        Kirigami.FormData.label: i18n("Speaker icon:")
        text: i18n("Show icon")
        onToggled: page.settingValueChanged()
    }

    RowLayout {
        Kirigami.FormData.label: i18n("High volume:")

        QQC2.TextField {
            id: highIconPathField

            placeholderText: i18n("Use your default icon")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Browse…")
            onClicked: page.browseForIcon("high")
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: highIconPathField.text.length > 0
            onClicked: highIconPathField.clear()
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Medium volume:")

        QQC2.TextField {
            id: mediumIconPathField

            placeholderText: i18n("Use your default icon")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Browse…")
            onClicked: page.browseForIcon("medium")
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: mediumIconPathField.text.length > 0
            onClicked: mediumIconPathField.clear()
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Low volume:")

        QQC2.TextField {
            id: lowIconPathField

            placeholderText: i18n("Use your default icon")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Browse…")
            onClicked: page.browseForIcon("low")
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: lowIconPathField.text.length > 0
            onClicked: lowIconPathField.clear()
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Muted:")

        QQC2.TextField {
            id: mutedIconPathField

            placeholderText: i18n("Use your default icon")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Browse…")
            onClicked: page.browseForIcon("muted")
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: mutedIconPathField.text.length > 0
            onClicked: mutedIconPathField.clear()
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Percentage font:")

        QQC2.TextField {
            id: fontFamilyField

            placeholderText: i18n("System default")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Choose…")
            onClicked: fontDialog.open()
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: fontFamilyField.text.length > 0
            onClicked: fontFamilyField.clear()
        }
    }

    FileDialog {
        id: iconDialog

        property string targetSetting: ""

        title: i18n("Select a speaker icon")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            i18n("Image files (*.png *.jpg *.jpeg *.svg *.webp)"),
            i18n("All files (*)")
        ]

        onAccepted: {
            const path = selectedFile.toString();

            switch (targetSetting) {
            case "high":
                highIconPathField.text = path;
                break;
            case "medium":
                mediumIconPathField.text = path;
                break;
            case "low":
                lowIconPathField.text = path;
                break;
            case "muted":
                mutedIconPathField.text = path;
                break;
            }

            targetSetting = "";
        }

        onRejected: targetSetting = ""
    }

    FontDialog {
        id: fontDialog

        title: i18n("Select the percentage font")
        currentFont.family: fontFamilyField.text.length > 0
            ? fontFamilyField.text
            : "Sans Serif"

        onAccepted: fontFamilyField.text = selectedFont.family
    }
}
