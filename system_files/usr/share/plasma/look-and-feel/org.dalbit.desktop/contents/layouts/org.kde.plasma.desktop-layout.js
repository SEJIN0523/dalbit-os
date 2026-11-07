// Dalbit OS 기본 바탕화면 · 작업표시줄 배치
// 화면 아래 떠 있는 작업표시줄:
//   [여백] 시작 버튼 · 고정 앱(파일, 브라우저, 터미널, 설정) [여백] 시스템 트레이 · Dalbit 컨트롤 센터 · 시계(2줄)
// (가운데 정렬은 양쪽 확장 여백으로 구현 — Plasma 버전에 상관없이 동작)

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
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.dalbit.controlcenter");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BelowTime");
clock.writeConfig("dateFormat", "shortDate");
