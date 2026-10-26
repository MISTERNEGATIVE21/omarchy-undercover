import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "win11-weather"

  // Responsive scaling based on DPI and screen resolution
  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0

  implicitWidth: weatherContainer.implicitWidth + Math.round(10 * root.scaleFactor)
  implicitHeight: root.bar ? root.bar.barSize : 48

  readonly property bool interactive: true
  readonly property bool pressable: true
  readonly property bool concealed: false

  function triggerPress(button) {
    if (button === Qt.RightButton) {
      root.runCmd("omarchy-weather")
    } else {
      root.runCmd("omarchy-win11-widgets")
    }
  }

  property var registeredBar: null
  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget) registeredBar.registerClickTarget(root)
  }
  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)

  property bool isDark: true
  property bool showWeather: true
  property string tempText: "72°F"
  property string conditionText: "Partly cloudy"
  property string weatherIcon: "🌤️"

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

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function resolveCmd(cmd) {
    if (!cmd) return ""
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    return cmd.replace(/\b(omarchy-[a-zA-Z0-9_-]+)\b/g, function(match) {
      return pluginScripts + "/" + match
    })
  }

  function runCmd(cmd) {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var fullCmd = root.resolveCmd(cmd)
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + fullCmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  // Theme state poller
  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/undercover/state"
    watchChanges: true
    printErrors: false
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

  // Periodic weather updater with bounded payload & sanitized GUI parsing
  Process {
    id: weatherPoller
    command: [
      "bash", "-c",
      "loc=$(grep -h '^WEATHER_LOCATION=' \"$HOME/.config/omarchy-undercover/settings.conf\" \"$HOME/.config/omarchy/plugins/omarchy-undercover/settings.conf\" \"$HOME/omarchy-undercover/settings.conf\" 2>/dev/null | head -n 1 | cut -d= -f2- | tr -d '\\r\\n\"\\\\' | sed 's/^[ \\t]*//;s/[ \\t]*$//'); " +
      "qloc=\"\"; [ -n \"$loc\" ] && qloc=\"$(printf '%s' \"$loc\" | tr -c '[:alnum:]_.,-' '+' | sed 's/++*/+/g; s/^+//; s/+$//')/\"; " +
      "raw=$(curl -s --max-time 2 \"https://wttr.in/${qloc}?format=%t+%C\" 2>/dev/null | head -c 129); " +
      "if [ -n \"$raw\" ] && [ $(printf '%s' \"$raw\" | wc -c) -le 128 ] && " +
      "echo \"$raw\" | grep -qE '^[+-]?[0-9]{1,3}(°?[CF])?[[:space:]]+[[:alnum:][:space:]_.,\\x27/()-]+$' && " +
      "! echo \"$raw\" | grep -qiE '<|html|50[0-9]|error'; then " +
      "echo \"$raw\" | head -n 1; " +
      "else echo '+72°F Partly cloudy'; fi"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line || line.length > 128) return
        var trimmed = line.trim()
        if (!trimmed || trimmed.indexOf("<") !== -1) return
        var parts = trimmed.split(/\s+/)
        if (parts.length >= 2) {
          var rawTemp = parts[0].replace("+", "").trim()
          // Validate temperature format: optional minus, 1-3 digits, optional degree and C/F
          if (!/^-?[0-9]{1,3}(°?[CF])?$/.test(rawTemp)) {
            root.tempText = "72°F"
            root.conditionText = "Partly cloudy"
            root.weatherIcon = "🌤️"
            return
          }
          // Cap condition to at most 5 tokens and 32 characters
          var condTokens = parts.slice(1, 6)
          var condStr = condTokens.join(" ").slice(0, 32).trim()
          if (!condStr) {
            root.tempText = "72°F"
            root.conditionText = "Partly cloudy"
            root.weatherIcon = "🌤️"
            return
          }

          root.tempText = rawTemp.slice(0, 8)
          root.conditionText = condStr
          var cond = condStr.toLowerCase()
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
           ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12))
           : "transparent"
    border.color: weatherMouse.containsMouse
                  ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.14))
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
          textFormat: Text.PlainText
          font.family: "Segoe UI, sans-serif"
          font.pixelSize: Math.round(12 * Math.min(1.3, root.scaleFactor))
          font.weight: Font.DemiBold
          color: root.textColor
        }
        Text {
          text: root.conditionText
          textFormat: Text.PlainText
          font.family: "Segoe UI, sans-serif"
          font.pixelSize: Math.round(10 * Math.min(1.3, root.scaleFactor))
          color: root.textSecondaryColor
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
