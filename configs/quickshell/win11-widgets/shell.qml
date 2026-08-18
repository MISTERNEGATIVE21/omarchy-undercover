import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: widgetsWindow
    screen: Quickshell.screens[0]

    anchors {
      left: true
      bottom: true
    }
    margins {
      left: 12
      bottom: 54
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 520
    implicitHeight: 780

    property bool wifiEnabled: true
    property bool btEnabled: true
    property int volumeVal: 70
    property int brightnessVal: 80
    property int batteryPct: 90
    property string wifiSsid: "Connected"

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
            widgetsWindow.wifiEnabled = (parts[0].indexOf("enabled") !== -1)
            widgetsWindow.btEnabled = (parts[1] === "1")
            var v = parseInt(parts[2])
            if (!isNaN(v)) widgetsWindow.volumeVal = Math.max(0, Math.min(100, v))
            var b = parseInt(parts[3])
            if (!isNaN(b)) widgetsWindow.brightnessVal = Math.max(5, Math.min(100, b))
            var bt = parseInt(parts[4])
            if (!isNaN(bt)) widgetsWindow.batteryPct = Math.max(1, Math.min(100, bt))
            if (parts[5]) widgetsWindow.wifiSsid = parts[5]
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
      radius: 16
      color: Qt.rgba(0.09, 0.10, 0.13, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.14)
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
            text: "Widgets Board"
            color: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 20
            font.weight: Font.Bold
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: "#ffffff"
              font.pixelSize: 13
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // 1. Live Connectivity & Hardware Status Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 146
          radius: 12
          color: Qt.rgba(1, 1, 1, 0.07)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Top row: Wi-Fi, Bluetooth, Battery Toggles
            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              // Wi-Fi Button
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 8
                color: widgetsWindow.wifiEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text { text: "󰤨"; font.pixelSize: 15; color: "#ffffff" }
                  Text {
                    text: widgetsWindow.wifiEnabled ? widgetsWindow.wifiSsid : "Wi-Fi Off"
                    font.family: "Segoe UI"
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
                    widgetsWindow.wifiEnabled = !widgetsWindow.wifiEnabled
                    widgetsWindow.runCmd("nmcli radio wifi " + (widgetsWindow.wifiEnabled ? "on" : "off"))
                  }
                }
              }

              // Bluetooth Button
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 8
                color: widgetsWindow.btEnabled ? "#0078d4" : Qt.rgba(1, 1, 1, 0.08)
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text { text: "󰂯"; font.pixelSize: 15; color: "#ffffff" }
                  Text {
                    text: widgetsWindow.btEnabled ? "Bluetooth On" : "Bluetooth Off"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    widgetsWindow.btEnabled = !widgetsWindow.btEnabled
                    widgetsWindow.runCmd("bluetoothctl power " + (widgetsWindow.btEnabled ? "on" : "off"))
                  }
                }
              }

              // Battery Pill
              Rectangle {
                implicitWidth: 70
                implicitHeight: 44
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.08)
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 4
                  Text { text: "🔋"; font.pixelSize: 13 }
                  Text { text: widgetsWindow.batteryPct + "%"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: "#ffffff" }
                }
              }
            }

            // Sound Volume Slider Row
            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "🔊"; font.pixelSize: 13 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)
                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (widgetsWindow.volumeVal / 100.0)
                  radius: 3
                  color: "#0078d4"
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                    widgetsWindow.volumeVal = pct
                    widgetsWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0) + " || pactl set-sink-volume @DEFAULT_SINK@ " + pct + "% || true")
                  }
                }
              }
              Text { text: widgetsWindow.volumeVal + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: "#ffffff"; implicitWidth: 30 }
            }

            // Brightness Slider Row
            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "☀️"; font.pixelSize: 13 }
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)
                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * (widgetsWindow.brightnessVal / 100.0)
                  radius: 3
                  color: "#0078d4"
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    var pct = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                    widgetsWindow.brightnessVal = pct
                    widgetsWindow.runCmd("brightnessctl set " + pct + "% || true")
                  }
                }
              }
              Text { text: widgetsWindow.brightnessVal + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: "#ffffff"; implicitWidth: 30 }
            }
          }
        }

        // 2. Weather & Stocks Cards Grid
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          // Weather Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.07)
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 4

              RowLayout {
                Text { text: "MSN WEATHER"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "📍 Cupertino"; color: Qt.rgba(1, 1, 1, 0.6); font.family: "Segoe UI"; font.pixelSize: 10 }
              }

              RowLayout {
                spacing: 8
                Text { text: "🌤️"; font.pixelSize: 26 }
                ColumnLayout {
                  spacing: 0
                  Text { text: "72°F"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 22; font.weight: Font.Bold }
                  Text { text: "Partly sunny • H: 76° L: 58°"; color: Qt.rgba(1, 1, 1, 0.7); font.family: "Segoe UI"; font.pixelSize: 10 }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: widgetsWindow.runCmd("xdg-open https://www.msn.com/weather")
            }
          }

          // Stock Market Watchlist Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.07)
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 4

              Text { text: "WATCHLIST • MSN MONEY"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold }

              RowLayout {
                Text { text: "MSFT"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "$448.20"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold }
                Text { text: "+1.25%"; color: "#27c460"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold }
              }

              RowLayout {
                Text { text: "AAPL"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "$224.50"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold }
                Text { text: "+0.85%"; color: "#27c460"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold }
              }

              RowLayout {
                Text { text: "NVDA"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "$128.90"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold }
                Text { text: "+3.10%"; color: "#27c460"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: widgetsWindow.runCmd("xdg-open https://www.msn.com/money")
            }
          }
        }

        // 3. Microsoft To-Do Checklist Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 130
          radius: 12
          color: Qt.rgba(1, 1, 1, 0.07)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
              Text { text: "MICROSOFT TO-DO"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "3 tasks left"; color: "#60cdff"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.DemiBold }
            }

            RowLayout {
              spacing: 8
              Text { text: "☑️"; font.pixelSize: 12 }
              Text { text: "Deploy Quickshell Windows 11 widgets"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 12; Layout.fillWidth: true }
            }
            RowLayout {
              spacing: 8
              Text { text: "⬜"; font.pixelSize: 12 }
              Text { text: "Review Omarchy Undercover v2.5 documentation"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 12; Layout.fillWidth: true }
            }
            RowLayout {
              spacing: 8
              Text { text: "⬜"; font.pixelSize: 12 }
              Text { text: "Configure multi-monitor taskbar mirrors"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 12; Layout.fillWidth: true }
            }
          }
        }

        // 4. MSN News Feed Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 140
          radius: 12
          color: Qt.rgba(1, 1, 1, 0.07)
          border.color: Qt.rgba(1, 1, 1, 0.10)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
              Text { text: "TOP STORIES • MSN NEWS"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "Refresh ↻"; color: "#60cdff"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.DemiBold }
            }

            RowLayout {
              spacing: 8
              Text { text: "📰"; font.pixelSize: 15 }
              ColumnLayout {
                spacing: 1
                Text { text: "Omarchy Undercover Releases Full Quickshell Suite"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold }
                Text { text: "Pure QML widgets and 60fps animations arrive for Hyprland — TechNews • 15m ago"; color: Qt.rgba(1, 1, 1, 0.6); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }

            RowLayout {
              spacing: 8
              Text { text: "🚀"; font.pixelSize: 15 }
              ColumnLayout {
                spacing: 1
                Text { text: "Next-Gen AI Desktop Experiences Launch on Wayland"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold }
                Text { text: "Fluent design and mica glassmorphism revolutionize Linux desktops — TheVerge • 1h ago"; color: Qt.rgba(1, 1, 1, 0.6); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: widgetsWindow.runCmd("xdg-open https://www.msn.com/news")
          }
        }

        Item { Layout.fillHeight: true }
      }
    }
  }
}
