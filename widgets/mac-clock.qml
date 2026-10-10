import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-clock"

  property var date: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.date = new Date()
  }

  readonly property string formattedTime: Qt.formatDateTime(root.date, "ddd d MMM  h:mm AP")
  readonly property int contentWidth: Math.max(80, Math.ceil(clockLabel.implicitWidth + 24))

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: root.contentWidth
    tooltipText: Qt.formatDateTime(root.date, "dddd, MMMM d, yyyy") + "\n• Left-Click: Notification Center & Widgets\n• Right-Click: Toggle Clock Panel"

    Text {
      id: clockLabel
      anchors.centerIn: parent
      text: root.formattedTime
      font.family: "SF Pro Text, -apple-system, sans-serif"
      font.pixelSize: 13
      font.weight: Font.Medium
      color: root.bar ? root.bar.foreground : "#ffffff"
    }

    property string homeDir: Quickshell.env("HOME")
    property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "omarchy.clock"])
      } else {
        var pluginScripts = button.configDir + "/scripts"
        var devScripts = button.homeDir + "/omarchy-undercover/scripts"
        var cmd = pluginScripts + "/omarchy-mac-widgets"
        var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
        Quickshell.execDetached(["bash", "-c", wrapped])
      }
    }
  }
}
