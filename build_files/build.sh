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
    # 부팅 화면(Plymouth) script 테마 실행용
    plymouth-plugin-script
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
(grep -rl -i 'firefox' /usr/share/plasma 2>/dev/null || true) | while read -r f; do
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
# 부팅·잠금·로그인은 테마와 상관없이 항상 다크 그림
WALL_DARK_IMG="file://$WALL/contents/images_dark/3840x2160.svg"
test -f /usr/share/color-schemes/DalbitDark.colors
test -f /usr/share/color-schemes/DalbitLight.colors
test -f /usr/share/plasma/look-and-feel/org.dalbit.desktop/metadata.json
test -f /usr/share/plasma/look-and-feel/org.dalbit.light.desktop/metadata.json
test -f /usr/share/icons/dalbit-dark/index.theme
test -f /usr/share/icons/dalbit-light/index.theme
gtk-update-icon-cache -f /usr/share/icons/dalbit-dark 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/dalbit-light 2>/dev/null || true
echo "== 기존 /etc/xdg/kdeglobals"; cat /etc/xdg/kdeglobals 2>/dev/null || echo "(없음)"
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.dalbit.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme DalbitDark
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme dalbit-dark
# Plasma의 낮/밤 자동 전환 기능이 있는 경우 쓸 라이트/다크 테마 짝
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key DefaultLightLookAndFeel org.dalbit.light.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key DefaultDarkLookAndFeel org.dalbit.desktop
# 글꼴 (Qt6 형식: 이름,크기,-1,5,굵기,...)
FONT_UI="Pretendard,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key font "$FONT_UI"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key menuFont "$FONT_UI"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key toolBarFont "$FONT_UI"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key smallestReadableFont "Pretendard,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key fixed "D2Coding,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file /etc/xdg/kdeglobals --group WM --key activeFont "Pretendard,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
# 잠금 화면 배경
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$WALL_DARK_IMG"
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "$WALL_DARK_IMG"
# 로그인 화면 배경 (Fedora 44 = Plasma Login Manager)
# 배포판 기본값 파일: /usr/lib/plasmalogin/defaults.conf (/etc/plasmalogin.conf가 덮어씀)
PLM_DEFAULTS=/usr/lib/plasmalogin/defaults.conf
if rpm -q plasma-login-manager >/dev/null 2>&1 || [ -d /usr/lib/plasmalogin ]; then
    echo "== 기존 $PLM_DEFAULTS"; cat "$PLM_DEFAULTS" 2>/dev/null || echo "(없음)"
    mkdir -p "$(dirname "$PLM_DEFAULTS")"
    kwriteconfig6 --file "$PLM_DEFAULTS" --group Greeter --key WallpaperPlugin org.kde.image
    kwriteconfig6 --file "$PLM_DEFAULTS" --group Greeter --group Wallpaper --group org.kde.image --group General \
        --key Image "$WALL_DARK_IMG"
    kwriteconfig6 --file "$PLM_DEFAULTS" --group Greeter --group Wallpaper --group org.kde.image --group General \
        --key PreviewImage "$WALL_DARK_IMG"
    echo "== 변경 후 $PLM_DEFAULTS"; cat "$PLM_DEFAULTS"
else
    echo "⚠️ Plasma Login Manager 없음 (로그인 배경은 기본값 유지)"
fi

### 2-5. 빌드 중에만 필요한 도구 (기반 이미지에 없던 것만 설치했다가 마지막에 제거)
TEMP_PKGS=()
for p in librsvg2-tools unzip; do
    rpm -q "$p" >/dev/null 2>&1 || TEMP_PKGS+=("$p")
