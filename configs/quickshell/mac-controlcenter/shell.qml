import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
    property real displayBrightness: 85
    property real masterVolume: 70

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

        // 1. Top Section: 2 Columns (Connectivity on Left, Quick toggles on Right)
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
                  Text { text: controlCenterWindow.wifiOn ? "Home Network" : "Off"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.wifiOn = !controlCenterWindow.wifiOn
                    Quickshell.execDetached("nmcli radio wifi " + (controlCenterWindow.wifiOn ? "on" : "off"))
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
                  Text { text: controlCenterWindow.btOn ? "AirPods Pro" : "Off"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10 }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.btOn = !controlCenterWindow.btOn
                    Quickshell.execDetached("bluetoothctl power " + (controlCenterWindow.btOn ? "on" : "off"))
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

          // Right Column: Do Not Disturb & Stage Manager
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
                Text { text: "Screen Mirroring"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
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
                    var pct = Math.max(10, Math.min(100, Math.round((mouse.x / width) * 100)))
                    controlCenterWindow.displayBrightness = pct
                    Quickshell.execDetached("brightnessctl set " + pct + "% || true")
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
                    Quickshell.execDetached("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (pct / 100.0))
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
              Text { text: "⏮️"; font.pixelSize: 13 }
              Text { text: "▶️"; font.pixelSize: 15 }
              Text { text: "⏭️"; font.pixelSize: 13 }
            }
          }
        }
      }
    }
  }
}
