pragma Singleton
import QtQuick

QtObject {
  function space(x) { return x }
  readonly property int gapsOut: 8
  readonly property int cornerRadius: 10
  readonly property var font: QtObject {
    readonly property string menuFamily: "SF Pro Text, -apple-system, sans-serif"
    readonly property string family: "SF Pro Text, -apple-system, sans-serif"
    readonly property int caption: 11
    readonly property int display: 16
  }
  readonly property var spacing: QtObject {
    readonly property int sm: 6
  }
}
