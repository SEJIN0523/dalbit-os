// Dalbit OS 기본 바탕화면 · 작업표시줄 배치
// 화면 아래 떠 있는 작업표시줄:
//   [여백] 시작 버튼 · 고정 앱(파일, 브라우저, 터미널, 설정) [여백] 시스템 트레이 · Dalbit 컨트롤 센터 · 시계(2줄)
// 바탕화면 보기 버튼은 두지 않음 (화면 오른쪽 아래 모서리 / Win+D)

var DALBIT_WALL = "file:///usr/share/wallpapers/Dalbit/";

// 바탕화면 배경
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    ds[i].wallpaperPlugin = "org.kde.image";
    ds[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    ds[i].writeConfig("Image", DALBIT_WALL);
}

// 기존 패널을 지우고 Dalbit 패널 생성
var ps = panels();
for (var j = 0; j < ps.length; j++) {
    ps[j].remove();
}

var panel = new Panel;
panel.location = "bottom";
panel.height = Math.round(gridUnit * 2.4);
panel.hiding = "none";
panel.floating = true;

panel.addWidget("org.kde.plasma.panelspacer");

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "dalbit");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:com.google.Chrome.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop"
]);

panel.addWidget("org.kde.plasma.panelspacer");

// 시스템 트레이: 아이콘을 작업표시줄 높이에 맞춰 키우지 않고, 자주 안 쓰는 항목은 ^ 안으로
var tray = panel.addWidget("org.kde.plasma.systemtray");
var trayId = tray.readConfig("SystrayContainmentId");
if (trayId) {
    var systray = desktopById(trayId);
    if (systray) {
        systray.currentConfigGroup = ["General"];
        systray.writeConfig("scaleIconsToFit", false);
        systray.writeConfig("iconSpacing", 2);
        // 항상 보이는 항목: Wi-Fi, 소리, 배터리 (+ 한글 입력 상태는 기본으로 표시)
        systray.writeConfig("shownItems", [
            "org.kde.plasma.networkmanagement",
            "org.kde.plasma.volume",
            "org.kde.plasma.battery"
        ]);
        systray.writeConfig("hiddenItems", [
            "org.kde.plasma.clipboard",
            "org.kde.plasma.brightness",
            "org.kde.plasma.bluetooth",
            "org.kde.kdeconnect",
            "org.kde.plasma.devicenotifier",
            "org.kde.plasma.mediacontroller"
        ]);
    }
}

panel.addWidget("org.dalbit.controlcenter");

// 시계: "11월 7일 (토)  15:41" — 날짜와 시간을 같은 크기로 한 줄에 (Pretendard Medium)
// dateDisplayFormat: 0 자동 / 1 시간 옆 / 2 시간 아래 (숫자로 저장해야 함)
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("use24hFormat", 2);
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 1);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "M월 d일 (ddd)");
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "Pretendard");
clock.writeConfig("fontWeight", 57);
clock.writeConfig("fontSize", 10);
