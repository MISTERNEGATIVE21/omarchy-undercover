import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // Raw state representation read from ~/.config/omarchy-undercover/state
  property string rawState: "win11-dark"

  // Theme detection: true for dark mode (win11-dark, mac-dark, omarchy), false for light mode (win11-light, mac-light)
  readonly property bool isDark: rawState.toLowerCase().indexOf("light") === -1
  readonly property bool isLight: !isDark
  readonly property bool isWindows: rawState.toLowerCase().indexOf("win11") !== -1
  readonly property bool isMac: rawState.toLowerCase().indexOf("mac") !== -1

  // Color tokens
  readonly property color bgColor: isDark ? "#202020" : "#f3f3f3"
  readonly property color surfaceColor: isDark ? Qt.rgba(0.11, 0.12, 0.16, 0.96) : Qt.rgba(1.0, 1.0, 1.0, 0.96)
  readonly property color textColor: isDark ? "#ffffff" : "#1a1a1a"
  readonly property color subTextColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.65) : Qt.rgba(0.0, 0.0, 0.0, 0.60)
  readonly property color accentColor: isDark ? "#60cdff" : "#0067c0"
  readonly property color borderColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.12) : Qt.rgba(0.0, 0.0, 0.0, 0.08)
  readonly property color hoverColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.08) : Qt.rgba(0.0, 0.0, 0.0, 0.06)
  readonly property color activePillColor: isDark ? "#60cdff" : "#0067c0"

  // Extended surface and component tokens for cards, inputs, and frosted glass
  readonly property color cardColor: isDark ? Qt.rgba(0.18, 0.18, 0.22, 0.85) : Qt.rgba(1.0, 1.0, 1.0, 0.85)
  readonly property color cardBorderColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.15) : Qt.rgba(0.0, 0.0, 0.0, 0.10)
  readonly property color inputBgColor: isDark ? Qt.rgba(0.15, 0.15, 0.18, 0.90) : Qt.rgba(0.95, 0.95, 0.95, 0.90)
  readonly property color glassBgColor: isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.85) : Qt.rgba(0.96, 0.96, 0.98, 0.85)
  readonly property color separatorColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.10) : Qt.rgba(0.0, 0.0, 0.0, 0.08)

  // Asynchronous state watcher process
  property Process _stateWatcher: Process {
    command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (s.length > 0) {
          root.rawState = s
        }
      }
    }
  }

  // Periodic polling timer to keep tokens reactive to state changes
  property Timer _poller: Timer {
    interval: 1200
    running: true
    repeat: true
    onTriggered: {
      if (!root._stateWatcher.running) {
        root._stateWatcher.running = true
      }
    }
  }
}
