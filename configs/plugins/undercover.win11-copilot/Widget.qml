import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-copilot"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩"
    tooltipText: "Copilot (Win + C)"
    horizontalMargin: 8
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("omarchy-undercover-settings")
      } else {
        root.bar.run("xdg-terminal-exec")
      }
    }
  }
}
