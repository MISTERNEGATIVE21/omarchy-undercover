import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string homeDir: Quickshell.env("HOME")
  property string stateFile: homeDir + "/.config/omarchy-undercover/state"
  property string settingsFile: homeDir + "/.config/omarchy-undercover/settings.conf"

  // Raw state representation read from ~/.config/omarchy-undercover/state
  property string rawState: "mac-dark"

  // Theme detection
  readonly property bool isDark: rawState.toLowerCase().indexOf("light") === -1
  readonly property bool isLight: !isDark
  readonly property bool isWindows: rawState.toLowerCase().indexOf("win11") !== -1 || rawState.toLowerCase().indexOf("windows") !== -1
  readonly property bool isMac: rawState.toLowerCase().indexOf("mac") !== -1 || rawState.toLowerCase().indexOf("apple") !== -1

  // Color tokens tailored for macOS Sequoia and Windows 11 Fluent
  readonly property color bgColor: isDark ? (isWindows ? "#202024" : "#1e1e24") : (isWindows ? "#f3f3f3" : "#f5f5f7")
  readonly property color surfaceColor: isDark 
    ? (isWindows ? Qt.rgba(0.12, 0.13, 0.17, 0.88) : Qt.rgba(0.14, 0.14, 0.18, 0.82))
    : (isWindows ? Qt.rgba(0.97, 0.97, 0.98, 0.90) : Qt.rgba(0.98, 0.98, 1.0, 0.82))
  
  readonly property color textColor: isDark ? "#ffffff" : "#1a1a1a"
  readonly property color subTextColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.65) : Qt.rgba(0.0, 0.0, 0.0, 0.60)
  readonly property color accentColor: isWindows ? (isDark ? "#60cdff" : "#0067c0") : "#007aff"
  readonly property color borderColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.14) : Qt.rgba(0.0, 0.0, 0.0, 0.10)
  readonly property color hoverColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.08) : Qt.rgba(0.0, 0.0, 0.0, 0.06)
  readonly property color activePillColor: accentColor

  // Extended surface and component tokens for cards, inputs, and frosted glass
  readonly property color cardColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.08) : Qt.rgba(0.0, 0.0, 0.0, 0.04)
  readonly property color cardBorderColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.12) : Qt.rgba(0.0, 0.0, 0.0, 0.08)
  readonly property color inputBgColor: isDark ? Qt.rgba(0.10, 0.10, 0.14, 0.90) : Qt.rgba(0.95, 0.95, 0.95, 0.90)
  readonly property color glassBgColor: isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.80) : Qt.rgba(0.96, 0.96, 0.98, 0.80)
  readonly property color separatorColor: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.10) : Qt.rgba(0.0, 0.0, 0.0, 0.08)

  // Typography tokens
  readonly property string fontFamily: isMac ? "SF Pro Text, -apple-system, sans-serif" : (isWindows ? "Segoe UI, sans-serif" : "Inter, sans-serif")
  readonly property string displayFontFamily: isMac ? "SF Pro Display, -apple-system, sans-serif" : (isWindows ? "Segoe UI Variable Display, Segoe UI, sans-serif" : "Inter, sans-serif")

  // Reactive FileView for state
  property FileView _stateWatcher: FileView {
    path: root.stateFile
    watchChanges: true
    onLoaded: {
      var s = text().trim()
      if (s) root.rawState = s
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      if (s) root.rawState = s
    }
  }
}
