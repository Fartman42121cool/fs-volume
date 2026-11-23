import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_iconPath: iconPathField.text
    property alias cfg_fontFamily: fontFamilyField.text

    RowLayout {
        Kirigami.FormData.label: i18n("Volume icon:")

        QQC2.TextField {
            id: iconPathField

            placeholderText: i18n("Use the built-in icon")
            Layout.fillWidth: true
        }

        QQC2.Button {
            text: i18n("Browse…")
            onClicked: iconDialog.open()
        }

        QQC2.Button {
            text: i18n("Reset")
            enabled: iconPathField.text.length > 0
            onClicked: iconPathField.clear()
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

        title: i18n("Select a volume icon")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            i18n("Image files (*.png *.jpg *.jpeg *.svg *.webp)"),
            i18n("All files (*)")
        ]

        onAccepted: iconPathField.text = selectedFile.toString()
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
