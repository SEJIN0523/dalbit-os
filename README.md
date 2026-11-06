# 🌙 Dalbit OS

Windows를 대체하기 위한 개인용 OS입니다. Fedora Kinoite(KDE Plasma) 기반이고, [Universal Blue](https://universal-blue.org/) / bootc 이미지 방식으로 만듭니다.

- **대상 기기**: Ryzen 5 8600G (DeskMini X600), Ryzen 5 8640HS 노트북
- **이미지**: `ghcr.io/sejin0523/dalbit:latest`

## 구조

```
Containerfile                  # OS 이미지 정의
build_files/build.sh           # 패키지 설치 및 설정 스크립트
system_files/                  # 이미지의 / 에 그대로 복사되는 파일
  usr/bin/dalbit-setup         # 초기 앱 설치 도구
  usr/share/dalbit/flatpaks.list
.github/workflows/build.yml    # GitHub Actions 자동 빌드
docs/                          # 단계별 가이드
```

## 로드맵

- [ ] 1. Live USB로 두 기기 하드웨어 테스트 → `docs/01-hardware-test.md`
- [ ] 2. GitHub 저장소 생성 및 첫 이미지 자동 빌드
- [ ] 3. Fedora Kinoite 설치 후 Dalbit 이미지로 전환
- [ ] 4. 브랜딩 (이름, 로고, 부팅 화면, 테마, 배경화면)
- [ ] 5. Dalbit 전용 설치 ISO 빌드
- [ ] 6. 일상 사용하며 개선 / 전용 도구 개발

## 설치 (4단계)

1. Fedora Kinoite 공식 ISO로 설치
2. 터미널에서 Dalbit 이미지로 전환 후 재부팅
   (이 시점의 Fedora에는 아직 Dalbit 공개 키가 없어서 첫 전환만 서명 검사 없이 진행됩니다)
   ```bash
   sudo bootc switch ghcr.io/sejin0523/dalbit:latest
   systemctl reboot
   ```
3. **서명 검사 켜기** — 이제부터는 내 키로 서명된 이미지만 설치됩니다
   ```bash
   sudo bootc switch --enforce-container-sigpolicy ghcr.io/sejin0523/dalbit:latest
   systemctl reboot
   ```
4. 기본 앱 설치
   ```bash
   dalbit-setup
   ```

## 이미지 서명

- 모든 이미지는 GitHub Actions에서 cosign으로 서명됩니다. 공개 키: [`cosign.pub`](cosign.pub)
- 비밀 키는 GitHub Secrets(`SIGNING_SECRET`)와 개인 PC의 저장소 밖 폴더에만 있습니다. **절대 저장소에 넣지 않습니다.**
- 수동 검증: `cosign verify --key cosign.pub ghcr.io/sejin0523/dalbit:latest`

## 이미지 태그

| 태그 | 의미 |
|---|---|
| `latest` | 최신 빌드 |
| `YYYYMMDD` | 날짜별 빌드 (특정 날짜로 되돌릴 때) |
| 커밋 7자리 | 특정 커밋의 빌드 |

## 업데이트와 롤백

- 업데이트는 백그라운드에서 자동으로 받고, 재부팅하면 적용됩니다.
- 문제가 생기면 부팅 메뉴에서 이전 항목을 선택하거나 `sudo bootc rollback`을 실행합니다.
