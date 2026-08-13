import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-weather"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🌤️ 72°F Partly Sunny"
    tooltipText: "Open Windows 11 Widgets Board (Win + W)"
    horizontalMargin: 10
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) {
        root.bar.run("xdg-open https://www.msn.com/weather")
      } else {
        root.bar.run("omarchy-win11-widgets")
      }
    }
  }
}
