import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme"
        source: "configGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Behavior")
        icon: "preferences-system-performance"
        source: "configBehavior.qml"
    }
}
