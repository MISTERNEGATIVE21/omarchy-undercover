import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: soundWindow
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

    implicitWidth: 360
    implicitHeight: 380

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
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          soundWindow.isDark = (s.indexOf("light") === -1)
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
          // Volume: 0.65 [MUTED]
          soundWindow.isMuted = (l.indexOf("[MUTED]") !== -1)
          var parts = l.replace("[MUTED]", "").trim().split(" ")
          if (parts.length >= 2) {
            var val = parseFloat(parts[1])
            if (!isNaN(val)) {
              soundWindow.volumeLevel = Math.min(1.0, Math.max(0.0, val))
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
            var currentList = soundWindow.audioSinks
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
            soundWindow.audioSinks = currentList
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
      radius: 14
      color: soundWindow.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.96) : Qt.rgba(0.97, 0.97, 0.98, 0.98)
      border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: soundWindow.isMuted ? "󰝟" : (soundWindow.volumeLevel > 0.5 ? "󰕾" : "󰖀")
            font.pixelSize: 18
            color: soundWindow.isDark ? "#60cdff" : "#0067c0"
          }

          Text {
            text: "Sound Output"
            font.family: "Segoe UI"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: closeMouse.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
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

        // Master Volume Card & Slider
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 74
          radius: 8
          color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
          border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Volume"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                Layout.fillWidth: true
              }
              Text {
                text: Math.round(soundWindow.volumeLevel * 100) + "%"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: soundWindow.isDark ? "#60cdff" : "#0067c0"
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 4
                color: muteBtnM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: soundWindow.isMuted ? "󰝟" : "󰕾"
                  font.pixelSize: 14
                  color: soundWindow.isMuted ? "#ff5f56" : (soundWindow.isDark ? "#ffffff" : "#1a1a1a")
                }
                MouseArea {
                  id: muteBtnM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    soundWindow.isMuted = !soundWindow.isMuted
                    soundWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                  }
                }
              }

              Slider {
                id: volSlider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: soundWindow.volumeLevel
                onMoved: {
                  soundWindow.volumeLevel = value
                  soundWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + value.toFixed(2))
                }
              }
            }
          }
        }

        // Output Device List Title
        Text {
          text: "Select Output Device"
          font.family: "Segoe UI"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.5)
        }

        // Output Sinks ScrollView
        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: sinkListView
            width: parent.width
            model: soundWindow.audioSinks
            spacing: 4

            delegate: Rectangle {
              width: sinkListView.width
              implicitHeight: 40
              radius: 6
              color: modelData.isDefault
                     ? (soundWindow.isDark ? Qt.rgba(0, 120, 212, 0.30) : Qt.rgba(0, 120, 212, 0.15))
                     : (sinkRowM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
              border.color: modelData.isDefault ? (soundWindow.isDark ? "#60cdff" : "#0067c0") : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text { text: modelData.type; font.pixelSize: 16 }
                Text {
                  text: modelData.name
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                  color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  visible: modelData.isDefault
                  text: "✓"
                  font.pixelSize: 12
                  color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                  font.weight: Font.Bold
                }
              }

              MouseArea {
                id: sinkRowM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  soundWindow.runCmd("wpctl set-default " + modelData.id)
                  if (!sinksPoller.running) sinksPoller.running = true
                }
              }
            }
          }
        }

        // Footer Link
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 6
          color: soundSetLinkM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚙️"; font.pixelSize: 12 }
            Text {
              text: "More sound settings"
              font.family: "Segoe UI"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: soundWindow.isDark ? "#60cdff" : "#0067c0"
            }
          }
          MouseArea {
            id: soundSetLinkM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              soundWindow.runCmd("pavucontrol || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}
