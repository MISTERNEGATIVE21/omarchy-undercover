import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-controlcenter"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰕓"
    tooltipText: "Control Center"
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("omarchy-mac-wifi")
      } else {
        root.bar.run("omarchy-mac-widgets")
      }
    }
  }
}
