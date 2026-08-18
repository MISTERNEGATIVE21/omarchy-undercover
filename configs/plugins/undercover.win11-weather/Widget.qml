import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-weather"

  implicitWidth: weatherContainer.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 40

  property bool isDark: true
  property bool showWeather: true
  property string tempText: "72°F"
  property string conditionText: "Partly sunny"
  property string weatherIcon: "🌤️"

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Theme state poller
  Process {
    id: statePoller
    running: true
    command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        root.isDark = (s.indexOf("light") === -1)
      }
    }
  }

  // Periodic weather updater
  Process {
    id: weatherPoller
    command: [
      "bash", "-c",
      "curl -s --max-time 2 'wttr.in/?format=%t+%C' 2>/dev/null | grep -E '[0-9]' || echo '+72°F Partly sunny'"
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
          else if (cond.indexOf("cloud") !== -1 || cond.indexOf("overcast") !== -1) root.weatherIcon = "☁️"
          else if (cond.indexOf("sun") !== -1 || cond.indexOf("clear") !== -1) root.weatherIcon = "🌤️"
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
      if (!statePoller.running) statePoller.running = true
    }
  }

  Rectangle {
    id: weatherContainer
    visible: root.showWeather
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: 4
    implicitWidth: Math.max(104, row.implicitWidth + 16)
    implicitHeight: root.bar ? root.bar.barSize - 8 : 34
    radius: 4
    color: weatherMouse.containsMouse
           ? (root.isDark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06))
           : "transparent"
    border.color: weatherMouse.containsMouse
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                  : "transparent"
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.weatherIcon
        font.pixelSize: 16
      }

      ColumnLayout {
        spacing: -1
        Text {
          text: root.tempText
          font.family: "Segoe UI"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: root.isDark ? "#ffffff" : "#1a1a1a"
        }
        Text {
          text: root.conditionText
          font.family: "Segoe UI"
          font.pixelSize: 9
          color: root.isDark ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(0, 0, 0, 0.60)
          elide: Text.ElideRight
          Layout.maximumWidth: 68
        }
      }
    }

    // Hover tooltip
    Rectangle {
      id: tooltip
      visible: weatherMouse.containsMouse
      anchors.bottom: parent.top
      anchors.bottomMargin: 6
      anchors.left: parent.left
      implicitWidth: tooltipText.implicitWidth + 14
      implicitHeight: 24
      radius: 5
      color: root.isDark ? Qt.rgba(0.13, 0.14, 0.18, 0.96) : Qt.rgba(0.98, 0.98, 0.99, 0.98)
      border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1
      z: 100

      Text {
        id: tooltipText
        anchors.centerIn: parent
        text: "Widgets • " + root.tempText + " " + root.conditionText + " • MSN Weather"
        font.family: "Segoe UI"
        font.pixelSize: 10
        color: root.isDark ? "#ffffff" : "#1a1a1a"
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
          root.runCmd("xdg-open https://www.msn.com/weather")
        } else {
          root.runCmd("omarchy-win11-widgets")
        }
      }
    }
  }
}
