import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: taskbarRow.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 44

  property bool showSearch: true
  property string searchMode: "box" // "box", "icon", "hidden"
  property bool showTaskView: true
  property bool showCopilot: true

  property var winApps: [
    { id: "start", name: "Start", icon: "󰍲", exec: "omarchy-win11-start", running: false, isStart: true, visible: true },
    { id: "search", name: "Search", icon: "🔍", exec: "omarchy-undercover-launcher", running: false, isSearch: true, visible: root.showSearch && root.searchMode !== "hidden" },
    { id: "taskview", name: "Task View", icon: "󰕓", exec: "rofi -show window -theme ~/.config/rofi/windows11.rasi", running: false, visible: root.showTaskView },
    { id: "copilot", name: "Copilot", icon: "󰚩", exec: "xdg-terminal-exec", running: false, visible: root.showCopilot },
    { id: "explorer", name: "File Explorer", icon: "📁", exec: "nautilus computer:/// || thunar || dolphin", running: true, visible: true },
    { id: "browser", name: "Microsoft Edge", icon: "🌐", exec: "xdg-open https://microsoft.com || firefox || google-chrome-stable", running: true, visible: true },
    { id: "terminal", name: "Terminal", icon: "💻", exec: "xdg-terminal-exec", running: true, visible: true },
    { id: "settings", name: "Settings", icon: "⚙️", exec: "omarchy-undercover-settings", running: false, visible: true }
  ]

  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: root.winApps

      Rectangle {
        id: itemBox
        visible: modelData.visible
        implicitWidth: modelData.isSearch && root.searchMode === "box" ? 150 : 38
        implicitHeight: root.bar ? root.bar.barSize - 8 : 36
        radius: modelData.isSearch && root.searchMode === "box" ? 18 : 4
        color: modelData.isSearch && root.searchMode === "box"
               ? (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
               : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.color: modelData.isSearch && root.searchMode === "box"
                      ? Qt.rgba(1, 1, 1, 0.10)
                      : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        border.width: 1

        // Standard Icon (Icon-only mode, without inline title clutter)
        Item {
          visible: !(modelData.isSearch && root.searchMode === "box")
          anchors.fill: parent

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            font.pixelSize: modelData.isStart ? 17 : 14
            color: modelData.isStart ? "#0078d4" : (root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff")
          }

          // Active Running Indicator Bar (Windows 11 blue indicator pill)
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

        // Expanded Search Pill View
        RowLayout {
          visible: modelData.isSearch && root.searchMode === "box"
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

        // Tooltip showing clean app name on hover
        Rectangle {
          id: tooltip
          visible: itemMouse.containsMouse && !modelData.isSearch
          anchors.bottom: parent.top
          anchors.bottomMargin: 6
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: tooltipText.implicitWidth + 12
          implicitHeight: 24
          radius: 5
          color: Qt.rgba(0.15, 0.16, 0.20, 0.96)
          border.color: Qt.rgba(1, 1, 1, 0.15)
          border.width: 1
          z: 100

          Text {
            id: tooltipText
            anchors.centerIn: parent
            text: modelData.name
            font.family: "Segoe UI"
            font.pixelSize: 10.5
            color: "#ffffff"
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: modelData.isSearch && root.searchMode === "box" ? Qt.IBeamCursor : Qt.PointingHandCursor
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
