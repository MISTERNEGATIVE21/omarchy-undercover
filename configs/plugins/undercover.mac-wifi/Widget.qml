import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-wifi"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰤨"
    tooltipText: "Wi-Fi: Connected"
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-mac-wifi")
    }
  }
}
