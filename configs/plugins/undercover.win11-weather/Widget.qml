import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-weather"

  // Responsive scaling based on DPI and screen resolution
  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0

  implicitWidth: weatherContainer.implicitWidth + Math.round(10 * root.scaleFactor)
  implicitHeight: root.bar ? root.bar.barSize : 48

  property bool isDark: true
  property bool showWeather: true
  property string tempText: "72°F"
  property string conditionText: "Partly cloudy"
  property string weatherIcon: "🌤️"

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Theme state poller
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

  // Periodic weather updater
  Process {
    id: weatherPoller
    command: [
      "bash", "-c",
      "curl -s --max-time 2 'wttr.in/?format=%t+%C' 2>/dev/null | grep -E '[0-9]' || echo '+72°F Partly cloudy'"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        var trimmed = line.trim()
        var parts = trimmed.split(" ")
        if (parts.length >= 2) {
          root.tempText = parts[0].replace("+", "")
          root.conditionText = parts.slice(1).join(" ")
          var cond = root.conditionText.toLowerCase()
          if (cond.indexOf("rain") !== -1 || cond.indexOf("drizzle") !== -1) root.weatherIcon = "🌧️"
          else if (cond.indexOf("snow") !== -1) root.weatherIcon = "❄️"
          else if (cond.indexOf("thunder") !== -1) root.weatherIcon = "⛈️"
          else if (cond.indexOf("cloud") !== -1 || cond.indexOf("overcast") !== -1) root.weatherIcon = "☁️"
          else if (cond.indexOf("sun") !== -1 || cond.indexOf("clear") !== -1) root.weatherIcon = "☀️"
          else root.weatherIcon = "🌤️"
        }
      }
    }
  }

  Timer {
    interval: 600000 // 10 minutes
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!weatherPoller.running) weatherPoller.running = true
    }
  }

  Rectangle {
    id: weatherContainer
    visible: root.showWeather
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Math.round(6 * root.scaleFactor)
    implicitWidth: Math.max(Math.round(128 * root.scaleFactor), row.implicitWidth + Math.round(20 * root.scaleFactor))
    implicitHeight: root.bar ? root.bar.barSize - 8 : 40
    radius: 4
    color: weatherMouse.containsMouse
           ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07))
           : "transparent"
    border.color: weatherMouse.containsMouse
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                  : "transparent"
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Math.round(8 * root.scaleFactor)

      Text {
        text: root.weatherIcon
        font.pixelSize: Math.round(18 * Math.min(1.3, root.scaleFactor))
      }

      ColumnLayout {
        spacing: 0
        Text {
          text: root.tempText
          font.family: "Segoe UI, sans-serif"
          font.pixelSize: Math.round(12 * Math.min(1.3, root.scaleFactor))
          font.weight: Font.DemiBold
          color: root.isDark ? "#ffffff" : "#1a1a1a"
        }
        Text {
          text: root.conditionText
          font.family: "Segoe UI, sans-serif"
          font.pixelSize: Math.round(10 * Math.min(1.3, root.scaleFactor))
          color: root.isDark ? Qt.rgba(1, 1, 1, 0.78) : Qt.rgba(0, 0, 0, 0.68)
          elide: Text.ElideRight
          Layout.maximumWidth: Math.round(95 * root.scaleFactor)
        }
      }
    }

    MouseArea {
      id: weatherMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.runCmd("omarchy-weather")
        } else {
          root.runCmd("omarchy-win11-widgets")
        }
      }
    }
  }
}
