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
panel.height = Math.round(gridUnit * 2.6);
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

// 시스템 트레이: Wi-Fi · 소리 · 배터리만 항상 표시, 나머지는 ^ 안으로. 아이콘은 작업표시줄 높이에 맞춰 키우지 않음
// 트레이는 자체 컨테이너를 가지며, 그 ID는 위젯 설정의 최상위 그룹(SystrayContainmentId)에 저장됨
var tray = panel.addWidget("org.kde.plasma.systemtray");
try {
    tray.currentConfigGroup = [];
    var trayId = tray.readConfig("SystrayContainmentId");
    if (!trayId) {
        tray.currentConfigGroup = ["General"];
        trayId = tray.readConfig("SystrayContainmentId");
    }
    print("Dalbit: systray containment id = " + trayId);
    var systray = trayId ? desktopById(trayId) : null;
    if (systray) {
        systray.currentConfigGroup = ["General"];
        systray.writeConfig("scaleIconsToFit", false);
        systray.writeConfig("iconSpacing", 2);
        systray.writeConfig("shownItems", [
            "org.kde.plasma.networkmanagement",
            "org.kde.plasma.volume",
            "org.kde.plasma.battery"
        ]);
        systray.writeConfig("hiddenItems", [
            "org.kde.plasma.clipboard",
            "org.kde.plasma.brightness",
            "org.kde.plasma.bluetooth",
            "org.kde.plasma.keyboardlayout",
            "org.kde.plasma.manage-inputmethod",
            "Fcitx",
            "org.kde.kdeconnect",
            "org.kde.kscreen",
            "org.kde.plasma.devicenotifier",
            "org.kde.plasma.mediacontroller",
            "org.kde.plasma.vault",
            "org.kde.plasma.weather",
            "xwaylandvideobridge"
        ]);
        try { systray.reloadConfig(); } catch (e) {}
    }
} catch (e) {
    print("Dalbit: systray config failed: " + e);
}

panel.addWidget("org.dalbit.controlcenter");

// 시계: Dalbit 시계 (위 시간 굵게, 아래 날짜 작고 흐리게, 누르면 달력)
panel.addWidget("org.dalbit.clock");
