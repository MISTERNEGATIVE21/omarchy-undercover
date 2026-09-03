import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-clock"

  property var date: new Date()
  property bool isDark: true

  // Responsive scaling based on DPI and bar size
  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0

  implicitWidth: clockBox.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 48

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.date = new Date()
  }

  // Theme state detection
  FileView {
    id: stateFile
    path: Quickshell.env("HOME") + "/.config/omarchy-undercover/state"
    watchChanges: true
    onLoaded: {
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
  }

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  Rectangle {
    id: clockBox
    anchors.centerIn: parent
    implicitWidth: Math.max(Math.round(76 * root.scaleFactor), clockCol.implicitWidth + Math.round(18 * root.scaleFactor))
    implicitHeight: root.bar ? root.bar.barSize - 8 : 40
    radius: 4
    color: clockMouse.containsMouse
           ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07))
           : "transparent"
    border.color: clockMouse.containsMouse
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                  : "transparent"
    border.width: 1

    ColumnLayout {
      id: clockCol
      anchors.centerIn: parent
      spacing: 1

      Text {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        text: Qt.formatDateTime(root.date, "h:mm A")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: Math.round(12 * Math.min(1.3, root.scaleFactor))
        font.weight: Font.DemiBold
        color: root.isDark ? "#ffffff" : "#1a1a1a"
      }

      Text {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        text: Qt.formatDateTime(root.date, "M/d/yyyy")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: Math.round(11 * Math.min(1.3, root.scaleFactor))
        color: root.isDark ? Qt.rgba(1, 1, 1, 0.78) : Qt.rgba(0, 0, 0, 0.70)
      }
    }

    MouseArea {
      id: clockMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.runCmd("omarchy-win11-settings")
        } else {
          root.runCmd("omarchy-win11-notifications")
        }
      }
    }
  }
}
