import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy-undercover.win11-clock"

  property var date: new Date()
  property bool isDark: true

  // Responsive scaling based on DPI and bar size
  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0

  implicitWidth: clockBox.implicitWidth + Math.round(20 * root.scaleFactor)
  implicitHeight: root.bar ? root.bar.barSize : 24

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
    path: Quickshell.env("HOME") + "/.config/omarchy/plugins/omarchy-undercover/state"
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

  // Dynamic Bar-Aware Contrast Detection
  readonly property bool isBarLight: {
    if (root.bar && root.bar.foreground !== undefined) {
      var f = root.bar.foreground
      var lumF = 0.299 * f.r + 0.587 * f.g + 0.114 * f.b
      return lumF < 0.5
    }
    return !root.isDark
  }
  readonly property color textColor: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : (isBarLight ? "#111111" : "#ffffff")
  readonly property color textSecondaryColor: isBarLight ? "#4f4f4f" : Qt.rgba(1, 1, 1, 0.78)

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
    implicitWidth: Math.max(Math.round(82 * root.scaleFactor), clockCol.implicitWidth + Math.round(22 * root.scaleFactor))
    implicitHeight: Math.max(20, root.bar ? root.bar.barSize - 4 : 20)
    radius: 4
    color: clockMouse.containsMouse
           ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12))
           : "transparent"
    border.color: clockMouse.containsMouse
                  ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.14))
                  : "transparent"
    border.width: 1

    ColumnLayout {
      id: clockCol
      anchors.centerIn: parent
      spacing: (root.bar && root.bar.barSize > 34) ? 2 : -1

      Text {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.date, "h:mm A")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: (root.bar && root.bar.barSize > 34) ? 12 : 9.5
        font.weight: Font.DemiBold
        color: root.textColor
      }

      Text {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.date, "M/d/yyyy")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: (root.bar && root.bar.barSize > 34) ? 10.5 : 8.5
        color: root.textSecondaryColor
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
