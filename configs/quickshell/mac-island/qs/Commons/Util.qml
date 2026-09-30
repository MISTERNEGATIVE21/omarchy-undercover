import QtQuick
pragma Singleton

QtObject {
  function alpha(c, a) {
    if (!c) return "transparent"
    return Qt.rgba(c.r, c.g, c.b, a)
  }
}
