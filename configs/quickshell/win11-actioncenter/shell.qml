import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: actionCenterWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
      right: true
    }
    margins {
      bottom: 52
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 380
    implicitHeight: 460

    property string homeDir: Quickshell.env("HOME")
    property bool isDark: true
    property bool isTransparent: true
    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool airplaneMode: false
    property bool nightLightEnabled: false
    property bool batterySaverEnabled: false
    property int volumeVal: 70
    property int brightnessVal: 80
    property int batteryPct: 90
    property bool isCharging: false
    property string wifiSsid: "Connected"
    property string btDevice: "Connected"

    Shortcut {
      sequence: "Escape"
      onActivated: Qt.quit()
    }

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Reactive Theme Poller
    FileView {
      id: stateWatcher
      path: actionCenterWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        actionCenterWindow.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        actionCenterWindow.isDark = (s.indexOf("light") === -1)
      }
    }

    // Live Hardware State Poller
    Process {
      id: statePoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '80'); " +
        "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'); " +
        "chg=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo 'Discharging'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Connected'); " +
        "echo \"$wifi|$bt|$vol|$bri|$bat|$chg|$ssid\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var p = line.trim().split("|")
          if (p.length >= 7) {
            actionCenterWindow.wifiEnabled = (p[0].indexOf("enabled") !== -1)
            actionCenterWindow.btEnabled = (p[1] === "1")
            var v = parseInt(p[2]); if (!isNaN(v)) actionCenterWindow.volumeVal = Math.max(0, Math.min(100, v))
            var b = parseInt(p[3]); if (!isNaN(b)) actionCenterWindow.brightnessVal = Math.max(5, Math.min(100, b))
            var bt = parseInt(p[4]); if (!isNaN(bt)) actionCenterWindow.batteryPct = Math.max(1, Math.min(100, bt))
            actionCenterWindow.isCharging = (p[5].toLowerCase().indexOf("charg") !== -1)
            if (p[6]) actionCenterWindow.wifiSsid = p[6]
          }
        }
      }
    }

    Timer {
      interval: 2500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!statePoller.running) statePoller.running = true
      }
    }

    // Windows 11 Fluent Acrylic Container
    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 12
      color: actionCenterWindow.isDark ? Qt.rgba(0.12, 0.13, 0.17, 0.94) : Qt.rgba(0.97, 0.97, 0.98, 0.94)
      border.color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // 1. Fluent 6-Toggle Grid (2 Columns x 3 Rows)
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 10
          columnSpacing: 10

          // Wi-Fi Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.wifiEnabled ? (actionCenterWindow.isDark ? "#0078d4" : "#0067c0") : (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8

              Text {
                text: "󰤨"
                font.pixelSize: 16
                color: "#ffffff"
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Wi-Fi"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: actionCenterWindow.wifiEnabled ? actionCenterWindow.wifiSsid : "Disconnected"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7); elide: Text.ElideRight; Layout.fillWidth: true }
              }

              Text {
                text: "›"
                font.pixelSize: 14
                color: Qt.rgba(1,1,1,0.6)
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  actionCenterWindow.runCmd("omarchy-wifi-manager")
                } else {
                  actionCenterWindow.wifiEnabled = !actionCenterWindow.wifiEnabled
                  actionCenterWindow.runCmd("nmcli radio wifi " + (actionCenterWindow.wifiEnabled ? "on" : "off"))
                }
              }
            }
          }

          // Bluetooth Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.btEnabled ? (actionCenterWindow.isDark ? "#0078d4" : "#0067c0") : (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8

              Text { text: "󰂯"; font.pixelSize: 16; color: "#ffffff" }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Bluetooth"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: actionCenterWindow.btEnabled ? actionCenterWindow.btDevice : "Off"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7) }
              }

              Text { text: "›"; font.pixelSize: 14; color: Qt.rgba(1,1,1,0.6) }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  actionCenterWindow.runCmd("omarchy-bluetooth-manager")
                } else {
                  actionCenterWindow.btEnabled = !actionCenterWindow.btEnabled
                  actionCenterWindow.runCmd("bluetoothctl power " + (actionCenterWindow.btEnabled ? "on" : "off"))
                }
              }
            }
          }

          // Airplane Mode Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.airplaneMode ? (actionCenterWindow.isDark ? "#0078d4" : "#0067c0") : (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text { text: "󰀝"; font.pixelSize: 16; color: "#ffffff" }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Airplane mode"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: actionCenterWindow.airplaneMode ? "On" : "Off"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7) }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.airplaneMode = !actionCenterWindow.airplaneMode
                actionCenterWindow.runCmd("rfkill " + (actionCenterWindow.airplaneMode ? "block all" : "unblock all"))
              }
            }
          }

          // Battery Saver Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.batterySaverEnabled ? (actionCenterWindow.isDark ? "#0078d4" : "#0067c0") : (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text { text: "󰂎"; font.pixelSize: 16; color: "#ffffff" }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Battery saver"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: actionCenterWindow.batterySaverEnabled ? "Active" : "Off"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7) }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.batterySaverEnabled = !actionCenterWindow.batterySaverEnabled
                actionCenterWindow.runCmd("powerprofilesctl set " + (actionCenterWindow.batterySaverEnabled ? "power-saver" : "balanced") + " 2>/dev/null || true")
              }
            }
          }

          // Night Light Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.nightLightEnabled ? (actionCenterWindow.isDark ? "#0078d4" : "#0067c0") : (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text { text: "󰖔"; font.pixelSize: 16; color: "#ffffff" }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Night light"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: actionCenterWindow.nightLightEnabled ? "On" : "Off"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7) }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.nightLightEnabled = !actionCenterWindow.nightLightEnabled
                actionCenterWindow.runCmd("omarchy toggle nightlight 2>/dev/null || hyprshade toggle blue-light-filter 2>/dev/null || true")
              }
            }
          }

          // Accessibility Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text { text: "󰌵"; font.pixelSize: 16; color: "#ffffff" }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Accessibility"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                Text { text: "Standard"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.7) }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.runCmd("omarchy-undercover-settings")
            }
          }
        }

        // 2. Brightness Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text { text: "󰃠"; font.pixelSize: 16; color: actionCenterWindow.isDark ? "#ffffff" : "#1a1a1a" }

          Rectangle {
            Layout.fillWidth: true
            height: 18
            radius: 9
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
            clip: true

            Rectangle {
              width: parent.width * (actionCenterWindow.brightnessVal / 100.0)
              height: parent.height
              radius: 9
              color: actionCenterWindow.isDark ? "#60cdff" : "#0067c0"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: function(mouse) {
                var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = p
                actionCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
              }
              onClicked: function(mouse) {
                var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = p
                actionCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
              }
            }
          }

          Text { text: actionCenterWindow.brightnessVal + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.7) }
        }

        // 3. Volume Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text { text: "󰕾"; font.pixelSize: 16; color: actionCenterWindow.isDark ? "#ffffff" : "#1a1a1a" }

          Rectangle {
            Layout.fillWidth: true
            height: 18
            radius: 9
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
            clip: true

            Rectangle {
              width: parent.width * (actionCenterWindow.volumeVal / 100.0)
              height: parent.height
              radius: 9
              color: actionCenterWindow.isDark ? "#60cdff" : "#0067c0"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = p
                actionCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
              onClicked: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = p
                actionCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
            }
          }

          Text { text: actionCenterWindow.volumeVal + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.7) }
        }

        // 4. Footer Bar with Battery & Settings Gear
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: 6
          color: actionCenterWindow.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.04)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            RowLayout {
              spacing: 6
              Text {
                text: actionCenterWindow.isCharging ? "󰂄" : "󰁹"
                font.pixelSize: 15
                color: actionCenterWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              Text {
                text: actionCenterWindow.batteryPct + "%"
                font.family: "Segoe UI"
                font.pixelSize: 11
                font.bold: true
                color: actionCenterWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "⚙"
              font.pixelSize: 16
              color: actionCenterWindow.isDark ? "#ffffff" : "#1a1a1a"
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
        }
      }
    }
  }
}
