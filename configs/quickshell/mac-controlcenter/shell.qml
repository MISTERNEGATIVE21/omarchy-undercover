import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
      right: 14
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 520

    property string homeDir: Quickshell.env("HOME")
    property bool isLight: false
    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property int displayBrightness: 85
    property int masterVolume: 70
    property string wifiSsid: "Wi-Fi"
    property string btDeviceName: "Bluetooth"
    property string musicTitle: "No Track Playing"
    property string musicArtist: "Media Player"
    property bool musicPlaying: false

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
      path: controlCenterWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        controlCenterWindow.isLight = (s.indexOf("light") !== -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        controlCenterWindow.isLight = (s.indexOf("light") !== -1)
      }
    }

    // Live Hardware State Poller
    Process {
      id: hwPoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '85'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Wi-Fi'); " +
        "track=$(playerctl metadata title 2>/dev/null || echo 'No Track Playing'); " +
        "artist=$(playerctl metadata artist 2>/dev/null || echo 'Media Player'); " +
        "mstatus=$(playerctl status 2>/dev/null || echo 'Stopped'); " +
        "echo \"$wifi|$bt|$vol|$bri|$ssid|$track|$artist|$mstatus\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var p = line.trim().split("|")
          if (p.length >= 8) {
            controlCenterWindow.wifiOn = (p[0].indexOf("enabled") !== -1)
            controlCenterWindow.btOn = (p[1] === "1")
            var v = parseInt(p[2]); if (!isNaN(v)) controlCenterWindow.masterVolume = Math.max(0, Math.min(100, v))
            var b = parseInt(p[3]); if (!isNaN(b)) controlCenterWindow.displayBrightness = Math.max(5, Math.min(100, b))
            if (p[4]) controlCenterWindow.wifiSsid = p[4]
            if (p[5]) controlCenterWindow.musicTitle = p[5]
            if (p[6]) controlCenterWindow.musicArtist = p[6]
            controlCenterWindow.musicPlaying = (p[7].toLowerCase() === "playing")
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
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Outer Frosted Glass Container
    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 18
      color: controlCenterWindow.isLight ? Qt.rgba(0.96, 0.96, 0.98, 0.82) : Qt.rgba(0.12, 0.12, 0.16, 0.82)
      border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.18)
      border.width: 1

      // Top Specular Highlight
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Qt.rgba(1, 1, 1, 0.35)
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Row 1: 2-Column Bento Grid (Network / Controls & Toggles)
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          // Left Bento Box: Wi-Fi & Bluetooth
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 130
            radius: 14
            color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
            border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              // Wi-Fi Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  width: 34
                  height: 34
                  radius: 17
                  color: controlCenterWindow.wifiOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.14)

                  Text {
                    anchors.centerIn: parent
                    text: "󰤨"
                    font.pixelSize: 16
                    color: "#ffffff"
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

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    text: "Wi-Fi"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                  }
                  Text {
                    text: controlCenterWindow.wifiOn ? controlCenterWindow.wifiSsid : "Off"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 10
                    color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.55)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                Text {
                  text: "›"
                  font.pixelSize: 18
                  color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterWindow.runCmd("omarchy-mac-wifi")
                  }
                }
              }

              Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

              // Bluetooth Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  width: 34
                  height: 34
                  radius: 17
                  color: controlCenterWindow.btOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.14)

                  Text {
                    anchors.centerIn: parent
                    text: "󰂯"
                    font.pixelSize: 16
                    color: "#ffffff"
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

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    text: "Bluetooth"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                  }
                  Text {
                    text: controlCenterWindow.btOn ? "On" : "Off"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 10
                    color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.55)
                  }
                }

                Text {
                  text: "›"
                  font.pixelSize: 18
                  color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterWindow.runCmd("omarchy-mac-bluetooth")
                  }
                }
              }
            }
          }

          // Right Bento Box: AirDrop & Focus pills
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // AirDrop Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 60
              radius: 14
              color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
              border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                  width: 30
                  height: 30
                  radius: 15
                  color: "#007aff"
                  Text { anchors.centerIn: parent; text: "󰀲"; font.pixelSize: 14; color: "#ffffff" }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text { text: "AirDrop"; font.pixelSize: 12; font.bold: true; color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff" }
                  Text { text: "Contacts Only"; font.pixelSize: 10; color: controlCenterWindow.isLight ? Qt.rgba(0,0,0,0.55) : Qt.rgba(1,1,1,0.55) }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: controlCenterWindow.runCmd("omarchy-undercover-settings -a")
              }
            }

            // Do Not Disturb / Focus Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 60
              radius: 14
              color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
              border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                  width: 30
                  height: 30
                  radius: 15
                  color: controlCenterWindow.dndOn ? "#5856d6" : Qt.rgba(1, 1, 1, 0.14)
                  Text { anchors.centerIn: parent; text: "󰂛"; font.pixelSize: 14; color: "#ffffff" }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text { text: "Focus"; font.pixelSize: 12; font.bold: true; color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff" }
                  Text { text: controlCenterWindow.dndOn ? "Do Not Disturb" : "Off"; font.pixelSize: 10; color: controlCenterWindow.isLight ? Qt.rgba(0,0,0,0.55) : Qt.rgba(1,1,1,0.55) }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  controlCenterWindow.dndOn = !controlCenterWindow.dndOn
                  controlCenterWindow.runCmd("makoctl mode -t dnd 2>/dev/null || true")
                }
              }
            }
          }
        }

        // Row 2: Display Brightness Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Display"; font.pixelSize: 11; font.bold: true; color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: controlCenterWindow.displayBrightness + "%"; font.pixelSize: 11; color: controlCenterWindow.isLight ? Qt.rgba(0,0,0,0.55) : Qt.rgba(1,1,1,0.55) }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 24
              radius: 12
              color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14)
              clip: true

              Rectangle {
                width: parent.width * (controlCenterWindow.displayBrightness / 100.0)
                height: parent.height
                radius: 12
                color: "#ffffff"
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                font.pixelSize: 13
                color: controlCenterWindow.displayBrightness > 15 ? "#1a1a1a" : "#ffffff"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                  var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.displayBrightness = p
                  controlCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
                }
                onClicked: function(mouse) {
                  var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.displayBrightness = p
                  controlCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
                }
              }
            }
          }
        }

        // Row 3: Sound Volume Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Sound"; font.pixelSize: 11; font.bold: true; color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: controlCenterWindow.masterVolume + "%"; font.pixelSize: 11; color: controlCenterWindow.isLight ? Qt.rgba(0,0,0,0.55) : Qt.rgba(1,1,1,0.55) }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 24
              radius: 12
              color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14)
              clip: true

              Rectangle {
                width: parent.width * (controlCenterWindow.masterVolume / 100.0)
                height: parent.height
                radius: 12
                color: "#ffffff"
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "󰕾"
                font.pixelSize: 13
                color: controlCenterWindow.masterVolume > 15 ? "#1a1a1a" : "#ffffff"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.masterVolume = p
                  controlCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
                }
                onClicked: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.masterVolume = p
                  controlCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
                }
              }
            }
          }
        }

        // Row 4: Now Playing / MPRIS Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 74
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
              width: 44
              height: 44
              radius: 8
              color: "#fa2d48"

              Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.pixelSize: 20
                color: "#ffffff"
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: controlCenterWindow.musicTitle
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: controlCenterWindow.musicArtist
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 10
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            RowLayout {
              spacing: 6

              Text {
                text: "󰒮"
                font.pixelSize: 18
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenterWindow.runCmd("playerctl previous") }
              }

              Text {
                text: controlCenterWindow.musicPlaying ? "󰏤" : "󰐊"
                font.pixelSize: 22
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.musicPlaying = !controlCenterWindow.musicPlaying
                    controlCenterWindow.runCmd("playerctl play-pause")
                  }
                }
              }

              Text {
                text: "󰒭"
                font.pixelSize: 18
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenterWindow.runCmd("playerctl next") }
              }
            }
          }
        }
      }
    }
  }
}
