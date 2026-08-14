import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-start"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍲"
    tooltipText: "Start (Super)"
    horizontalMargin: 8
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("omarchy-undercover-settings --page system")
      } else {
        root.bar.run("omarchy-win11-start")
      }
    }
  }
}
