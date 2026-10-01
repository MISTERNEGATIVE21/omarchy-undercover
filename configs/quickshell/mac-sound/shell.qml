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
      top: 8
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: Math.min(350, (screen ? screen.width : 1280) - 24)
    implicitHeight: Math.min(500, (screen ? screen.height : 720) - 50)

    property bool isDark: true

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    AudioService {
      id: audioService
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy/plugins/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          macSoundWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    function getDeviceIcon(desc, name, isSource) {
      var d = ((desc || "") + " " + (name || "")).toLowerCase()
      if (isSource) {
        if (d.indexOf("headset") !== -1 || d.indexOf("airpods") !== -1) return "🎧"
        if (d.indexOf("webcam") !== -1 || d.indexOf("camera") !== -1) return "📷"
        return "🎙️"
      }
      if (d.indexOf("airpods") !== -1 || d.indexOf("headphone") !== -1 || d.indexOf("headset") !== -1) return "🎧"
      if (d.indexOf("hdmi") !== -1 || d.indexOf("displayport") !== -1 || d.indexOf("tv") !== -1) return "📺"
      if (d.indexOf("blue") !== -1) return "📶"
      return "🔊"
    }

    function getAppIcon(stream) {
      var n = ((stream.binary || "") + " " + (stream.app_name || "") + " " + (stream.name || "")).toLowerCase()
      if (n.indexOf("firefox") !== -1 || n.indexOf("chrome") !== -1 || n.indexOf("browser") !== -1 || n.indexOf("brave") !== -1) return "🌐"
      if (n.indexOf("spotify") !== -1 || n.indexOf("music") !== -1 || n.indexOf("amberol") !== -1) return "🎵"
      if (n.indexOf("discord") !== -1 || n.indexOf("slack") !== -1 || n.indexOf("telegram") !== -1) return "💬"
      if (n.indexOf("vlc") !== -1 || n.indexOf("mpv") !== -1 || n.indexOf("video") !== -1) return "🎬"
      if (n.indexOf("game") !== -1 || n.indexOf("steam") !== -1) return "🎮"
      return "🎚️"
    }

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: macSoundWindow.isDark ? Qt.rgba(0.12, 0.12, 0.17, 0.94) : Qt.rgba(0.96, 0.96, 0.98, 0.94)
      border.color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1
      opacity: 0
      scale: 0.97

      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Component.onCompleted: {
        opacity = 1.0
        scale = 1.0
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Sound"
            font.family: "SF Pro Text, -apple-system, sans-serif"
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
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 11
              color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
            }
            MouseArea {
              id: closeM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Apple Style Master Output Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 10
          color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
          border.color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
              implicitWidth: 28
              implicitHeight: 28
              radius: 6
              color: spkMuteM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
              Text {
                anchors.centerIn: parent
                text: audioService.masterMuted ? "🔇" : (audioService.masterVolume === 0 ? "🔈" : (audioService.masterVolume > 50 ? "🔊" : "🔉"))
                font.pixelSize: 15
              }
              MouseArea {
                id: spkMuteM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: audioService.toggleMasterMute()
              }
            }

            Slider {
              id: masterSlider
              Layout.fillWidth: true
              from: 0
              to: 100
              stepSize: 1
              value: audioService.masterVolume
              onMoved: audioService.setMasterVolume(Math.round(value))

              background: Rectangle {
                x: masterSlider.leftPadding
                y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                implicitWidth: 160
                implicitHeight: 6
                width: masterSlider.availableWidth
                height: 6
                radius: 3
                color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                Rectangle {
                  width: masterSlider.visualPosition * parent.width
                  height: parent.height
                  color: audioService.masterMuted ? "#8e8e93" : "#007aff"
                  radius: 3
                }
              }

              handle: Rectangle {
                x: masterSlider.leftPadding + masterSlider.visualPosition * (masterSlider.availableWidth - width)
                y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "#ffffff"
                border.color: Qt.rgba(0, 0, 0, 0.2)
                border.width: 1
              }
            }

            Text {
              text: audioService.masterMuted ? "Mute" : (audioService.masterVolume + "%")
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: audioService.masterMuted ? "#8e8e93" : (macSoundWindow.isDark ? "#ffffff" : "#1a1a1a")
              Layout.preferredWidth: 34
              horizontalAlignment: Text.AlignRight
            }
          }
        }

        // Scrollable Audio Sections (Output, Input, Streams)
        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ColumnLayout {
            width: parent.width
            spacing: 12

            // ==========================================
            // OUTPUT DEVICES SECTION
            // ==========================================
            Text {
              text: "OUTPUT"
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 10
              font.weight: Font.Bold
              color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 3

              Repeater {
                model: audioService.sinks
                delegate: Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 34
                  radius: 8
                  color: modelData.is_default
                         ? (macSoundWindow.isDark ? Qt.rgba(0, 122, 255, 0.25) : Qt.rgba(0, 122, 255, 0.15))
                         : (sinkRowM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                      text: macSoundWindow.getDeviceIcon(modelData.description, modelData.name, false)
                      font.pixelSize: 14
                    }
                    Text {
                      text: modelData.description || modelData.name
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      visible: modelData.is_default
                      text: "✓"
                      font.pixelSize: 12
                      color: "#007aff"
                      font.weight: Font.Bold
                    }
                  }

                  MouseArea {
                    id: sinkRowM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioService.setDefaultSink(modelData.name)
                  }
                }
              }
            }

            // Divider
            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
            }

            // ==========================================
            // INPUT (MICROPHONE) SECTION
            // ==========================================
            Text {
              text: "INPUT"
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 10
              font.weight: Font.Bold
              color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
            }

            // Mic Slider Row
            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: 4
                color: micMuteM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: audioService.micMuted ? "🔇" : "🎙️"
                  font.pixelSize: 13
                }
                MouseArea {
                  id: micMuteM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: audioService.toggleMicMute()
                }
              }

              Slider {
                id: micSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
                value: audioService.micVolume
                onMoved: audioService.setMicVolume(Math.round(value))

                background: Rectangle {
                  x: micSlider.leftPadding
                  y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                  implicitWidth: 160
                  implicitHeight: 5
                  width: micSlider.availableWidth
                  height: 5
                  radius: 3
                  color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                  Rectangle {
                    width: micSlider.visualPosition * parent.width
                    height: parent.height
                    color: audioService.micMuted ? "#8e8e93" : "#34c759"
                    radius: 3
                  }
                }

                handle: Rectangle {
                  x: micSlider.leftPadding + micSlider.visualPosition * (micSlider.availableWidth - width)
                  y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                  implicitWidth: 14
                  implicitHeight: 14
                  radius: 7
                  color: "#ffffff"
                  border.color: Qt.rgba(0, 0, 0, 0.2)
                  border.width: 1
                }
              }

              Text {
                text: audioService.micMuted ? "Mute" : (audioService.micVolume + "%")
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 11
                color: audioService.micMuted ? "#8e8e93" : (macSoundWindow.isDark ? "#ffffff" : "#1a1a1a")
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
              }
            }

            // Input Sources List
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 3

              Repeater {
                model: audioService.sources
                delegate: Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 32
                  radius: 8
                  color: modelData.is_default
                         ? (macSoundWindow.isDark ? Qt.rgba(52, 199, 89, 0.22) : Qt.rgba(52, 199, 89, 0.15))
                         : (sourceRowM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                      text: macSoundWindow.getDeviceIcon(modelData.description, modelData.name, true)
                      font.pixelSize: 13
                    }
                    Text {
                      text: modelData.description || modelData.name
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 11
                      color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      visible: modelData.is_default
                      text: "✓"
                      font.pixelSize: 11
                      color: "#34c759"
                      font.weight: Font.Bold
                    }
                  }

                  MouseArea {
                    id: sourceRowM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioService.setDefaultSource(modelData.name)
                  }
                }
              }
            }

            // ==========================================
            // ACTIVE APPLICATION STREAMS (VOLUME MIXER)
            // ==========================================
            Item {
              visible: audioService.streams.length > 0
              Layout.fillWidth: true
              implicitHeight: 1
            }

            Rectangle {
              visible: audioService.streams.length > 0
              Layout.fillWidth: true
              height: 1
              color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
            }

            Text {
              visible: audioService.streams.length > 0
              text: "VOLUME MIXER"
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 10
              font.weight: Font.Bold
              color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
            }

            ColumnLayout {
              visible: audioService.streams.length > 0
              Layout.fillWidth: true
              spacing: 6

              Repeater {
                model: audioService.streams
                delegate: Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 46
                  radius: 8
                  color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 6

                      Text {
                        text: macSoundWindow.getAppIcon(modelData)
                        font.pixelSize: 12
                      }
                      Text {
                        text: modelData.app_name || modelData.name || "App"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: macSoundWindow.isDark ? "#ffffff" : "#1a1a1a"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                      }
                      Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 3
                        color: streamMuteM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                        Text {
                          anchors.centerIn: parent
                          text: modelData.muted ? "🔇" : "🔊"
                          font.pixelSize: 10
                        }
                        MouseArea {
                          id: streamMuteM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: audioService.toggleStreamMute(modelData.id)
                        }
                      }
                      Text {
                        text: modelData.muted ? "Mute" : (modelData.volume + "%")
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 10
                        color: modelData.muted ? "#8e8e93" : (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.6))
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                      }
                    }

                    Slider {
                      id: streamSlider
                      Layout.fillWidth: true
                      Layout.preferredHeight: 14
                      from: 0
                      to: 100
                      stepSize: 1
                      value: modelData.volume
                      onMoved: audioService.setStreamVolume(modelData.id, Math.round(value))

                      background: Rectangle {
                        x: streamSlider.leftPadding
                        y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                        implicitWidth: 160
                        implicitHeight: 4
                        width: streamSlider.availableWidth
                        height: 4
                        radius: 2
                        color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                        Rectangle {
                          width: streamSlider.visualPosition * parent.width
                          height: parent.height
                          color: modelData.muted ? "#8e8e93" : "#007aff"
                          radius: 2
                        }
                      }

                      handle: Rectangle {
                        x: streamSlider.leftPadding + streamSlider.visualPosition * (streamSlider.availableWidth - width)
                        y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: "#ffffff"
                        border.color: Qt.rgba(0, 0, 0, 0.2)
                        border.width: 1
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Footer Divider
        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
        }

        // Footer Link: Sound Settings...
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: 6
          color: soundPrefM.containsMouse ? (macSoundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"

          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text {
              text: "⚙"
              font.pixelSize: 11
              color: "#007aff"
            }
            Text {
              text: "Sound Settings..."
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 12
              font.weight: Font.Medium
              color: "#007aff"
            }
          }

          MouseArea {
            id: soundPrefM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              macSoundWindow.visible = false
              Qt.quit()
              macSoundWindow.runCmd("echo 'sound' > \"${XDG_RUNTIME_DIR:-/tmp}/omarchy-settings-page\" && (omarchy-mac-settings --page sound || omarchy-mac-settings)")
            }
          }
        }
      }
    }
  }
}
