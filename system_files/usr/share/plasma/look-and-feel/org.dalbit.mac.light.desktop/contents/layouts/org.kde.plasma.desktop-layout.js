// Dalbit OS 맥 스타일 배치
//   위쪽 메뉴 막대: [달 메뉴 · 앱 이름] [앱 메뉴(파일·편집…)] [여백] [시스템 트레이 · Dalbit 컨트롤 센터 · 시계(한 줄)]
//   아래쪽 독(떠 있음, 가운데): 고정 앱 · 실행 중인 앱 | 앱 모음
// 창 버튼(동그라미)의 위치는 dalbit-theme이 kwinrc에 설정 (기본: 오른쪽)

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

// ---------- 위쪽 메뉴 막대 ----------
var panel = new Panel;
panel.location = "top";
panel.height = Math.round(gridUnit * 1.6);
panel.hiding = "none";
panel.floating = false;

panel.addWidget("org.dalbit.moon");

// 지금 쓰는 앱의 메뉴(파일·편집·보기…)를 메뉴 막대로 (KDE 앱 등 지원하는 앱만)
var appmenu = panel.addWidget("org.kde.plasma.appmenu");
appmenu.currentConfigGroup = ["General"];
appmenu.writeConfig("compactView", false);

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

// 시계: Dalbit 시계 (막대가 얇으면 자동으로 한 줄: "11월 8일 (일)  01:52")
panel.addWidget("org.dalbit.clock");

// ---------- 아래쪽 독 ----------
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.hiding = "none";
dock.floating = true;
dock.alignment = "center";
// 내용 길이에 맞춘 독 (Plasma 6의 "내용에 맞춤")
try { dock.lengthMode = "fit"; } catch (e) { print("Dalbit: lengthMode not supported: " + e); }

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:com.google.Chrome.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.videolan.VLC.desktop",
    "applications:systemsettings.desktop"
]);
tasks.writeConfig("iconSpacing", 1);
tasks.writeConfig("maxStripes", 1);

dock.addWidget("org.kde.plasma.marginsseparator");

// 앱 모음(전체 앱 화면). Win 키도 이것을 연다
var grid = dock.addWidget("org.kde.plasma.kickerdash");
grid.currentConfigGroup = ["General"];
grid.writeConfig("icon", "view-app-grid-symbolic");
try { grid.globalShortcut = "Alt+F1"; } catch (e) { print("Dalbit: shortcut failed: " + e); }
