# Dalbit OS
# Fedora Kinoite(KDE Plasma) 기반 Universal Blue 이미지 위에 Dalbit 구성을 얹습니다.

# Fedora 버전 고정. 같은 버전 안의 업데이트는 매일 자동으로 반영되고,
# 다음 Fedora(45 등)로의 업그레이드는 이 숫자를 바꿔서 직접 진행합니다.
ARG FEDORA_VERSION=44

# 빌드 스크립트와 시스템 파일을 담는 임시 단계
FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files
COPY cosign.pub /cosign.pub

# 기반 이미지: Fedora KDE + 코덱/하드웨어 지원이 포함된 Universal Blue 버전
# (Fedora 버전은 파일 맨 위 FEDORA_VERSION에서 고정)
FROM ghcr.io/ublue-os/kinoite-main:${FEDORA_VERSION}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build_files/build.sh && \
    ostree container commit

# bootc 이미지 규칙 검사
RUN bootc container lint
