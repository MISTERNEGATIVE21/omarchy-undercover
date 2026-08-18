import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: macSoundWindow
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

    implicitWidth: 340
    implicitHeight: 360

    property bool isDark: true
    property real volumeLevel: 0.65
    property bool isMuted: false
    property var audioSinks: []

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          macSoundWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Volume level poller
    Process {
      id: volPoller
      running: true
      command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.65'"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          macSoundWindow.isMuted = (l.indexOf("[MUTED]") !== -1)
          var parts = l.replace("[MUTED]", "").trim().split(" ")
          if (parts.length >= 2) {
            var val = parseFloat(parts[1])
            if (!isNaN(val)) {
              macSoundWindow.volumeLevel = Math.min(1.0, Math.max(0.0, val))
            }
          }
        }
      }
    }

    // Audio Sinks query
    Process {
      id: sinksPoller
      command: ["bash", "-c", "wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep -E '[0-9]+\\.'"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var isDefault = (l.indexOf("*") !== -1)
          var clean = l.replace("*", "").trim()
          var parts = clean.split(".")
          if (parts.length >= 2) {
            var id = parseInt(parts[0].trim())
            var name = parts.slice(1).join(".").trim()
            var currentList = macSoundWindow.audioSinks
            var exists = false
            for (var i = 0; i < currentList.length; i++) {
              if (currentList[i].id === id) {
                currentList[i].name = name
                currentList[i].isDefault = isDefault
                exists = true
                break
              }
            }
            if (!exists) {
              currentList.push({
                id: id,
                name: name,
                isDefault: isDefault,
                type: (name.toLowerCase().indexOf("head") !== -1 || name.toLowerCase().indexOf("airpods") !== -1) ? "🎧" : "🔊"
              })
            }
            macSoundWindow.audioSinks = currentList
          }
        }
      }
    }

    Timer {
      interval: 4000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!volPoller.running) volPoller.running = true
        if (!sinksPoller.running) sinksPoller.running = true
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: macSoundWindow.isDark ? Qt.rgba(0.12, 0.12, 0.17, 0.90) : Qt.rgba(0.96, 0.96, 0.98, 0.92)
      border.color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Sound"
            font.family: "SF Pro Text"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: closeM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a" }
            MouseArea {
              id: closeM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Apple Style Sound Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 10
          color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              Text { text: "🔊"; font.pixelSize: 13 }
              Slider {
                id: macSlider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: macSoundWindow.volumeLevel
                onMoved: {
                  macSoundWindow.volumeLevel = value
                  macSoundWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + value.toFixed(2))
                }
              }
              Text {
                text: Math.round(macSoundWindow.volumeLevel * 100) + "%"
                font.family: "SF Pro Text"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
            }
          }
        }

        // Output Section Title
        Text {
          text: "Output"
          font.family: "SF Pro Text"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macSinkList
            width: parent.width
            model: macSoundWindow.audioSinks
            spacing: 3

            delegate: Rectangle {
              width: macSinkList.width
              implicitHeight: 36
              radius: 6
              color: modelData.isDefault
                     ? (macSoundWindow.isDark ? Qt.rgba(0, 122, 255, 0.25) : Qt.rgba(0, 122, 255, 0.15))
                     : (macSinkRowM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text { text: modelData.type; font.pixelSize: 15 }
                Text {
                  text: modelData.name
                  font.family: "SF Pro Text"
                  font.pixelSize: 12
                  color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  visible: modelData.isDefault
                  text: "✓"
                  font.pixelSize: 12
                  color: "#007aff"
                  font.weight: Font.Bold
                }
              }

              MouseArea {
                id: macSinkRowM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  macSoundWindow.runCmd("wpctl set-default " + modelData.id)
                  if (!sinksPoller.running) sinksPoller.running = true
                }
              }
            }
          }
        }

        // Footer Link
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: 6
          color: soundPrefM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "Sound Settings..."
            font.family: "SF Pro Text"
            font.pixelSize: 11
            color: "#007aff"
          }
          MouseArea {
            id: soundPrefM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              macSoundWindow.runCmd("pavucontrol || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}
