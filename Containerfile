# Dalbit OS
# Fedora Kinoite(KDE Plasma) 기반 Universal Blue 이미지 위에 Dalbit 구성을 얹습니다.

# 빌드 스크립트와 시스템 파일을 담는 임시 단계
FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files
COPY cosign.pub /cosign.pub

# 기반 이미지: Fedora KDE + 코덱/하드웨어 지원이 포함된 Universal Blue 버전
# 안정화 후에는 latest 대신 Fedora 버전 번호 태그로 고정하는 것을 권장합니다.
FROM ghcr.io/ublue-os/kinoite-main:latest

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build_files/build.sh && \
    ostree container commit

# bootc 이미지 규칙 검사
RUN bootc container lint
