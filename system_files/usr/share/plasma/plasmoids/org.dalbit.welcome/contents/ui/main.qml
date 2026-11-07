/*
 * Dalbit 시작하기
 * 첫 로그인 때 창으로 한 번 뜨는 안내: 환영 → 모양 → 배터리 → 휴대폰 → 단축키 → 완료
 * plasmawindowed org.dalbit.welcome 으로 실행. 고른 값은 고르는 즉시 시스템에 적용된다.
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
    readonly property var steps: ["환영합니다", "모양", "배터리", "휴대폰", "단축키", "완료"]
    property int step: 0
    property var st: ({ mode: "dark", power: "balanced", battery: "unsupported", phone: "" })
    property int nonce: 0

    Plasmoid.icon: "dalbit"
    preferredRepresentation: fullRepresentation

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (sourceName.indexOf("cc-status") !== -1) {
                try { root.st = JSON.parse(data["stdout"]) } catch (e) { console.warn("dalbit-welcome:", e) }
            }
        }
    }
    function run(cmd) { nonce += 1; exec.connectSource(cmd + " #" + nonce) }
    function refresh() { run(helpers + "cc-status") }
    function patch(changes) { st = Object.assign({}, st, changes) }
    function setMode(m) { if (st.mode !== m) { patch({ mode: m }); run("dalbit-theme " + m) } }
    function setPower(p) { patch({ power: p }); run(helpers + "cc-power " + p) }
    function setBattery(on) { patch({ battery: on ? "on" : "off" }); run("pkexec " + helpers + "battery-set " + (on ? "on" : "off")) }

    Component.onCompleted: refresh()
    // 휴대폰 단계에서는 연결 상태를 몇 초마다 확인
    Timer { interval: 3000; repeat: true; running: root.step === 3; onTriggered: root.refresh() }

    component Card: Rectangle {
        radius: Kirigami.Units.smallSpacing * 3
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
    }

    component Heading: PlasmaComponents3.Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.6
        font.weight: Font.DemiBold
    }

    component Body: PlasmaComponents3.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        wrapMode: Text.Wrap
        opacity: 0.7
    }

    component ModeCard: Rectangle {
        id: card
        required property string mode
        required property string label
        readonly property bool selected: root.st.mode === mode
        Layout.fillWidth: true
        implicitHeight: thumb.height + cardLabel.implicitHeight + Kirigami.Units.smallSpacing * 5
        radius: Kirigami.Units.smallSpacing * 3
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
        border.width: selected ? 2 : 1
        border.color: selected ? Kirigami.Theme.highlightColor
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
        Rectangle {
            id: thumb
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.smallSpacing * 2 }
            height: width * 9 / 16
            radius: Kirigami.Units.smallSpacing * 2
            clip: true
            gradient: Gradient {
                GradientStop { position: 0; color: card.mode === "dark" ? "#2a2f38" : "#f7f8fa" }
                GradientStop { position: 1; color: card.mode === "dark" ? "#08090b" : "#c9ced6" }
            }
            Rectangle {
                x: parent.width * 0.1; y: parent.height * 0.18
                width: parent.width * 0.52; height: parent.height * 0.56
                radius: 4
                color: card.mode === "dark" ? "#1e2024" : "#ffffff"
                border.width: 1
                border.color: card.mode === "dark" ? "#30343b" : "#d3d7de"
            }
            Image {
                source: Qt.resolvedUrl("../images/mark-" + card.mode + ".svg")
                width: parent.width * 0.24; height: width
                sourceSize.width: width * 2; sourceSize.height: height * 2
                x: parent.width * 0.68; y: parent.height * 0.12
            }
        }
        PlasmaComponents3.Label {
            id: cardLabel
            anchors { top: thumb.bottom; topMargin: Kirigami.Units.smallSpacing * 1.5; horizontalCenter: parent.horizontalCenter }
            text: card.label
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setMode(card.mode) }
    }

    component Keycap: Rectangle {
        property alias text: keyLabel.text
        implicitWidth: keyLabel.implicitWidth + Kirigami.Units.smallSpacing * 3
        implicitHeight: keyLabel.implicitHeight + Kirigami.Units.smallSpacing
        radius: Kirigami.Units.smallSpacing * 1.5
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
        PlasmaComponents3.Label { id: keyLabel; anchors.centerIn: parent; font: Kirigami.Theme.smallFont }
    }

    fullRepresentation: RowLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 40
        Layout.preferredHeight: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 30
        Layout.minimumHeight: Kirigami.Units.gridUnit * 22
        spacing: 0

        // 왼쪽 단계 목록
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)

            ColumnLayout {
                anchors { fill: parent; margins: Kirigami.Units.largeSpacing * 1.5 }
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing * 2
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                    Kirigami.Icon { source: "dalbit"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
                    PlasmaComponents3.Label { text: "Dalbit 시작하기"; font.weight: Font.DemiBold }
                }
                Repeater {
                    model: root.steps
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: stepRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: Kirigami.Units.smallSpacing * 2
                        readonly property color hl: Kirigami.Theme.highlightColor
                        color: index === root.step ? Qt.rgba(hl.r, hl.g, hl.b, 0.18) : "transparent"
                        RowLayout {
                            id: stepRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 2 }
                            spacing: Kirigami.Units.smallSpacing * 2
                            Rectangle {
                                implicitWidth: Kirigami.Units.gridUnit
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: index === root.step ? Kirigami.Theme.highlightColor
                                     : index < root.step ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                     : "transparent"
                                border.width: index > root.step ? 1 : 0
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                                PlasmaComponents3.Label {
                                    anchors.centerIn: parent
                                    text: index < root.step ? "✓" : String(index + 1)
                                    font: Kirigami.Theme.smallFont
                                    color: index === root.step ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: modelData
                                opacity: index === root.step ? 1 : 0.6
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // 오른쪽 내용 + 이동 버튼
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.gridUnit * 1.5
                currentIndex: root.step

                // 1. 환영
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "dalbit"
                        implicitWidth: Kirigami.Units.iconSizes.huge; implicitHeight: implicitWidth
                    }
                    Heading { text: "Dalbit에 오신 것을 환영합니다"; horizontalAlignment: Text.AlignHCenter }
                    Body {
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "몇 가지만 고르면 바로 쓸 수 있어요. 1분이면 끝나고, 나중에 컨트롤 센터에서 언제든 바꿀 수 있습니다."
                    }
                    Item { Layout.fillHeight: true }
                }

                // 2. 모양
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Heading { text: "어떤 모양이 좋으세요?" }
                    Body { text: "창, 바탕화면, 폴더 아이콘, 한글 입력 창이 함께 바뀝니다. 부팅과 잠금 화면은 항상 어둡게 유지됩니다." }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        ModeCard { mode: "dark"; label: "다크 · 밤하늘" }
                        ModeCard { mode: "light"; label: "라이트 · 은빛 흰색" }
                    }
                    Item { Layout.fillHeight: true }
                }

                // 3. 배터리
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Heading { text: "배터리를 오래 쓰도록" }
                    Body { text: "충전기를 자주 꽂아두고 쓰신다면 배터리 보호를 켜두는 걸 추천해요. 외출 전에는 컨트롤 센터에서 잠깐 끄고 100%까지 충전하면 됩니다." }
                    Card {
                        visible: root.st.battery !== "unsupported"
                        Layout.fillWidth: true
                        implicitHeight: battRow.implicitHeight + Kirigami.Units.smallSpacing * 4
                        RowLayout {
                            id: battRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 3 }
                            spacing: Kirigami.Units.smallSpacing * 2
                            Kirigami.Icon { source: "battery-good-symbolic"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                PlasmaComponents3.Label { text: "배터리 보호" }
                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    text: "일정 수준에서 충전을 멈춥니다 (Lenovo 펌웨어 기준)"
                                    font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.Wrap
                                }
                            }
                            PlasmaComponents3.Switch { checked: root.st.battery === "on"; onToggled: root.setBattery(checked) }
                        }
                    }
                    PlasmaComponents3.Label { text: "기본 전원 모드"; font: Kirigami.Theme.smallFont; opacity: 0.65 }
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
                    Item { Layout.fillHeight: true }
                }

                // 4. 휴대폰
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Heading { text: "휴대폰과 연결하기" }
                    Body {
                        textFormat: Text.StyledText
                        text: "1. 휴대폰에 <b>KDE Connect</b> 앱을 설치하세요 (Play 스토어)<br>2. 노트북과 같은 Wi-Fi에 연결하세요<br>3. 아래 버튼을 눌러 휴대폰을 고르세요"
                    }
                    Card {
                        Layout.fillWidth: true
                        implicitHeight: phoneRow.implicitHeight + Kirigami.Units.smallSpacing * 4
                        RowLayout {
                            id: phoneRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.smallSpacing * 3 }
                            spacing: Kirigami.Units.smallSpacing * 2
                            Kirigami.Icon { source: "smartphone-symbolic"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: root.st.phone ? root.st.phone + " · 연결됨" : "아직 연결된 휴대폰이 없어요"
                                elide: Text.ElideRight
                            }
                            PlasmaComponents3.Button {
                                text: root.st.phone ? "열기" : "휴대폰 찾기"
                                onClicked: root.run("kdeconnect-app")
                            }
                        }
                    }
                    Body { text: "파일 보내기, 휴대폰 알림 보기, 복사한 글자 공유를 쓸 수 있어요. 지금 건너뛰어도 됩니다." }
                    Item { Layout.fillHeight: true }
                }

                // 5. 단축키
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Heading { text: "손에 익히면 편한 단축키" }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.gridUnit
                        rowSpacing: Kirigami.Units.smallSpacing * 2
                        Repeater {
                            model: [
                                [["Win"], "시작 메뉴"], [["Win", "E"], "파일"],
                                [["한/영"], "한글 · 영어 전환"], [["오른쪽 Ctrl"], "한자 변환"],
                                [["Win", "V"], "복사 기록"], [["Win", "."], "이모지"],
                                [["Win", "L"], "화면 잠금"], [["Ctrl", "Alt", "Del"], "종료 · 재시작"],
                                [["Print"], "화면 캡처"], [["Alt", "Space"], "무엇이든 검색"]
                            ]
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing
                                Repeater {
                                    model: modelData[0]
                                    delegate: Keycap { required property string modelData; text: modelData }
                                }
                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                    text: modelData[1]
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // 6. 완료
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "dalbit"
                        implicitWidth: Kirigami.Units.iconSizes.huge; implicitHeight: implicitWidth
                    }
                    Heading { text: "준비가 끝났습니다"; horizontalAlignment: Text.AlignHCenter }
                    Body {
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "작업표시줄 오른쪽의 Dalbit 마크를 누르면 모양, 전원, 배터리, 업데이트를 언제든 바꿀 수 있어요."
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // 이동 버튼
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 1.5
                Layout.rightMargin: Kirigami.Units.gridUnit * 1.5
                Layout.bottomMargin: Kirigami.Units.gridUnit
                PlasmaComponents3.Button {
                    text: "뒤로"
                    visible: root.step > 0
                    onClicked: root.step -= 1
                }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.steps.length
                        delegate: Rectangle {
                            required property int index
                            width: index === root.step ? Kirigami.Units.gridUnit : Kirigami.Units.smallSpacing * 1.5
                            height: Kirigami.Units.smallSpacing * 1.5
                            radius: height / 2
                            color: index === root.step ? Kirigami.Theme.highlightColor
                                 : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                            Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents3.Button {
                    highlighted: true
                    text: root.step === 0 ? "시작하기"
                        : root.step === root.steps.length - 1 ? "Dalbit 시작"
                        : (root.step === 3 && !root.st.phone) ? "건너뛰기" : "다음"
                    onClicked: {
                        if (root.step < root.steps.length - 1) {
                            root.step += 1
                        } else {
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
