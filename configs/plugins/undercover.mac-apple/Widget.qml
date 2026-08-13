import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-apple"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰀵"
    tooltipText: "Apple Menu"
    horizontalMargin: 8
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("omarchy-undercover-settings")
      } else {
        root.bar.run("omarchy-mac-applemenu")
      }
    }
  }
}
