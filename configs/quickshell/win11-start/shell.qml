import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: startWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
    }
    margins {
      bottom: 54
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 700

    property bool showAllApps: false
    property bool showPowerPopup: false

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    property var pinnedApps: [
      { name: "Edge", icon: "🌐", exec: "xdg-open https://microsoft.com || firefox" },
      { name: "Word", icon: "📝", exec: "libreoffice --writer || abiword || xdg-open https://office.com" },
      { name: "Excel", icon: "📊", exec: "libreoffice --calc || gnumeric || xdg-open https://office.com" },
      { name: "PowerPoint", icon: "📽️", exec: "libreoffice --impress || xdg-open https://office.com" },
      { name: "Store", icon: "🛍️", exec: "pamac-manager || gnome-software || discover" },
      { name: "Photos", icon: "🖼️", exec: "eog || gwenview || loupe" },
      { name: "Settings", icon: "⚙️", exec: "omarchy-undercover-settings" },
      { name: "Terminal", icon: "💻", exec: "xdg-terminal-exec" },
      { name: "Explorer", icon: "📁", exec: "nautilus computer:/// || thunar || dolphin" },
      { name: "Calculator", icon: "🔢", exec: "gnome-calculator || kcalc || galculator" },
      { name: "Spotify", icon: "🎵", exec: "spotify || omarchy-win11-widgets" },
      { name: "VS Code", icon: "🧑‍💻", exec: "code || vscodium || cursor" },
      { name: "Chat", icon: "💬", exec: "discord || telegram-desktop || slack" },
      { name: "Notepad", icon: "🗒️", exec: "gedit || kate || mousepad || gnome-text-editor" },
      { name: "Mail", icon: "✉️", exec: "thunderbird || evolution || geary" },
      { name: "Paint", icon: "🎨", exec: "drawing || gimp || inkscape || pinta" },
      { name: "Clock", icon: "⏰", exec: "gnome-clocks || kclock" },
      { name: "Weather", icon: "🌤️", exec: "omarchy-win11-widgets" }
    ]

    property var recommendedItems: [
      { name: "omarchy-undercover.sh", time: "Just now", icon: "📄", exec: "xdg-open ~/.config/omarchy-undercover" },
      { name: "Sequoia-Design-System.pdf", time: "2h ago", icon: "📑", exec: "xdg-open ~/Documents" },
      { name: "Project-Roadmap-2026.docx", time: "Yesterday at 4:15 PM", icon: "📘", exec: "xdg-open ~/Documents" },
      { name: "hyprland-config.lua", time: "Yesterday at 11:30 AM", icon: "⚙️", exec: "xdg-open ~/.config/hypr" },
      { name: "msn-weather-report.json", time: "3 days ago", icon: "📊", exec: "omarchy-win11-widgets" },
      { name: "system-diagnostics.log", time: "5 days ago", icon: "📝", exec: "omarchy-undercover --status" }
    ]

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 16
      color: Qt.rgba(0.11, 0.12, 0.16, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.14)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // 1. Search Box
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: 20
          color: Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.14)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Text { text: "🔍"; font.pixelSize: 13; color: Qt.rgba(1, 1, 1, 0.7) }
            Text {
              text: "Type here to search apps, settings, and files..."
              color: Qt.rgba(1, 1, 1, 0.5)
              font.family: "Segoe UI"
              font.pixelSize: 12
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: {
              Qt.quit()
              startWindow.runCmd("rofi -show drun -theme ~/.config/rofi/windows11.rasi")
            }
          }
        }

        // 2. Pinned Apps Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Pinned"
            color: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 13.5
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }
          Rectangle {
            implicitWidth: 80
            implicitHeight: 26
            radius: 6
            color: allAppsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "All apps >"
              color: "#60cdff"
              font.family: "Segoe UI"
              font.pixelSize: 11.5
              font.weight: Font.DemiBold
            }
            MouseArea {
              id: allAppsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("rofi -show drun -theme ~/.config/rofi/windows11.rasi")
              }
            }
          }
        }

        // 3. Pinned Apps Grid (6 cols x 3 rows)
        GridLayout {
          Layout.fillWidth: true
          columns: 6
          rowSpacing: 10
          columnSpacing: 6

          Repeater {
            model: startWindow.pinnedApps

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 74
              radius: 8
              color: tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
              border.color: tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.icon
                  font.pixelSize: 26
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.name
                  color: "#ffffff"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  startWindow.runCmd(modelData.exec)
                }
              }
            }
          }
        }

        // 4. Recommended Section Header
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 4
          Text {
            text: "Recommended"
            color: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 13.5
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }
          Rectangle {
            implicitWidth: 64
            implicitHeight: 26
            radius: 6
            color: moreMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "More >"
              color: "#60cdff"
              font.family: "Segoe UI"
              font.pixelSize: 11.5
              font.weight: Font.DemiBold
            }
            MouseArea {
              id: moreMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("nautilus recent:/// || thunar")
              }
            }
          }
        }

        // 5. Recommended Files Grid (2 cols x 3 rows)
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 6
          columnSpacing: 10

          Repeater {
            model: startWindow.recommendedItems

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 46
              radius: 8
              color: recMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text { text: modelData.icon; font.pixelSize: 18 }
                ColumnLayout {
                  spacing: 1
                  Layout.fillWidth: true
                  Text {
                    text: modelData.name
                    color: "#ffffff"
                    font.family: "Segoe UI"
                    font.pixelSize: 11.5
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.time
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                  }
                }
              }

              MouseArea {
                id: recMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  startWindow.runCmd(modelData.exec)
                }
              }
            }
          }
        }

        Item { Layout.fillHeight: true }

        // 6. User Profile & Power Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 52
          radius: 10
          color: Qt.rgba(0.08, 0.08, 0.11, 0.85)
          border.color: Qt.rgba(1, 1, 1, 0.08)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            // User Profile
            RowLayout {
              spacing: 10
              Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: "#0078d4"
                Text { anchors.centerIn: parent; text: "👤"; font.pixelSize: 16 }
              }
              Text {
                text: "User"
                color: "#ffffff"
                font.family: "Segoe UI"
                font.pixelSize: 12.5
                font.weight: Font.DemiBold
              }
            }

            Item { Layout.fillWidth: true }

            // Settings Shortcut
            Rectangle {
              implicitWidth: 36
              implicitHeight: 36
              radius: 6
              color: setMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
              Text { anchors.centerIn: parent; text: "⚙️"; font.pixelSize: 14 }
              MouseArea {
                id: setMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  startWindow.runCmd("omarchy-undercover-settings")
                }
              }
            }

            // Power Button
            Rectangle {
              implicitWidth: 36
              implicitHeight: 36
              radius: 6
              color: powerMouse.containsMouse || startWindow.showPowerPopup ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
              Text { anchors.centerIn: parent; text: "⏻"; color: "#ffffff"; font.pixelSize: 15 }
              MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  startWindow.showPowerPopup = !startWindow.showPowerPopup
                }
              }
            }
          }
        }
      }

      // Power Popup Card
      Rectangle {
        visible: startWindow.showPowerPopup
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        anchors.right: parent.right
        anchors.rightMargin: 20
        implicitWidth: 140
        implicitHeight: 130
        radius: 10
        color: Qt.rgba(0.14, 0.15, 0.20, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        z: 200

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 2

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: lockM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              spacing: 8
              Text { text: "🔒"; font.pixelSize: 11 }
              Text { text: "Lock"; color: "#ffffff"; font.pixelSize: 11 }
            }
            MouseArea {
              id: lockM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("hyprlock || swaylock || loginctl lock-session")
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: sleepM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              spacing: 8
              Text { text: "💤"; font.pixelSize: 11 }
              Text { text: "Sleep"; color: "#ffffff"; font.pixelSize: 11 }
            }
            MouseArea {
              id: sleepM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl suspend")
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: restartM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              spacing: 8
              Text { text: "🔄"; font.pixelSize: 11 }
              Text { text: "Restart"; color: "#ffffff"; font.pixelSize: 11 }
            }
            MouseArea {
              id: restartM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl reboot")
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: shutM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              spacing: 8
              Text { text: "⏻"; color: "#ff5f56"; font.pixelSize: 11 }
              Text { text: "Shut down"; color: "#ffffff"; font.pixelSize: 11 }
            }
            MouseArea {
              id: shutM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl poweroff")
              }
            }
          }
        }
      }
    }
  }
}
