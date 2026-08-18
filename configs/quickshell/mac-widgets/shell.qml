import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: macWidgetsWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
      bottom: true
    }
    margins {
      top: 36
      right: 12
      bottom: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 440

    property bool wifiOn: true
    property bool btOn: true
    property int masterVolume: 70
    property int displayBrightness: 85
    property int batteryPct: 90
    property string wifiSsid: "Home Network"

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Live Hardware Poller
    Process {
      id: statePoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '85'); " +
        "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Home Network'); " +
        "echo \"$wifi|$bt|$vol|$bri|$bat|$ssid\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var parts = line.trim().split("|")
          if (parts.length >= 6) {
            macWidgetsWindow.wifiOn = (parts[0].indexOf("enabled") !== -1)
            macWidgetsWindow.btOn = (parts[1] === "1")
            var v = parseInt(parts[2])
            if (!isNaN(v)) macWidgetsWindow.masterVolume = Math.max(0, Math.min(100, v))
            var b = parseInt(parts[3])
            if (!isNaN(b)) macWidgetsWindow.displayBrightness = Math.max(5, Math.min(100, b))
            var bt = parseInt(parts[4])
            if (!isNaN(bt)) macWidgetsWindow.batteryPct = Math.max(1, Math.min(100, bt))
            if (parts[5]) macWidgetsWindow.wifiSsid = parts[5]
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
        if (!statePoller.running) statePoller.running = true
      }
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 22
      color: Qt.rgba(0.08, 0.08, 0.12, 0.95)
      border.color: Qt.rgba(1, 1, 1, 0.18)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "Widgets"
            color: "#ffffff"
            font.pixelSize: 22
            font.weight: Font.Bold
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.12)
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: "#ffffff"
              font.pixelSize: 12
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // 1. Live Connectivity & Audio Control Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 146
          radius: 16
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.12)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Top Buttons: Wi-Fi and Bluetooth
            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              // Wi-Fi Button
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 10
                color: macWidgetsWindow.wifiOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.10)
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text { text: "󰤨"; font.pixelSize: 14; color: "#ffffff" }
                  Text {
                    text: macWidgetsWindow.wifiOn ? macWidgetsWindow.wifiSsid : "Wi-Fi Off"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    elide: Text.ElideRight
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    macWidgetsWindow.wifiOn = !macWidgetsWindow.wifiOn
                    macWidgetsWindow.runCmd("nmcli radio wifi " + (macWidgetsWindow.wifiOn ? "on" : "off"))
                  }
                }
              }

              // Bluetooth Button
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 10
                color: macWidgetsWindow.btOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.10)
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text { text: "󰂯"; font.pixelSize: 14; color: "#ffffff" }
                  Text {
                    text: macWidgetsWindow.btOn ? "Bluetooth On" : "Bluetooth Off"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    macWidgetsWindow.btOn = !macWidgetsWindow.btOn
                    macWidgetsWindow.runCmd("bluetoothctl power " + (macWidgetsWindow.btOn ? "on" : "off"))
                  }
                }
              }
            }

            // Sound Slider
            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "🔊"; font.pixelSize: 12 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)
                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (macWidgetsWindow.masterVolume / 100.0)
                  radius: 3
                  color: "#007aff"
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                    macWidgetsWindow.masterVolume = pct
                    macWidgetsWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0) + " || pactl set-sink-volume @DEFAULT_SINK@ " + pct + "% || true")
                  }
                }
              }
              Text { text: macWidgetsWindow.masterVolume + "%"; font.pixelSize: 10; color: "#ffffff"; implicitWidth: 30 }
            }

            // Display Brightness Slider
            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "☀️"; font.pixelSize: 12 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)
                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (macWidgetsWindow.displayBrightness / 100.0)
                  radius: 3
                  color: "#ffffff"
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                    macWidgetsWindow.displayBrightness = pct
                    macWidgetsWindow.runCmd("brightnessctl set " + pct + "% || true")
                  }
                }
              }
              Text { text: macWidgetsWindow.displayBrightness + "%"; font.pixelSize: 10; color: "#ffffff"; implicitWidth: 30 }
            }
          }
        }

        // 2. Weather 2x2 Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 110
          radius: 16
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.12)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "WEATHER • CUPERTINO"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }
            RowLayout {
              Text { text: "72°"; color: "#ffffff"; font.pixelSize: 32; font.weight: Font.ExtraBold }
              ColumnLayout {
                Text { text: "Sunny"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold }
                Text { text: "H: 76°  L: 58° • 0% Rain"; color: Qt.rgba(1, 1, 1, 0.65); font.pixelSize: 11 }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: macWidgetsWindow.runCmd("xdg-open https://weather.com")
          }
        }

        // 3. Apple Stocks Watchlist Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 120
          radius: 16
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.12)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "STOCKS"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }

            RowLayout {
              Text { text: "AAPL"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "$224.50"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              Text { text: "+0.85%"; color: "#34c759"; font.pixelSize: 11; font.weight: Font.Bold }
            }

            RowLayout {
              Text { text: "MSFT"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "$448.20"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              Text { text: "+1.25%"; color: "#34c759"; font.pixelSize: 11; font.weight: Font.Bold }
            }

            RowLayout {
              Text { text: "NVDA"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "$128.90"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              Text { text: "+3.10%"; color: "#34c759"; font.pixelSize: 11; font.weight: Font.Bold }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: macWidgetsWindow.runCmd("xdg-open https://finance.yahoo.com")
          }
        }

        // 4. Multi-Device Batteries Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 100
          radius: 16
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.12)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text { text: "BATTERIES"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }

            RowLayout {
              Layout.fillWidth: true
              spacing: 12

              // MacBook Battery
              RowLayout {
                spacing: 6
                Text { text: "💻"; font.pixelSize: 14 }
                Text { text: macWidgetsWindow.batteryPct + "%"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              }

              // iPhone Battery
              RowLayout {
                spacing: 6
                Text { text: "📱"; font.pixelSize: 14 }
                Text { text: "88%"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              }

              // AirPods Pro Battery
              RowLayout {
                spacing: 6
                Text { text: "🎧"; font.pixelSize: 14 }
                Text { text: "100%"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
              }
            }
          }
        }

        Item { Layout.fillHeight: true }
      }
    }
  }
}
