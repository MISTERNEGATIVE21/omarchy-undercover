import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: actionCenterWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
      right: true
    }
    margins {
      bottom: 54
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 380
    implicitHeight: 460

    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool nightLightEnabled: false
    property bool batterySaverEnabled: false
    property real volumeVal: 75
    property real brightnessVal: 80

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 16
      color: Qt.rgba(0.11, 0.12, 0.16, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.14)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // 1. Quick Toggles Grid (3 cols x 2 rows)
        GridLayout {
          Layout.fillWidth: true
          columns: 3
          rowSpacing: 10
          columnSpacing: 10

          // Wi-Fi Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: actionCenterWindow.wifiEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰤨"; font.pixelSize: 18; color: "#ffffff" }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Wi-Fi"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.wifiEnabled = !actionCenterWindow.wifiEnabled
                Quickshell.execDetached("nmcli radio wifi " + (actionCenterWindow.wifiEnabled ? "on" : "off"))
              }
            }
          }

          // Bluetooth Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: actionCenterWindow.btEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂯"; font.pixelSize: 18; color: "#ffffff" }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Bluetooth"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.btEnabled = !actionCenterWindow.btEnabled
                Quickshell.execDetached("bluetoothctl power " + (actionCenterWindow.btEnabled ? "on" : "off"))
              }
            }
          }

          // Airplane Mode Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "✈️"; font.pixelSize: 18 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Airplane"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached("rfkill toggle all")
              }
            }
          }

          // Battery Saver Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: actionCenterWindow.batterySaverEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🔋"; font.pixelSize: 18 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Saver"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.batterySaverEnabled = !actionCenterWindow.batterySaverEnabled
              }
            }
          }

          // Night Light Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: actionCenterWindow.nightLightEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🌙"; font.pixelSize: 18 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Night Light"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.nightLightEnabled = !actionCenterWindow.nightLightEnabled
                Quickshell.execDetached("hyprsunset -t 4500 || pkill hyprsunset")
              }
            }
          }

          // Accessibility Tile
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 3
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "♿"; font.pixelSize: 18 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Access"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached("omarchy-undercover-settings")
              }
            }
          }
        }

        // 2. Brightness Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text { text: "☀️"; font.pixelSize: 16 }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * (actionCenterWindow.brightnessVal / 100.0)
              radius: 3
              color: "#0078d4"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                var pct = Math.max(10, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = pct
                Quickshell.execDetached("brightnessctl set " + pct + "% || true")
              }
            }
          }

          Text {
            text: actionCenterWindow.brightnessVal + "%"
            color: "#ffffff"
            font.pixelSize: 11
            implicitWidth: 32
          }
        }

        // 3. Volume Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text { text: "🔊"; font.pixelSize: 16 }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * (actionCenterWindow.volumeVal / 100.0)
              radius: 3
              color: "#0078d4"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                var pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = pct
                Quickshell.execDetached("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0))
              }
            }
          }

          Text {
            text: actionCenterWindow.volumeVal + "%"
            color: "#ffffff"
            font.pixelSize: 11
            implicitWidth: 32
          }
        }

        Item { Layout.fillHeight: true }

        // 4. Footer: Battery & Settings Shortcut
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 48
          radius: 10
          color: Qt.rgba(0.08, 0.08, 0.11, 0.85)
          border.color: Qt.rgba(1, 1, 1, 0.08)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            RowLayout {
              spacing: 6
              Text { text: "🔋"; font.pixelSize: 14 }
              Text { text: "94% • Fully Charged"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              implicitWidth: 32
              implicitHeight: 32
              radius: 6
              color: setM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
              Text { anchors.centerIn: parent; text: "⚙️"; font.pixelSize: 13 }
              MouseArea {
                id: setM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  Quickshell.execDetached("omarchy-undercover-settings")
                }
              }
            }
          }
        }
      }
    }
  }
}
