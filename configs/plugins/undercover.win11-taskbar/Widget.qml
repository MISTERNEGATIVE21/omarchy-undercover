import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: row.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 38

  property var winApps: [
    { name: "Start", icon: "󰍲", exec: "omarchy-win11-start", running: false, isStart: true },
    { name: "Search", icon: "🔍", exec: "omarchy-undercover-launcher", running: false, isSearch: true },
    { name: "Task View", icon: "󰕓", exec: "rofi -show window -theme ~/.config/rofi/windows11.rasi", running: false },
    { name: "Copilot", icon: "󰚩", exec: "xdg-terminal-exec", running: false },
    { name: "File Explorer", icon: "📁", exec: "nautilus computer:/// || thunar || dolphin", running: true },
    { name: "Microsoft Edge", icon: "🌐", exec: "xdg-open https://microsoft.com || firefox || google-chrome-stable", running: true },
    { name: "Terminal", icon: "💻", exec: "xdg-terminal-exec", running: true },
    { name: "Settings", icon: "⚙️", exec: "omarchy-undercover-settings", running: false }
  ]

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 4

    Repeater {
      model: root.winApps

      Rectangle {
        id: appButton
        implicitWidth: 38
        implicitHeight: root.bar ? root.bar.barSize - 6 : 32
        radius: 6
        color: itemMouse.containsMouse ? (root.bar && root.bar.hoverBackground !== undefined ? root.bar.hoverBackground : Qt.rgba(1, 1, 1, 0.12)) : "transparent"
        border.color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: modelData.icon
          font.family: root.bar && root.bar.fontFamily !== undefined ? root.bar.fontFamily : "sans-serif"
          font.pixelSize: modelData.isStart ? 17 : 14
          color: modelData.isStart ? "#0078d4" : (root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff")
        }

        // Active running indicator (blue line at bottom)
        Rectangle {
          visible: modelData.running
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          width: 14
          height: 3
          radius: 1.5
          color: "#0078d4"
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (modelData.isStart && mouse.button === Qt.RightButton) {
              if (root.bar) root.bar.run("omarchy-undercover-settings --page system")
            } else {
              if (root.bar) {
                root.bar.run(modelData.exec)
              } else {
                Quickshell.execDetached(modelData.exec)
              }
            }
          }
        }
      }
    }
  }
}
