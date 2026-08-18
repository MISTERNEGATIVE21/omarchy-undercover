import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
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
    implicitHeight: 500

    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool nightLightEnabled: false
    property bool batterySaverEnabled: false
    property int volumeVal: 70
    property int brightnessVal: 80
    property int batteryPct: 90
    property string wifiSsid: "Connected"
    property string btDevice: "Active"

    // Helper runner
    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // 1. Live State Polling Process
    Process {
      id: statePoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '80'); " +
        "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Connected'); " +
        "echo \"$wifi|$bt|$vol|$bri|$bat|$ssid\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var parts = line.trim().split("|")
          if (parts.length >= 6) {
            actionCenterWindow.wifiEnabled = (parts[0].indexOf("enabled") !== -1)
            actionCenterWindow.btEnabled = (parts[1] === "1")
            var v = parseInt(parts[2])
            if (!isNaN(v)) actionCenterWindow.volumeVal = Math.max(0, Math.min(100, v))
            var b = parseInt(parts[3])
            if (!isNaN(b)) actionCenterWindow.brightnessVal = Math.max(5, Math.min(100, b))
            var bt = parseInt(parts[4])
            if (!isNaN(bt)) actionCenterWindow.batteryPct = Math.max(1, Math.min(100, bt))
            if (parts[5]) actionCenterWindow.wifiSsid = parts[5]
          }
        }
      }
    }

    Timer {
      interval: 2000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!statePoller.running) {
          statePoller.running = true
        }
      }
    }

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
        spacing: 12

        // Header with Title and Close Button
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "Quick Settings"
            color: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: "#ffffff"
              font.pixelSize: 12
            }
            MouseArea {
              id: closeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

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
                actionCenterWindow.runCmd("nmcli radio wifi " + (actionCenterWindow.wifiEnabled ? "on" : "off"))
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
                actionCenterWindow.runCmd("bluetoothctl power " + (actionCenterWindow.btEnabled ? "on" : "off"))
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
                actionCenterWindow.runCmd("rfkill toggle all")
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
                actionCenterWindow.runCmd("hyprsunset -t 4500 || pkill hyprsunset || true")
              }
            }
          }

          // Settings Shortcut Tile
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
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚙️"; font.pixelSize: 18 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Settings"; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#ffffff" }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                actionCenterWindow.runCmd("omarchy-undercover-settings")
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
            id: briTrack
            Layout.fillWidth: true
            implicitHeight: 8
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * (actionCenterWindow.brightnessVal / 100.0)
              radius: 4
              color: "#0078d4"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                var pct = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = pct
                actionCenterWindow.runCmd("brightnessctl set " + pct + "% || true")
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
            id: volTrack
            Layout.fillWidth: true
            implicitHeight: 8
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * (actionCenterWindow.volumeVal / 100.0)
              radius: 4
              color: "#0078d4"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                var pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = pct
                actionCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0) + " || pactl set-sink-volume @DEFAULT_SINK@ " + pct + "% || true")
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

        // 4. Footer: Live Battery & Settings Shortcut
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
              Text {
                text: actionCenterWindow.batteryPct + "% • " + actionCenterWindow.wifiSsid
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }
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
                  actionCenterWindow.runCmd("omarchy-undercover-settings")
                }
              }
            }
          }
        }
      }
    }
  }
}
