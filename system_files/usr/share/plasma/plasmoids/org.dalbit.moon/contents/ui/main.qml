/*
 * Dalbit 달 메뉴 (맥 스타일 배치의 왼쪽 위)
 * - 작업표시줄: 오늘의 달 모양 + 지금 쓰는 앱 이름
 * - 누르면: 오늘의 달 정보와 시스템 메뉴 (이 컴퓨터에 관하여 · 설정 · 잠자기 · 다시 시작 · 종료 …)
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property real synodic: 29.530588853
    property date now: new Date()
    // 기준 삭: 2000-01-06 18:14 UTC
    readonly property real age: (((now.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000) % synodic + synodic) % synodic
    readonly property real phase: age / synodic
    property int nonce: 0

    function phaseName(a) {
        if (a < 1.5 || a >= 28.0) return "삭 · 달이 거의 보이지 않아요"
        if (a < 6.4) return "초승달"
        if (a < 8.9) return "상현달"
        if (a < 13.8) return "차오르는 달"
        if (a < 15.8) return "보름달"
        if (a < 20.8) return "기우는 달"
        if (a < 23.6) return "하현달"
        return "그믐달"
    }
    function nextFullMoon() {
        let days = (14.77 - age + synodic) % synodic
        if (days < 0.6) return "오늘"
        const d = new Date(now.getTime() + days * 86400000)
        return d.toLocaleDateString(Qt.locale("ko_KR"), "M월 d일 (ddd)")
    }

    Plasmoid.icon: "dalbit"
    toolTipMainText: "오늘의 달 · " + phaseName(age)
    toolTipSubText: "다음 보름달: " + nextFullMoon()

    // 달 모양은 천천히 바뀌므로 10분마다 갱신
    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    onExpandedChanged: if (expanded) now = new Date()

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }
    function run(cmd) {
        nonce += 1
        root.expanded = false
        exec.connectSource(cmd + " #" + nonce)
    }
    function prompt(kind) {
        run("dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt." + kind)
    }

    // ---------- 메뉴 막대 ----------
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Kirigami.Theme.textColor
            opacity: root.expanded ? 0.14 : compact.containsMouse ? 0.08 : 0
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 2

            MoonCanvas {
                Layout.preferredWidth: Math.round(Math.min(compact.height * 0.72, Kirigami.Units.iconSizes.smallMedium))
                Layout.preferredHeight: Layout.preferredWidth
                phase: root.phase
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                text: appName.item ? appName.item.text : "Dalbit"
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            }
        }

        Loader {
            id: appName
            source: "AppName.qml"
        }
    }

    // ---------- 달 메뉴 ----------
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing * 2
            spacing: Kirigami.Units.largeSpacing

            MoonCanvas {
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Layout.preferredWidth
                phase: root.phase
                color: Kirigami.Theme.textColor
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: root.phaseName(root.age)
                    font.weight: Font.DemiBold
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    wrapMode: Text.Wrap
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: "음력 " + Math.max(1, Math.round(root.age)) + "일 무렵 · 다음 보름달 " + root.nextFullMoon()
                    font: Kirigami.Theme.smallFont
                    opacity: 0.65
                    wrapMode: Text.Wrap
                }
            }
        }

        Separator {}
        MenuRow { text: "이 컴퓨터에 관하여"; command: "systemsettings kcm_about-distro" }
        MenuRow { text: "시스템 설정…"; command: "systemsettings" }
        MenuRow { text: "앱 스토어…"; command: "plasma-discover" }
        Separator {}
        MenuRow { text: "잠자기"; command: "systemctl suspend" }
        MenuRow { text: "다시 시작…"; onActivated: root.prompt("promptReboot") }
        MenuRow { text: "시스템 종료…"; onActivated: root.prompt("promptShutDown") }
        Separator {}
        MenuRow { text: "화면 잠금"; command: "loginctl lock-session" }
        MenuRow { text: "로그아웃…"; onActivated: root.prompt("promptLogout") }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        implicitHeight: 1
        color: Kirigami.Theme.textColor
        opacity: 0.12
    }

    component MenuRow: Rectangle {
        id: menuRow
        property string text
        property string command: ""
        signal activated()

        Layout.fillWidth: true
        implicitHeight: label.implicitHeight + Kirigami.Units.smallSpacing * 3
        radius: Kirigami.Units.smallSpacing * 1.5
        color: mouse.containsMouse ? Kirigami.Theme.highlightColor : "transparent"

        PlasmaComponents3.Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.smallSpacing * 3
            text: menuRow.text
            color: mouse.containsMouse ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (menuRow.command !== "") root.run(menuRow.command)
                else menuRow.activated()
            }
        }
    }
}
