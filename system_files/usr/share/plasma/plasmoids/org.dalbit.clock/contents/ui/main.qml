/*
 * Dalbit 시계: 위에 시간(굵게), 아래 날짜(작고 흐리게), 오른쪽 정렬. 누르면 달력.
 * 달력은 KDE 달력 부품을 별도 파일(Calendar.qml)로 불러와, 혹시 불러오지 못해도 시계는 그대로 동작.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()

    Plasmoid.icon: "preferences-system-time"
    toolTipMainText: now.toLocaleDateString(Qt.locale("ko_KR"), "yyyy년 M월 d일 dddd")
    toolTipSubText: Qt.formatTime(now, "HH:mm")

    Timer {
        // 다음 분이 바뀌는 순간에 맞춰 갱신
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const d = new Date()
            if (d.getMinutes() !== root.now.getMinutes() || d.getDate() !== root.now.getDate()) {
                root.now = d
            }
        }
    }

    compactRepresentation: MouseArea {
        id: compact
        // 얇은 막대(맥 스타일 위쪽 메뉴 막대)에서는 날짜와 시간을 한 줄로
        readonly property bool oneLine: height < Kirigami.Units.gridUnit * 2
        Layout.minimumWidth: (oneLine ? line.implicitWidth : labels.implicitWidth) + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Row {
            id: line
            visible: compact.oneLine
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing * 2

            PlasmaComponents3.Label {
                text: root.now.toLocaleDateString(Qt.locale("ko_KR"), "M월 d일 (ddd)")
                font.family: "Pretendard"
                opacity: compact.containsMouse ? 1 : 0.85
            }
            PlasmaComponents3.Label {
                text: Qt.formatTime(root.now, "HH:mm")
                font.family: "Pretendard"
                font.weight: Font.DemiBold
            }
        }

        Column {
            id: labels
            visible: !compact.oneLine
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: 0

            PlasmaComponents3.Label {
                anchors.right: parent.right
                text: Qt.formatTime(root.now, "HH:mm")
                font.family: "Pretendard"
                font.weight: Font.DemiBold
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.05)
            }
            PlasmaComponents3.Label {
                anchors.right: parent.right
                text: root.now.toLocaleDateString(Qt.locale("ko_KR"), "M월 d일 (ddd)")
                font.family: "Pretendard"
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 0.82)
                opacity: compact.containsMouse ? 0.9 : 0.65
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 21
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 17

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.now.toLocaleDateString(Qt.locale("ko_KR"), "yyyy년 M월 d일 dddd")
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            }
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: "Calendar.qml"
                onLoaded: item.today = Qt.binding(() => root.now)
            }
        }
    }
}
