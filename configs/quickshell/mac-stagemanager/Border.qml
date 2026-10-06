pragma Singleton
import QtQuick

QtObject {
  function hyprlandActiveSpec(fallbackColor, fallbackWidth) {
    return {
      color: fallbackColor,
      widths: { top: fallbackWidth, bottom: fallbackWidth, left: fallbackWidth, right: fallbackWidth },
      gradient: null
    }
  }

  function withWidth(spec, width) {
    return {
      color: spec ? spec.color : Qt.rgba(1, 1, 1, 0.2),
      widths: { top: width, bottom: width, left: width, right: width },
      gradient: spec ? spec.gradient : null
    }
  }
}
