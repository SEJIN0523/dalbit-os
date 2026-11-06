#!/usr/bin/env bash
# Dalbit OS 이미지 빌드 스크립트 (Containerfile 안에서 실행됨)
set -euxo pipefail

echo "기반: $(. /etc/os-release && echo "$PRETTY_NAME")"

### 1. 시스템 파일 복사 (/usr, /etc 아래 Dalbit 설정)
cp -a /ctx/system_files/. /

### 2. 패키지 설치 (이미지에 직접 포함되는 시스템 패키지)
# 일반 앱(브라우저 등)은 Flatpak으로 설치합니다. -> /usr/share/dalbit/flatpaks.list
PACKAGES=(
    # 한글
    fcitx5
    fcitx5-hangul
    fcitx5-configtool
    kcm-fcitx5
    google-noto-sans-cjk-fonts
    google-noto-serif-cjk-fonts
    naver-nanum-gothic-fonts
    # 영상 가속 점검 (vainfo)
    libva-utils
    # 도구
    fastfetch
    htop
    jq
)

# 저장소에 없는 패키지가 있으면 어떤 것인지 로그에 남기고 실패
missing=()
for p in "${PACKAGES[@]}"; do
    [[ "$p" == \#* ]] && continue
    dnf5 repoquery --quiet --available "$p" | grep -q . || rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
done
if (( ${#missing[@]} )); then
    echo "❌ 저장소에서 찾을 수 없는 패키지: ${missing[*]}"
    exit 1
fi
dnf5 install -y "${PACKAGES[@]}"

# sched_ext 스케줄러(scx-scheds)는 Fedora 공식 저장소에 들어오면 추가 예정
# (외부 COPR 저장소는 신뢰 범위 문제로 사용하지 않음)

### 2-1. Firefox 제거 → 기본 브라우저를 Chrome(Flatpak)으로
FIREFOX_PKGS=$(rpm -qa 'firefox*' --qf '%{NAME}\n' | sort -u)
if [ -n "$FIREFOX_PKGS" ]; then
    echo "제거: $FIREFOX_PKGS"
    dnf5 remove -y $FIREFOX_PKGS
fi
if rpm -q firefox >/dev/null 2>&1; then echo "❌ firefox 제거 실패"; exit 1; fi

CHROME=com.google.Chrome.desktop
# 기존 기본 앱 설정에서 firefox를 Chrome으로 교체
for f in /etc/xdg/kde-mimeapps.list /etc/xdg/mimeapps.list /usr/share/applications/mimeapps.list /usr/share/applications/kde-mimeapps.list; do
    [ -f "$f" ] || continue
    echo "== $f"; grep -n -i firefox "$f" || true
    # 긴 이름(org.mozilla.firefox)을 먼저 바꿔야 'org.mozilla.' 접두어가 남지 않음
    sed -i -E "s/(org\.mozilla\.)?firefox\.desktop/${CHROME}/g" "$f"
    if grep -q 'org\.mozilla\.' "$f"; then echo "❌ $f 에 firefox 흔적 남음"; grep -n 'org\.mozilla\.' "$f"; exit 1; fi
done
# 웹 관련 기본 앱을 Chrome으로 지정 (Chrome은 dalbit-setup에서 설치)
cat >> /etc/xdg/mimeapps.list <<EOF

[Default Applications]
x-scheme-handler/http=${CHROME}
x-scheme-handler/https=${CHROME}
text/html=${CHROME}
application/xhtml+xml=${CHROME}
EOF

# KDE 작업표시줄 기본 고정 아이콘에서 Firefox를 Chrome으로 교체 (새 사용자 계정에 적용)
grep -rl -i 'firefox' /usr/share/plasma 2>/dev/null | while read -r f; do
    echo "== 작업표시줄 설정: $f"; grep -n -i firefox "$f" || true
    sed -i -E "s/applications:(org\.mozilla\.)?firefox\.desktop/applications:${CHROME}/g" "$f"
done

### 2-1b. 한글 입력 기본 설정 (기존 KDE 설정은 유지하고 필요한 값만 추가)
FCITX_DESKTOP=/usr/share/applications/org.fcitx.Fcitx5.desktop
test -f "$FCITX_DESKTOP"
test -f /etc/xdg/fcitx5/profile
command -v kwriteconfig6
for f in /etc/xdg/kwinrc /etc/xdg/kxkbrc; do echo "== 기존 $f"; cat "$f" 2>/dev/null || echo "(없음)"; done
# 로그인 시 KWin이 fcitx5 실행
kwriteconfig6 --file /etc/xdg/kwinrc --group Wayland --key InputMethod "$FCITX_DESKTOP"
kwriteconfig6 --file /etc/xdg/kwinrc --group Wayland --key VirtualKeyboardEnabled true
# 오른쪽 Alt = 한/영, 오른쪽 Ctrl = 한자 (한/영 키가 Alt로 인식되는 노트북 대응)
kwriteconfig6 --file /etc/xdg/kxkbrc --group Layout --key Options "korean:ralt_hangul,korean:rctrl_hanja"
kwriteconfig6 --file /etc/xdg/kxkbrc --group Layout --key ResetOldOptions true
for f in /etc/xdg/kwinrc /etc/xdg/kxkbrc; do echo "== 변경 후 $f"; cat "$f"; done

### 2-2. 강력 절전 모드 (KDE 전원 프로필 "절전" = dalbit-powersave)
rpm -q tuned tuned-ppd power-profiles-daemon || true
if ! rpm -q tuned-ppd >/dev/null 2>&1; then
    echo "❌ tuned-ppd가 없습니다. 전원 관리 방식이 예상과 다르므로 절전 모드 설정을 확인해야 합니다."
    exit 1
fi
# tuned 버전에 따라 프로필 위치가 다름 (/usr/lib/tuned/profiles 또는 /usr/lib/tuned)
POWERSAVE_CONF=$( (ls -d /usr/lib/tuned/profiles/powersave/tuned.conf /usr/lib/tuned/powersave/tuned.conf 2>/dev/null || true) | head -1 )
TUNED_DIR=$(dirname "$(dirname "${POWERSAVE_CONF:-./x}")")
test -n "$TUNED_DIR" && test "$TUNED_DIR" != "."
echo "tuned 프로필 위치: $TUNED_DIR"
install -Dm644 /ctx/build_files/tuned/dalbit-powersave/tuned.conf "$TUNED_DIR/dalbit-powersave/tuned.conf"
# KDE의 "절전" 프로필이 Dalbit 절전 모드를 쓰도록 연결
PPD_CONF=/etc/tuned/ppd.conf
cat "$PPD_CONF"
grep -q '^power-saver=powersave$' "$PPD_CONF"
sed -i 's/^power-saver=powersave$/power-saver=dalbit-powersave/' "$PPD_CONF"
grep -q '^power-saver=dalbit-powersave$' "$PPD_CONF"

### 2-3. 브랜딩 (시스템 이름, 로고)
# ID=fedora 등 호환성 관련 값은 유지하고 표시 이름만 변경
OSR=/usr/lib/os-release
FEDORA_VER=$(. "$OSR" && echo "$VERSION_ID")
sed -i -E \
    -e 's/^NAME=.*/NAME="Dalbit OS"/' \
    -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Dalbit OS (Fedora ${FEDORA_VER} 기반)\"/" \
    -e '/^(LOGO|HOME_URL|BUG_REPORT_URL)=/d' \
    "$OSR"
cat >> "$OSR" <<'EOF'
LOGO=dalbit
HOME_URL="https://github.com/SEJIN0523/dalbit-os"
BUG_REPORT_URL="https://github.com/SEJIN0523/dalbit-os/issues"
EOF
cat "$OSR"
# 아이콘 테마에서 'dalbit' 이름으로 로고를 찾을 수 있도록
install -Dm644 /usr/share/pixmaps/dalbit-logo.svg /usr/share/icons/hicolor/scalable/apps/dalbit.svg
# KDE '시스템 정보' 화면
kwriteconfig6 --file /etc/xdg/kcm-about-distrorc --group General --key LogoPath /usr/share/pixmaps/dalbit-logo.svg
kwriteconfig6 --file /etc/xdg/kcm-about-distrorc --group General --key Website "https://github.com/SEJIN0523/dalbit-os"
kwriteconfig6 --file /etc/xdg/kcm-about-distrorc --group General --key Variant "Zen 4 Edition"
cat /etc/xdg/kcm-about-distrorc

### 2-4. Dalbit 테마 (다크 + 하늘색 강조) — 새 사용자 기본값
WALL=/usr/share/wallpapers/Dalbit
test -f /usr/share/color-schemes/DalbitDark.colors
test -f /usr/share/plasma/look-and-feel/org.dalbit.desktop/metadata.json
echo "== 기존 /etc/xdg/kdeglobals"; cat /etc/xdg/kdeglobals 2>/dev/null || echo "(없음)"
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.dalbit.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme DalbitDark
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme breeze-dark
# 잠금 화면 배경
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALL/"
# 로그인 화면(SDDM) 배경: 사용 중인 테마 확인 후 설정
grep -rh '^Current=' /etc/sddm.conf /etc/sddm.conf.d/ /usr/lib/sddm/sddm.conf.d/ 2>/dev/null || echo "SDDM Current 설정 없음 (기본 breeze)"
SDDM_THEME=$(grep -rh '^Current=' /etc/sddm.conf /etc/sddm.conf.d/ /usr/lib/sddm/sddm.conf.d/ 2>/dev/null | tail -1 | cut -d= -f2)
SDDM_THEME=${SDDM_THEME:-breeze}
echo "SDDM 테마: $SDDM_THEME"
if [ -d "/usr/share/sddm/themes/$SDDM_THEME" ]; then
    cat > "/usr/share/sddm/themes/$SDDM_THEME/theme.conf.user" <<EOF
[General]
background=$WALL/contents/images/3840x2160.svg
type=image
EOF
else
    echo "⚠️ SDDM 테마 폴더 없음: $SDDM_THEME (로그인 배경은 기본값 유지)"
fi

### 3. 이미지 서명 검사 정책
# Dalbit 이미지는 내 cosign 키로 서명된 것만 받도록 설정 (다른 이미지는 기존 정책 유지)
install -Dm644 /ctx/cosign.pub /etc/pki/containers/dalbit.pub
POLICY=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/sejin0523/dalbit"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/dalbit.pub",
      "signedIdentity": { "type": "matchRepository" }
    }]' "$POLICY" > /tmp/policy.json
install -m644 /tmp/policy.json "$POLICY"
jq . "$POLICY"

### 4. 실행 권한
chmod +x /usr/bin/dalbit-setup /usr/bin/dalbit-check /usr/bin/dalbit-battery /usr/bin/dalbit-theme

### 5. 서비스
systemctl enable dalbit-battery-init.service

### 6. 정리
dnf5 clean all
