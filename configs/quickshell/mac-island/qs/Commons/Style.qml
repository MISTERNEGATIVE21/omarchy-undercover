import QtQuick
pragma Singleton

QtObject {
  readonly property real fontScale: 1.0
  readonly property var font: ({ family: "SF Pro Text, -apple-system, sans-serif" })
  readonly property var spacing: ({ scale: 1.0 })
  function space(px) { return px }
}
