pragma Singleton
import QtQuick

QtObject {
  readonly property var menu: QtObject {
    readonly property color background: Qt.rgba(0.12, 0.12, 0.14, 0.85)
    readonly property color text: "#ffffff"
    readonly property color border: Qt.rgba(1, 1, 1, 0.15)
    readonly property color selectedBackground: Qt.rgba(0.0, 0.48, 1.0, 0.85)
    readonly property color selectedText: "#ffffff"
  }
}
