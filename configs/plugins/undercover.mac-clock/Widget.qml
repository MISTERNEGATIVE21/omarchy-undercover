import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-clock"

  property var date: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.date = new Date()
  }

  readonly property string formattedTime: Qt.formatDateTime(root.date, "ddd d MMM  h:mm AP")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    tooltipText: Qt.formatDateTime(root.date, "dddd, MMMM d, yyyy") + "\n• Left-Click: Notification Center & Widgets\n• Right-Click: Toggle Clock Panel"
    horizontalMargin: 8

    Text {
      anchors.centerIn: parent
      text: root.formattedTime
      font.family: "SF Pro Text, -apple-system, sans-serif"
      font.pixelSize: 13
      font.weight: Font.Medium
      color: root.bar ? root.bar.foreground : "#ffffff"
    }

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        if (root.bar) root.bar.run("omarchy-shell shell toggle omarchy.clock")
        else Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "omarchy.clock"])
      } else {
        if (root.bar) root.bar.run("omarchy-mac-widgets")
        else Quickshell.execDetached(["omarchy-mac-widgets"])
      }
    }
  }
}
