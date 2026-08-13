import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: macWidgetsWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
      bottom: true
    }
    margins {
      top: 36
      right: 12
      bottom: 12
    }

    WlLayer.layer: WlLayer.Overlay
    WlLayer.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 420

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 22
      color: "rgba(22, 22, 30, 0.94)"
      border.color: "rgba(255, 255, 255, 0.18)"
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "Widgets"
            color: "#ffffff"
            font.pixelSize: 22
            font.weight: Font.Bold
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: "rgba(255, 255, 255, 0.12)"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: "#ffffff"
              font.pixelSize: 12
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Weather 2x2 Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 110
          radius: 16
          color: "rgba(255, 255, 255, 0.08)"
          border.color: "rgba(255, 255, 255, 0.12)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "WEATHER • CUPERTINO"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
            RowLayout {
              Text { text: "72°"; color: "#ffffff"; font.pixelSize: 32; font.weight: Font.ExtraBold }
              ColumnLayout {
                Text { text: "Sunny"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold }
                Text { text: "H: 76°  L: 58° • 0% Rain"; color: "rgba(255, 255, 255, 0.65)"; font.pixelSize: 11 }
              }
            }
          }
        }

        // Stocks Watchlist Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 120
          radius: 16
          color: "rgba(255, 255, 255, 0.08)"
          border.color: "rgba(255, 255, 255, 0.12)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "STOCKS • WATCHLIST"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
            RowLayout {
              Text { text: "AAPL (Apple Inc.)"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "$234.15"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold }
              Text { text: "+2.14%"; color: "#30d158"; font.pixelSize: 11.5; font.weight: Font.Bold }
            }
            RowLayout {
              Text { text: "NVDA (NVIDIA)"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "$128.50"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold }
              Text { text: "+3.42%"; color: "#30d158"; font.pixelSize: 11.5; font.weight: Font.Bold }
            }
            RowLayout {
              Text { text: "S&P 500"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold; Layout.fillWidth: true }
              Text { text: "5,620.8"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.Bold }
              Text { text: "+0.85%"; color: "#30d158"; font.pixelSize: 11.5; font.weight: Font.Bold }
            }
          }
        }

        // Multi-Device Batteries
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 110
          radius: 16
          color: "rgba(255, 255, 255, 0.08)"
          border.color: "rgba(255, 255, 255, 0.12)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text { text: "BATTERIES • DEVICES"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
            RowLayout {
              Text { text: "💻 MacBook Pro"; color: "rgba(255,255,255,0.7)"; font.pixelSize: 11; Layout.fillWidth: true }
              Text { text: "94%"; color: "#30d158"; font.pixelSize: 11; font.weight: Font.Bold }
              Text { text: "🎧 AirPods Pro"; color: "rgba(255,255,255,0.7)"; font.pixelSize: 11; Layout.fillWidth: true }
              Text { text: "100%"; color: "#30d158"; font.pixelSize: 11; font.weight: Font.Bold }
            }
            RowLayout {
              Text { text: "🖱️ Magic Mouse"; color: "rgba(255,255,255,0.7)"; font.pixelSize: 11; Layout.fillWidth: true }
              Text { text: "85%"; color: "#30d158"; font.pixelSize: 11; font.weight: Font.Bold }
              Text { text: "📱 iPhone 16"; color: "rgba(255,255,255,0.7)"; font.pixelSize: 11; Layout.fillWidth: true }
              Text { text: "92%"; color: "#30d158"; font.pixelSize: 11; font.weight: Font.Bold }
            }
          }
        }

        // Reminders & Tasks Checklist
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 16
          color: "rgba(255, 255, 255, 0.08)"
          border.color: "rgba(255, 255, 255, 0.12)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text { text: "REMINDERS & CALENDAR"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: "✔ Design review with macOS architecture team"; color: "rgba(255, 255, 255, 0.6)"; font.pixelSize: 11.5 }
            Text { text: "□ Deploy Omarchy Undercover Quickshell update"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
            Text { text: "□ Review pull requests & QML components"; color: "#ffffff"; font.pixelSize: 11.5; font.weight: Font.DemiBold }
          }
        }
      }
    }
  }
}
