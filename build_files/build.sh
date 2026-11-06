#!/usr/bin/env bash
# Dalbit OS 이미지 빌드 스크립트 (Containerfile 안에서 실행됨)
set -euxo pipefail

### 1. 시스템 파일 복사 (/usr, /etc 아래 Dalbit 설정)
cp -a /ctx/system_files/. /

### 2. 패키지 설치 (이미지에 직접 포함되는 시스템 패키지)
# 일반 앱(브라우저, Steam 등)은 Flatpak으로 설치합니다. -> /usr/share/dalbit/flatpaks.list
dnf5 install -y \
    fcitx5 \
    fcitx5-hangul \
    fcitx5-configtool \
    kcm-fcitx5 \
    google-noto-sans-cjk-fonts \
    google-noto-serif-cjk-fonts \
    naver-nanum-gothic-fonts \
    fastfetch \
    htop

### 3. 실행 권한
chmod +x /usr/bin/dalbit-setup

### 4. 서비스
# (필요해지면 여기에 systemctl enable 추가)

### 5. 정리
dnf5 clean all
