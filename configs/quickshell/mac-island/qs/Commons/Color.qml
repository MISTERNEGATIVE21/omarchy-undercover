import QtQuick
import Quickshell
pragma Singleton

QtObject {
  readonly property color background: "#000000"
  readonly property color foreground: "#f5f5f7"
  readonly property color accent: "#007aff"
  readonly property color urgent: "#ff3b30"
  readonly property color green: "#34c759"
  readonly property color orange: "#ff9500"
  readonly property string currentThemePath: Quickshell.env("HOME") + "/.config/omarchy/current/theme"
}
