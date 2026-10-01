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
      bottom: 58
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: Math.min(380, (screen ? screen.width : 1280) - 24)
    implicitHeight: Math.min(460, (screen ? screen.height : 720) - 70)

    property bool isDark: true
    property int currentTab: 0 // 0: Output, 1: Input, 2: Mixer
    property bool hasEntered: false

    AudioService {
      id: audioService
    }

    function closePopup() {
      soundWindow.visible = false
      var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-win11-sound.pid"
      Quickshell.execDetached(["rm", "-f", pidFile])
      Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    Shortcut {
      sequence: "Escape"
      onActivated: soundWindow.closePopup()
    }

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy/plugins/omarchy-undercover/state 2>/dev/null || cat $HOME/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          soundWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 14
      color: soundWindow.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.96) : Qt.rgba(0.96, 0.96, 0.98, 0.96)
      border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1
      opacity: 0
      y: 12

      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Component.onCompleted: {
        opacity = 1.0
        y = 0
      }

      HoverHandler {
        id: cardHover
        onHoveredChanged: {
          if (hovered) {
            soundWindow.hasEntered = true
          }
        }
      }

      Timer {
        id: leaveTimer
        interval: 400
        running: soundWindow.hasEntered && !cardHover.hovered
        onTriggered: {
          soundWindow.closePopup()
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ==========================================
        // 1. HEADER
        // ==========================================
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: audioService.masterMuted ? "󰝟" : (audioService.masterVolume > 50 ? "󰕾" : "󰖀")
            font.pixelSize: 18
            color: soundWindow.isDark ? "#60cdff" : "#0067c0"
          }

          Text {
            text: "Sound & Audio Controls"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 6
            color: closeMouse.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 11
              color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
            }
            MouseArea {
              id: closeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: soundWindow.closePopup()
            }
          }
        }

        // ==========================================
        // 2. SEGMENTED TABS (Output | Input | Mixer)
        // ==========================================
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: soundWindow.isDark ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 2

            // Tab 0: Output
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: 6
              color: soundWindow.currentTab === 0 ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : "#ffffff") : "transparent"
              Text {
                anchors.centerIn: parent
                text: "🔊 Output"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: soundWindow.currentTab === 0 ? Font.DemiBold : Font.Normal
                color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: soundWindow.currentTab = 0
              }
            }

            // Tab 1: Input
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: 6
              color: soundWindow.currentTab === 1 ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : "#ffffff") : "transparent"
              Text {
                anchors.centerIn: parent
                text: "🎙️ Input"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: soundWindow.currentTab === 1 ? Font.DemiBold : Font.Normal
                color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: soundWindow.currentTab = 1
              }
            }

            // Tab 2: Mixer
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: 6
              color: soundWindow.currentTab === 2 ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : "#ffffff") : "transparent"
              Text {
                anchors.centerIn: parent
                text: "🎚️ Mixer (" + audioService.streams.length + ")"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: soundWindow.currentTab === 2 ? Font.DemiBold : Font.Normal
                color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: soundWindow.currentTab = 2
              }
            }
          }
        }

        // ==========================================
        // 3. TAB CONTENT
        // ==========================================

        // --- TAB 0: OUTPUT ---
        ColumnLayout {
          visible: soundWindow.currentTab === 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 8

          // Output Volume Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff"
            border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text {
                  text: "Output Volume"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                  Layout.fillWidth: true
                }
                Text {
                  text: audioService.masterVolume + "%"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                  implicitWidth: 26
                  implicitHeight: 26
                  radius: 4
                  color: muteBtnM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: audioService.masterMuted ? "󰝟" : "󰕾"
                    font.pixelSize: 13
                    color: audioService.masterMuted ? "#ff5f56" : (soundWindow.isDark ? "#ffffff" : "#1a1a1a")
                  }
                  MouseArea {
                    id: muteBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioService.toggleMasterMute()
                  }
                }

                Slider {
                  id: outVolSlider
                  Layout.fillWidth: true
                  from: 0
                  to: 100
                  value: audioService.masterVolume
                  onMoved: audioService.setMasterVolume(value)
                }
              }
            }
          }

          Text {
            text: "Select Output Device"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.75) : "#555555"
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
              id: sinkList
              width: parent.width
              model: audioService.sinks
              spacing: 4

              delegate: Rectangle {
                width: sinkList.width
                implicitHeight: 38
                radius: 6
                color: modelData.isDefault
                       ? (soundWindow.isDark ? Qt.rgba(0, 120, 212, 0.30) : Qt.rgba(0, 120, 212, 0.15))
                       : (sinkM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                border.color: modelData.isDefault ? (soundWindow.isDark ? "#60cdff" : "#0067c0") : "transparent"
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text { text: modelData.type; font.pixelSize: 15 }
                  Text {
                    text: modelData.description || modelData.name
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                    color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    visible: modelData.isDefault
                    text: "✓"
                    font.pixelSize: 11
                    color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                    font.weight: Font.Bold
                  }
                }

                MouseArea {
                  id: sinkM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: audioService.setDefaultSink(modelData.name)
                }
              }
            }
          }
        }

        // --- TAB 1: INPUT ---
        ColumnLayout {
          visible: soundWindow.currentTab === 1
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 8

          // Input Volume Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff"
            border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text {
                  text: "Microphone Input Level"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                  Layout.fillWidth: true
                }
                Text {
                  text: audioService.micVolume + "%"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                  implicitWidth: 26
                  implicitHeight: 26
                  radius: 4
                  color: micMuteM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: audioService.micMuted ? "󰍭" : "󰍬"
                    font.pixelSize: 13
                    color: audioService.micMuted ? "#ff5f56" : (soundWindow.isDark ? "#ffffff" : "#1a1a1a")
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
                  id: inVolSlider
                  Layout.fillWidth: true
                  from: 0
                  to: 100
                  value: audioService.micVolume
                  onMoved: audioService.setMicVolume(value)
                }
              }
            }
          }

          Text {
            text: "Select Input Device (Microphone)"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.75) : "#555555"
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
              id: sourceList
              width: parent.width
              model: audioService.sources
              spacing: 4

              delegate: Rectangle {
                width: sourceList.width
                implicitHeight: 38
                radius: 6
                color: modelData.isDefault
                       ? (soundWindow.isDark ? Qt.rgba(0, 120, 212, 0.30) : Qt.rgba(0, 120, 212, 0.15))
                       : (srcM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                border.color: modelData.isDefault ? (soundWindow.isDark ? "#60cdff" : "#0067c0") : "transparent"
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text { text: modelData.type; font.pixelSize: 14 }
                  Text {
                    text: modelData.description || modelData.name
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                    color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    visible: modelData.isDefault
                    text: "✓"
                    font.pixelSize: 11
                    color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                    font.weight: Font.Bold
                  }
                }

                MouseArea {
                  id: srcM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: audioService.setDefaultSource(modelData.name)
                }
              }
            }
          }
        }

        // --- TAB 2: MIXER ---
        ColumnLayout {
          visible: soundWindow.currentTab === 2
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 8

          Text {
            text: "Application Volume Mixer"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.75) : "#555555"
          }

          // Empty state indicator
          Rectangle {
            visible: audioService.streams.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 6
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: "🔇"
                font.pixelSize: 24
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No applications currently playing sound"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : "#777777"
              }
            }
          }

          ScrollView {
            visible: audioService.streams.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
              id: streamList
              width: parent.width
              model: audioService.streams
              spacing: 6

              delegate: Rectangle {
                width: streamList.width
                implicitHeight: 64
                radius: 8
                color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.07) : "#ffffff"
                border.color: soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 4

                  RowLayout {
                    Layout.fillWidth: true
                    Text {
                      text: "🎵"
                      font.pixelSize: 12
                    }
                    Text {
                      text: modelData.name
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 11
                      font.weight: Font.DemiBold
                      color: soundWindow.isDark ? "#ffffff" : "#1a1a1a"
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      text: modelData.volume + "%"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 11
                      color: soundWindow.isDark ? "#60cdff" : "#0067c0"
                    }
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                      implicitWidth: 22
                      implicitHeight: 22
                      radius: 4
                      color: streamMuteM.containsMouse ? (soundWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                      Text {
                        anchors.centerIn: parent
                        text: modelData.muted ? "󰝟" : "󰕾"
                        font.pixelSize: 11
                        color: modelData.muted ? "#ff5f56" : (soundWindow.isDark ? "#ffffff" : "#1a1a1a")
                      }
                      MouseArea {
                        id: streamMuteM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audioService.toggleStreamMute(modelData.index)
                      }
                    }

                    Slider {
                      Layout.fillWidth: true
                      from: 0
                      to: 100
                      value: modelData.volume
                      onMoved: audioService.setStreamVolume(modelData.index, value)
                    }
                  }
                }
              }
            }
          }
        }

        // ==========================================
        // 4. FOOTER LINK TO SETTINGS
        // ==========================================
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
              font.family: "Segoe UI, sans-serif"
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
              soundWindow.closePopup()
              soundWindow.runCmd("omarchy-win11-settings --page sound 2>/dev/null || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}
