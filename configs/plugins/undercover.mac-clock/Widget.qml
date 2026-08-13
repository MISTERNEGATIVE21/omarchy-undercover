import QtQuick
import Quickshell
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
    text: root.formattedTime
    tooltipText: Qt.formatDateTime(root.date, "dddd, MMMM d, yyyy")
    horizontalMargin: 8
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("omarchy-shell shell toggle omarchy.clock")
      } else {
        root.bar.run("omarchy-mac-widgets")
      }
    }
  }
}
