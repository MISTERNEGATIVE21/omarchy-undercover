import QtQuick

Rectangle {
  id: root
  property var borderSpec: null
  color: "transparent"
  border.color: (borderSpec && borderSpec.color) ? borderSpec.color : Qt.rgba(1, 1, 1, 0.2)
  border.width: (borderSpec && borderSpec.widths && borderSpec.widths.top) ? borderSpec.widths.top : 1
}
