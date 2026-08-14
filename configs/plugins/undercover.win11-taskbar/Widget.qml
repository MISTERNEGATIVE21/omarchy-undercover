import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: taskbarRow.implicitWidth + 12
  implicitHeight: root.bar ? root.bar.barSize : 44

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
    id: taskbarRow
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: root.winApps

      Rectangle {
        id: itemBox
        implicitWidth: modelData.isSearch ? 160 : 40
        implicitHeight: root.bar ? root.bar.barSize - 8 : 36
        radius: modelData.isSearch ? 18 : 4
        color: modelData.isSearch
               ? (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
               : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.color: modelData.isSearch ? Qt.rgba(1, 1, 1, 0.10) : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        border.width: 1

        // Normal Icon View
        Item {
          visible: !modelData.isSearch
          anchors.fill: parent

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            font.pixelSize: modelData.isStart ? 18 : 15
            color: modelData.isStart ? "#0078d4" : (root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff")
          }

          // Active Running Indicator Bar
          Rectangle {
            visible: modelData.running
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: 14
            height: 3
            radius: 1.5
            color: "#60cdff"
          }
        }

        // Search Box Pill View
        RowLayout {
          visible: modelData.isSearch
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 8

          Text {
            text: "🔍"
            font.pixelSize: 12
            color: Qt.rgba(1, 1, 1, 0.7)
          }

          Text {
            text: "Search"
            font.family: "Segoe UI"
            font.pixelSize: 11
            color: Qt.rgba(1, 1, 1, 0.6)
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: modelData.isSearch ? Qt.IBeamCursor : Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (modelData.isStart && mouse.button === Qt.RightButton) {
              if (root.bar) {
                root.bar.run("omarchy-undercover-settings --page system")
              } else {
                Quickshell.execDetached("omarchy-undercover-settings --page system")
              }
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
