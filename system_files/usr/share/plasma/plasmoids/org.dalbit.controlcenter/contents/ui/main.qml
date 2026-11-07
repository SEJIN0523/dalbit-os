/*
 * Dalbit 컨트롤 센터
 * 작업표시줄의 Dalbit 마크를 누르면 열리는 패널: 모양 · 전원 · 배터리 보호 · 휴대폰 · 업데이트
 * 시스템 작업은 /usr/libexec/dalbit 의 도우미 스크립트와 dalbit-* 명령을 그대로 부른다.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property string helpers: "/usr/libexec/dalbit/"
    property var st: ({
        mode: "dark", power: "balanced", battery: "unsupported",
        capacity: "", batteryStatus: "", phone: "",
        update: "ok", version: "", stagedVersion: ""
    })
    property int nonce: 0
    // 자원: 최근 30개(약 1분) 기록
    property var stats: ({})
    property var hist: ({ cpu: [], mem: [], gpu: [], temp: [] })

    Plasmoid.icon: "dalbit-control"
    toolTipMainText: "Dalbit"
    toolTipSubText: st.update === "ready"
        ? "업데이트 준비됨 · 다시 시작하면 적용됩니다"
        : "모양 · 전원 · 배터리 · 업데이트"

    // ---------- 명령 실행 ----------
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (sourceName.indexOf("cc-stats") !== -1) {
                try {
                    const x = JSON.parse(data["stdout"])
                    root.stats = x
                    const h = root.hist
                    const push = (k, v) => {
                        const a = h[k].slice()
                        a.push(v === "" || v === undefined ? NaN : Number(v))
                        while (a.length > 30) a.shift()
                        return a
                    }
                    root.hist = {
                        cpu: push("cpu", x.cpu),
                        mem: push("mem", x.memUsed),
                        gpu: push("gpu", x.gpu),
                        temp: push("temp", x.temp)
                    }
                } catch (e) {
                    console.warn("dalbit-controlcenter: stats parse failed:", e)
                }
            } else if (sourceName.indexOf("cc-status") !== -1) {
                try {
                    root.st = JSON.parse(data["stdout"])
                } catch (e) {
                    console.warn("dalbit-controlcenter: status parse failed:", e)
                }
            } else {
                refreshTimer.restart()
            }
        }
    }

    function run(cmd) {
        nonce += 1
        // 같은 명령을 다시 실행할 수 있도록 끝에 셸 주석으로 번호를 붙임
        exec.connectSource(cmd + " #" + nonce)
    }
    function refresh() { run(helpers + "cc-status") }
    function patch(changes) { st = Object.assign({}, st, changes) }

    function setMode(m) {
        if (st.mode === m) return
        patch({ mode: m })
        run("dalbit-theme " + m)
    }
    function setPower(p) {
        patch({ power: p })
        run(helpers + "cc-power " + p)
    }
    function setBattery(on) {
        patch({ battery: on ? "on" : "off" })
        run("pkexec " + helpers + "battery-set " + (on ? "on" : "off"))
    }
    function batteryText() {
        if (!st.capacity) return ""
        const s = st.batteryStatus === "Charging" ? " · 충전 중"
                : st.batteryStatus === "Full" ? " · 충전 완료"
                : st.batteryStatus === "Not charging" ? " · 충전 멈춤" : ""
        return "배터리 " + st.capacity + "%" + s
    }

    // 업데이트 상태가 바뀌었을 수 있으니 가끔 확인 (작업표시줄 점 표시용)
    Timer { interval: 10 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
    // 명령 실행 직후 상태 다시 읽기
    Timer { id: refreshTimer; interval: 1200; onTriggered: root.refresh() }

    onExpandedChanged: if (expanded) refresh()
    Timer {
        interval: 2000
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: root.run(root.helpers + "cc-stats")
    }
    function fmtMinutes(m) {
        if (m === "" || m === undefined) return ""
        const n = Number(m)
        const h = Math.floor(n / 60), mm = n % 60
        return (h > 0 ? h + "시간 " : "") + mm + "분"
    }
    Component.onCompleted: refresh()

    // ---------- 작업표시줄 아이콘 ----------
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: "dalbit-control"
            active: compact.containsMouse
        }
        // 업데이트가 준비되면 작은 점
        Rectangle {
            visible: root.st.update === "ready"
            width: Math.max(6, Math.round(parent.width * 0.26))
            height: width
            radius: width / 2
            anchors.right: parent.right
            anchors.top: parent.top
            color: Kirigami.Theme.highlightColor
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor
        }
    }

    // ---------- 공용 부품 ----------
    component SectionLabel: PlasmaComponents3.Label {
        font: Kirigami.Theme.smallFont
        opacity: 0.65
        Layout.topMargin: Kirigami.Units.smallSpacing
    }

    component Card: Rectangle {
        radius: Kirigami.Units.smallSpacing * 3
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
    }

    component ResItem: ColumnLayout {
        id: ri
        required property string label
        required property string value
        required property var series
        required property real maxValue
        property real minValue: 0
        Layout.fillWidth: true
        spacing: 2
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Label { text: ri.label; font: Kirigami.Theme.smallFont; opacity: 0.65 }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label { text: ri.value; font.weight: Font.Medium }
        }
        Canvas {
            id: spark
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit
            property var pts: ri.series
            onPtsChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const a = pts || []
                if (a.length < 2) return
                ctx.strokeStyle = Kirigami.Theme.highlightColor
                ctx.lineWidth = 1.5
                ctx.lineJoin = "round"
                ctx.beginPath()
                let started = false
                for (let i = 0; i < a.length; i++) {
                    if (isNaN(a[i])) continue
                    const x = width * i / 29
                    const t = Math.max(0, Math.min(1, (a[i] - ri.minValue) / (ri.maxValue - ri.minValue)))
                    const y = height - 1 - t * (height - 2)
                    if (!started) { ctx.moveTo(x, y); started = true } else { ctx.lineTo(x, y) }
                }
                ctx.stroke()
            }
        }
    }

    component ModeTile: Rectangle {
        id: tile
        required property string mode
        required property string label
        readonly property bool selected: root.st.mode === mode
        Layout.fillWidth: true
        implicitHeight: thumb.height + tileLabel.implicitHeight + Kirigami.Units.smallSpacing * 4
        radius: Kirigami.Units.smallSpacing * 3
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
        border.width: selected ? 2 : 1
        border.color: selected ? Kirigami.Theme.highlightColor
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

        Rectangle {
            id: thumb
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.smallSpacing * 1.5 }
            height: width * 9 / 16
            radius: Kirigami.Units.smallSpacing * 1.5
            clip: true
            gradient: Gradient {
                GradientStop { position: 0; color: tile.mode === "dark" ? "#2a2f38" : "#f7f8fa" }
                GradientStop { position: 1; color: tile.mode === "dark" ? "#08090b" : "#c9ced6" }
            }
            Rectangle {
                x: parent.width * 0.1; y: parent.height * 0.18
                width: parent.width * 0.52; height: parent.height * 0.56
                radius: 3
                color: tile.mode === "dark" ? "#1e2024" : "#ffffff"
                border.width: 1
                border.color: tile.mode === "dark" ? "#30343b" : "#d3d7de"
            }
            Image {
                source: Qt.resolvedUrl("../images/mark-" + tile.mode + ".svg")
                width: parent.width * 0.24; height: width
                sourceSize.width: width * 2; sourceSize.height: height * 2
                x: parent.width * 0.68; y: parent.height * 0.12
            }
        }
        PlasmaComponents3.Label {
            id: tileLabel
            anchors { top: thumb.bottom; topMargin: Kirigami.Units.smallSpacing; horizontalCenter: parent.horizontalCenter }
            text: tile.label
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setMode(tile.mode)
        }
    }

    // ---------- 패널 ----------
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 19
        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        spacing: Kirigami.Units.smallSpacing * 2

        // 머리
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing * 2
            Kirigami.Icon {
                source: "dalbit"
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: implicitWidth
            }
            PlasmaComponents3.Label {
                text: "Dalbit"
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label {
                text: root.batteryText()
                font: Kirigami.Theme.smallFont
                opacity: 0.65
            }
        }

        // 모양
        SectionLabel { text: "모양" }
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing * 2
            ModeTile { mode: "dark"; label: "다크" }
            ModeTile { mode: "light"; label: "라이트" }
        }

        // 전원
        SectionLabel { text: "전원" }
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: [["save", "절전"], ["balanced", "균형"], ["perf", "성능"]]
                delegate: PlasmaComponents3.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData[1]
                    checkable: true
                    checked: root.st.power === modelData[0]
                    onClicked: root.setPower(modelData[0])
                }
            }
        }
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.65
            text: root.st.power === "save" ? "CPU 부스트 끔 · 그래픽 저전력 · 배터리 오래"
                : root.st.power === "perf" ? "빠른 반응 우선 · 충전기 연결 권장"
                : "평소 사용에 맞춘 기본값"
        }

        // 자원 (누르면 작업 관리자)
        SectionLabel { text: "자원" }
        Card {
            Layout.fillWidth: true
            implicitHeight: resCol.implicitHeight + Kirigami.Units.smallSpacing * 4

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.expanded = false; root.run("plasma-systemmonitor") }
            }
            ColumnLayout {
                id: resCol
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 3 }
                spacing: Kirigami.Units.smallSpacing * 2

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.largeSpacing * 1.5
                    rowSpacing: Kirigami.Units.smallSpacing * 2
                    ResItem {
                        label: "CPU"; maxValue: 100; series: root.hist.cpu
                        value: root.stats.cpu !== undefined && root.stats.cpu !== "" ? root.stats.cpu + "%" : "—"
                    }
                    ResItem {
                        label: "메모리"; maxValue: Number(root.stats.memTotal || 16); series: root.hist.mem
                        value: root.stats.memUsed ? root.stats.memUsed + " / " + root.stats.memTotal + " GB" : "—"
                    }
                    ResItem {
                        label: "그래픽"; maxValue: 100; series: root.hist.gpu
                        value: root.stats.gpu !== undefined && root.stats.gpu !== "" ? root.stats.gpu + "%" : "—"
                    }
                    ResItem {
                        label: "온도"; minValue: 30; maxValue: 95; series: root.hist.temp
                        value: root.stats.temp !== undefined && root.stats.temp !== "" ? root.stats.temp + "°C" : "—"
                    }
                }
                Rectangle {
                    visible: !!root.stats.power
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
                }
                RowLayout {
                    visible: !!root.stats.power
                    Layout.fillWidth: true
                    PlasmaComponents3.Label {
                        text: (root.stats.batteryStatus === "Charging" ? "충전 " : "배터리 소모 ") + root.stats.power + " W"
                        font: Kirigami.Theme.smallFont; opacity: 0.8
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents3.Label {
                        visible: !!root.stats.minutes
                        text: root.stats.batteryStatus === "Charging"
                            ? "다 차기까지 " + root.fmtMinutes(root.stats.minutes)
                            : "약 " + root.fmtMinutes(root.stats.minutes) + " 남음"
                        font: Kirigami.Theme.smallFont; opacity: 0.65
                    }
                }
            }
        }

        // 배터리 보호 · 휴대폰
        Card {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            implicitHeight: rows.implicitHeight + Kirigami.Units.smallSpacing * 2

            ColumnLayout {
                id: rows
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 2 }
                spacing: Kirigami.Units.smallSpacing * 2

                RowLayout {
                    visible: root.st.battery !== "unsupported"
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 2
                    Kirigami.Icon { source: "battery-good-symbolic"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents3.Label { text: "배터리 보호" }
                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: "충전을 일정 수준에서 멈춰 수명을 늘립니다"
                            font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.Wrap
                        }
                    }
                    PlasmaComponents3.Switch {
                        checked: root.st.battery === "on"
                        onToggled: root.setBattery(checked)
                    }
                }

                Rectangle {
                    visible: root.st.battery !== "unsupported"
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
                }

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: phoneRow.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run("kdeconnect-app")
                    RowLayout {
                        id: phoneRow
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing * 2
                        Kirigami.Icon { source: "smartphone-symbolic"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents3.Label { text: "휴대폰" }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: root.st.phone
                                    ? root.st.phone + " · 연결됨" + (root.st.phoneBattery ? " · 배터리 " + root.st.phoneBattery + "%" : "")
                                    : "연결된 휴대폰 없음 · 눌러서 연결"
                                font: Kirigami.Theme.smallFont; opacity: 0.65; elide: Text.ElideRight
                            }
                        }
                        PlasmaComponents3.Label { text: "›"; opacity: 0.5 }
                    }
                }

                RowLayout {
                    visible: !!root.st.phoneId
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 2
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "document-send"
                        text: "파일 보내기"
                        onClicked: { root.expanded = false; root.run(root.helpers + "cc-phone send " + root.st.phoneId) }
                    }
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "notification-active"
                        text: "휴대폰 찾기"
                        onClicked: root.run(root.helpers + "cc-phone ring " + root.st.phoneId)
                    }
                }
            }
        }

        // 업데이트
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: upd.implicitHeight + Kirigami.Units.smallSpacing * 4
            radius: Kirigami.Units.smallSpacing * 3
            readonly property color hl: Kirigami.Theme.highlightColor
            readonly property color tx: Kirigami.Theme.textColor
            color: root.st.update === "ready" ? Qt.rgba(hl.r, hl.g, hl.b, 0.16) : Qt.rgba(tx.r, tx.g, tx.b, 0.04)
            border.width: 1
            border.color: root.st.update === "ready" ? Qt.rgba(hl.r, hl.g, hl.b, 0.45) : Qt.rgba(tx.r, tx.g, tx.b, 0.10)

            RowLayout {
                id: upd
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 2 }
                spacing: Kirigami.Units.smallSpacing * 2
                Kirigami.Icon {
                    source: root.st.update === "ready" ? "update-none-symbolic" : "checkmark-symbolic"
                    implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents3.Label {
                        text: root.st.update === "ready" ? "업데이트 준비됨" : "최신 상태"
                        font.weight: Font.Medium
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.st.update === "ready"
                            ? "Dalbit " + root.st.stagedVersion + " · 다시 시작하면 적용"
                            : (root.st.version ? "Dalbit " + root.st.version : "")
                        font: Kirigami.Theme.smallFont; opacity: 0.65; elide: Text.ElideRight
                    }
                }
                PlasmaComponents3.Button {
                    visible: root.st.update === "ready"
                    text: "다시 시작"
                    // KDE 기본 "다시 시작할까요?" 확인 창
                    onClicked: root.run("dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot")
                }
            }
        }

        // 아래 메뉴
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents3.ToolButton { text: "시스템 점검"; onClicked: root.run("konsole --hold -e dalbit-check") }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.ToolButton { text: "시작하기"; onClicked: { root.expanded = false; root.run("plasmawindowed org.dalbit.welcome") } }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.ToolButton { text: "설정"; onClicked: { root.expanded = false; root.run("systemsettings") } }
        }
    }
}
