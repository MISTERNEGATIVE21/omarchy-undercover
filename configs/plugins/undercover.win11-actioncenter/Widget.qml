import QtQuick
import QtQuick.Layouts
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-actioncenter"

  implicitWidth: pill.implicitWidth
  implicitHeight: pill.implicitHeight

  WidgetButton {
    id: pill
    anchors.fill: parent
    bar: root.bar
    text: "󰤨  󰕾  󰁹"
    tooltipText: "Quick Settings & Action Center (Win + A)"
    horizontalMargin: 8
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-win11-actioncenter")
      } else {
        Quickshell.execDetached("omarchy-win11-actioncenter")
      }
    }
  }
}