done
if (( ${#TEMP_PKGS[@]} )); then dnf5 install -y "${TEMP_PKGS[@]}"; fi

### 2-6. 글꼴: Pretendard(시스템), D2Coding(터미널) — 공식 GitHub 배포본, 버전·체크섬 고정
FONT_TMP=$(mktemp -d)
curl -fsSL -o "$FONT_TMP/pretendard.zip" \
    https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip
echo "04be351a74d6bf7d60c480a3087e51d185485d35a52023142af1df19eb8c428a  $FONT_TMP/pretendard.zip" | sha256sum -c -
curl -fsSL -o "$FONT_TMP/d2coding.zip" \
    https://github.com/naver/d2codingfont/releases/download/VER1.4.0/D2Coding-Ver1.4.0-20261003.zip
echo "17e2da5e2879006eb725b87943f7988736ef8b6c9f8b84bc8e3bdbcb8dd46744  $FONT_TMP/d2coding.zip" | sha256sum -c -
unzip -q "$FONT_TMP/pretendard.zip" -d "$FONT_TMP/p"
unzip -q "$FONT_TMP/d2coding.zip" -d "$FONT_TMP/d"
install -Dm644 -t /usr/share/fonts/pretendard "$FONT_TMP"/p/public/static/Pretendard-*.otf
install -Dm644 -t /usr/share/fonts/d2coding \
    "$FONT_TMP/d/D2Coding/D2Coding-Ver1.4.0-20261003.ttf" \
    "$FONT_TMP/d/D2Coding/D2CodingBold-Ver1.4.0-20261003.ttf"
# OFL 라이선스 파일 함께 배포
mkdir -p /usr/share/licenses/pretendard /usr/share/licenses/d2coding
find "$FONT_TMP/p" -maxdepth 2 -iname 'LICENSE*' -exec cp {} /usr/share/licenses/pretendard/ \;
find "$FONT_TMP/d" -maxdepth 2 -iname '*LICENSE*' -exec cp {} /usr/share/licenses/d2coding/ \;
rm -rf "$FONT_TMP"
fc-cache -f /usr/share/fonts
fc-list : family > /tmp/fc-families.txt
grep -q 'Pretendard' /tmp/fc-families.txt
grep -q 'D2Coding' /tmp/fc-families.txt
fc-match sans-serif:lang=ko
fc-match monospace

### 2-7. 부팅 화면 (Plymouth) — 초기 부팅 파일(initramfs)도 다시 생성
PLY_SRC=/ctx/build_files/plymouth
PLY_DIR=/usr/share/plymouth/themes/dalbit
mkdir -p "$PLY_DIR"
# 초승달과 별은 같은 캔버스 크기 (겹치면 로고 완성, 별만 따로 반짝임)
rsvg-convert -w 128 -h 128 "$PLY_SRC/crescent.svg" -o "$PLY_DIR/crescent.png"
rsvg-convert -w 128 -h 128 "$PLY_SRC/star.svg"     -o "$PLY_DIR/star.png"
rsvg-convert -w 300 -h 48  "$PLY_SRC/title.svg"    -o "$PLY_DIR/title.png"
rsvg-convert -w 4   -h 4   "$PLY_SRC/bar.svg"      -o "$PLY_DIR/bar.png"
install -m644 "$PLY_SRC/dalbit.plymouth" "$PLY_SRC/dalbit.script" "$PLY_DIR/"
ls -l "$PLY_DIR"
rpm -q plymouth-plugin-script
plymouth-set-default-theme dalbit
plymouth-set-default-theme | grep -qx dalbit

KVER=$(ls /usr/lib/modules)
[ "$(echo "$KVER" | wc -l)" = 1 ] || { echo "❌ 커널이 여러 개: $KVER"; exit 1; }
echo "initramfs 재생성: $KVER"
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "$KVER" --reproducible --zstd --add ostree -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
# 새 initramfs에 Dalbit 부팅 화면이 들어갔는지 확인
lsinitrd "/usr/lib/modules/$KVER/initramfs.img" > /tmp/initrd.txt
grep -q 'usr/share/plymouth/themes/dalbit/dalbit.script' /tmp/initrd.txt
grep -q 'usr/share/plymouth/themes/dalbit/crescent.png' /tmp/initrd.txt
grep -q 'usr/share/plymouth/themes/dalbit/star.png' /tmp/initrd.txt
grep -q 'plymouth/script.so' /tmp/initrd.txt || { echo "❌ initramfs에 plymouth script 플러그인 없음"; exit 1; }
grep -E 'ostree-prepare-root|plymouth/themes/dalbit|plymouth/script.so' /tmp/initrd.txt | head -20

# 빌드용 임시 도구 제거
if (( ${#TEMP_PKGS[@]} )); then dnf5 remove -y "${TEMP_PKGS[@]}"; fi

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
chmod +x /usr/bin/dalbit-setup /usr/bin/dalbit-check /usr/bin/dalbit-battery /usr/bin/dalbit-theme /usr/libexec/dalbit/grub-hide-menu

### 5. 서비스
systemctl enable dalbit-battery-init.service
systemctl enable dalbit-grub-hide-menu.service

### 6. 정리
dnf5 clean all
