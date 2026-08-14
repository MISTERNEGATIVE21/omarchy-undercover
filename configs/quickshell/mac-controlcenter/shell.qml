import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: controlCenterWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }
    margins {
      top: 36
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 440

    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property int displayBrightness: 85
    property int masterVolume: 70
    property string wifiSsid: "Home Network"
    property string btDeviceName: "Active Device"

    // Helper runner
    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // 1. Live State Poller
    Process {
      id: statePoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '85'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Home Network'); " +
        "echo \"$wifi|$bt|$vol|$bri|$ssid\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var parts = line.trim().split("|")
          if (parts.length >= 5) {
            controlCenterWindow.wifiOn = (parts[0].indexOf("enabled") !== -1)
            controlCenterWindow.btOn = (parts[1] === "1")
            var v = parseInt(parts[2])
            if (!isNaN(v)) controlCenterWindow.masterVolume = Math.max(0, Math.min(100, v))
            var b = parseInt(parts[3])
            if (!isNaN(b)) controlCenterWindow.displayBrightness = Math.max(5, Math.min(100, b))
            if (parts[4]) controlCenterWindow.wifiSsid = parts[4]
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
      radius: 18
      color: Qt.rgba(0.12, 0.12, 0.16, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.18)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // 1. Top Section: Connectivity Hub + Focus
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          // Connectivity Card (Left)
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 140
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 8

              // Wi-Fi Row
              RowLayout {
                spacing: 8
                Rectangle {
                  implicitWidth: 28
                  implicitHeight: 28
                  radius: 14
                  color: controlCenterWindow.wifiOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.15)
                  Text { anchors.centerIn: parent; text: "󰤨"; color: "#ffffff"; font.pixelSize: 13 }
                }
                ColumnLayout {
                  spacing: 0
                  Text { text: "Wi-Fi"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
                  Text { text: controlCenterWindow.wifiOn ? controlCenterWindow.wifiSsid : "Off"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.wifiOn = !controlCenterWindow.wifiOn
                    controlCenterWindow.runCmd("nmcli radio wifi " + (controlCenterWindow.wifiOn ? "on" : "off"))
                  }
                }
              }

              // Bluetooth Row
              RowLayout {
                spacing: 8
                Rectangle {
                  implicitWidth: 28
                  implicitHeight: 28
                  radius: 14
                  color: controlCenterWindow.btOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.15)
                  Text { anchors.centerIn: parent; text: "󰂯"; color: "#ffffff"; font.pixelSize: 13 }
                }
                ColumnLayout {
                  spacing: 0
                  Text { text: "Bluetooth"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
                  Text { text: controlCenterWindow.btOn ? "On" : "Off"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.btOn = !controlCenterWindow.btOn
                    controlCenterWindow.runCmd("bluetoothctl power " + (controlCenterWindow.btOn ? "on" : "off"))
                  }
                }
              }

              // AirDrop Row
              RowLayout {
                spacing: 8
                Rectangle {
                  implicitWidth: 28
                  implicitHeight: 28
                  radius: 14
                  color: "#007aff"
                  Text { anchors.centerIn: parent; text: "󰕓"; color: "#ffffff"; font.pixelSize: 13 }
                }
                ColumnLayout {
                  spacing: 0
                  Text { text: "AirDrop"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
                  Text { text: "Contacts Only"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
                }
              }
            }
          }

          // Right Column: Do Not Disturb & Screen Mirroring
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Do Not Disturb Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 65
              radius: 14
              color: controlCenterWindow.dndOn ? "#5856d6" : Qt.rgba(1, 1, 1, 0.08)
              border.color: Qt.rgba(1, 1, 1, 0.10)

              RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "🌙"; font.pixelSize: 15 }
                Text { text: "Focus"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  controlCenterWindow.dndOn = !controlCenterWindow.dndOn
                }
              }
            }

            // Screen Mirroring Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 65
              radius: 14
              color: Qt.rgba(1, 1, 1, 0.08)
              border.color: Qt.rgba(1, 1, 1, 0.10)

              RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "🪞"; font.pixelSize: 15 }
                Text { text: "Stage Manager"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
              }
            }
          }
        }

        // 2. Display Brightness Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 62
          radius: 14
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Text { text: "DISPLAY"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "☀️"; font.pixelSize: 13 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 20
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.12)

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (controlCenterWindow.displayBrightness / 100.0)
                  radius: 10
                  color: "#ffffff"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                    controlCenterWindow.displayBrightness = pct
                    controlCenterWindow.runCmd("brightnessctl set " + pct + "% || true")
                  }
                }
              }
            }
          }
        }

        // 3. Sound Volume Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 62
          radius: 14
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Text { text: "SOUND"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "🔊"; font.pixelSize: 13 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 20
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.12)

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (controlCenterWindow.masterVolume / 100.0)
                  radius: 10
                  color: "#ffffff"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                    controlCenterWindow.masterVolume = pct
                    controlCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0) + " || pactl set-sink-volume @DEFAULT_SINK@ " + pct + "% || true")
                  }
                }
              }
            }
          }
        }

        // 4. Now Playing Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 68
          radius: 14
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
              implicitWidth: 44
              implicitHeight: 44
              radius: 8
              color: "#fa243c"
              Text { anchors.centerIn: parent; text: "🎵"; font.pixelSize: 20 }
            }

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text { text: "Apple Music"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold }
              Text { text: "Now Playing • Spatial Audio"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
            }

            RowLayout {
              spacing: 8
              Text {
                text: "⏮️"
                font.pixelSize: 13
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: controlCenterWindow.runCmd("playerctl previous || true")
                }
              }
              Text {
                text: "⏯️"
                font.pixelSize: 15
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: controlCenterWindow.runCmd("playerctl play-pause || true")
                }
              }
              Text {
                text: "⏭️"
                font.pixelSize: 13
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: controlCenterWindow.runCmd("playerctl next || true")
                }
              }
            }
          }
        }
      }
    }
  }
}
