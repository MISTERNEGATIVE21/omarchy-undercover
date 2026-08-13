import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: widgetsWindow
    screen: Quickshell.screens[0]

    anchors {
      left: true
      bottom: true
    }
    margins {
      left: 12
      bottom: 54
    }

    WlLayer.layer: WlLayer.Overlay
    WlLayer.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 500
    implicitHeight: 760

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 16
      color: "rgba(24, 25, 32, 0.94)"
      border.color: "rgba(255, 255, 255, 0.14)"
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
            font.pixelSize: 20
            font.weight: Font.Bold
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 8
            color: "rgba(255, 255, 255, 0.08)"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: "#ffffff"
              font.pixelSize: 13
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Search pill
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 36
          radius: 8
          color: "rgba(255, 255, 255, 0.06)"
          border.color: "rgba(255, 255, 255, 0.10)"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text { text: "🔍"; color: "rgba(255, 255, 255, 0.6)" }
            Text { text: "Search widgets, web, and MSN feed"; color: "rgba(255, 255, 255, 0.5)"; font.pixelSize: 11.5; Layout.fillWidth: true }
          }
        }

        // Weather + Stocks Cards Grid
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          // Weather Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: 12
            color: "rgba(255, 255, 255, 0.05)"
            border.color: "rgba(255, 255, 255, 0.08)"

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 4

              Text { text: "WEATHER • LOCAL"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
              RowLayout {
                Text { text: "72°F"; color: "#ffffff"; font.pixelSize: 26; font.weight: Font.ExtraBold }
                ColumnLayout {
                  Text { text: "Partly Sunny"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold }
                  Text { text: "H: 76° L: 58° • 0% Rain"; color: "rgba(255, 255, 255, 0.6)"; font.pixelSize: 10 }
                }
              }
            }
          }

          // Stocks Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: 12
            color: "rgba(255, 255, 255, 0.05)"
            border.color: "rgba(255, 255, 255, 0.08)"

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 3

              Text { text: "WATCHLIST • MARKETS"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
              RowLayout {
                Text { text: "MSFT $448.20"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "+1.82%"; color: "#27c460"; font.pixelSize: 11; font.weight: Font.Bold }
              }
              RowLayout {
                Text { text: "NVDA $128.40"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "+3.45%"; color: "#27c460"; font.pixelSize: 11; font.weight: Font.Bold }
              }
              RowLayout {
                Text { text: "NASDAQ 18.4K"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "+1.20%"; color: "#27c460"; font.pixelSize: 11; font.weight: Font.Bold }
              }
            }
          }
        }

        // To-Do & Calendar Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 100
          radius: 12
          color: "rgba(255, 255, 255, 0.05)"
          border.color: "rgba(255, 255, 255, 0.08)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "📋 TO-DO & CALENDAR"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold }
            Text { text: "✔ Review Omarchy Undercover v2.5 PR"; color: "rgba(255, 255, 255, 0.7)"; font.pixelSize: 11 }
            Text { text: "□ Architecture Review with Design Team (10:30 AM)"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
          }
        }

        // MSN Curated News Headlines
        Text { text: "TOP STORIES & TRENDING NEWS"; color: "rgba(255, 255, 255, 0.55)"; font.pixelSize: 10; font.weight: Font.Bold; Layout.topMargin: 4 }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 12
          color: "rgba(255, 255, 255, 0.04)"
          border.color: "rgba(255, 255, 255, 0.06)"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            ColumnLayout {
              spacing: 2
              Text { text: "TECHNOLOGY"; color: "#0078d4"; font.pixelSize: 10; font.weight: Font.Bold }
              Text { text: "Next-Gen AI Silicon Achieves 4x Performance Leap in Workstations"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
              Text { text: "MSN Tech • 1h ago"; color: "rgba(255, 255, 255, 0.45)"; font.pixelSize: 10 }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "rgba(255, 255, 255, 0.06)" }

            ColumnLayout {
              spacing: 2
              Text { text: "FINANCE"; color: "#0078d4"; font.pixelSize: 10; font.weight: Font.Bold }
              Text { text: "Global Markets Rally on Strong Cloud Earnings & AI Infrastructure"; color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
              Text { text: "Wall Street Journal • 2h ago"; color: "rgba(255, 255, 255, 0.45)"; font.pixelSize: 10 }
            }
          }
        }
      }
    }
  }
}
