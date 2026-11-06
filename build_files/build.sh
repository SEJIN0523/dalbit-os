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
chmod +x /usr/bin/dalbit-setup /usr/bin/dalbit-check /usr/bin/dalbit-battery

### 5. 서비스
systemctl enable dalbit-battery-init.service

### 6. 정리
dnf5 clean all
