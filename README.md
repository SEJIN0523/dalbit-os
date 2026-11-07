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
  usr/bin/dalbit-theme         # 모양(다크/라이트)과 배치(Windows식/맥식) 전환
  usr/share/aurorae/themes/    # 맥식 배치의 동그란 창 버튼
  usr/share/plasma/            # 전역 테마 · 위젯(시계, 컨트롤 센터, 달 메뉴, 시작하기)
  usr/share/dalbit/flatpaks.list
.github/workflows/build.yml    # GitHub Actions 자동 빌드
docs/                          # 단계별 가이드, 프로젝트 현황(PROJECT_STATUS.md)
```

## 최적화

Zen 4 + Radeon 760M에 맞춘 zram, 메모리 튜닝, 강력 절전 모드, 노트북 배터리 보호가 들어 있습니다.
자세한 내용은 [`docs/02-optimization.md`](docs/02-optimization.md), 설치 후 점검은 `dalbit-check`.

## 모양과 배치

컨트롤 센터(작업표시줄의 Dalbit 마크)의 **모양**에서 바꾸거나, 터미널에서 `dalbit-theme`을 씁니다.

| | Windows식 배치 (기본) | 맥식 배치 |
|---|---|---|
| 작업표시줄 | 아래, 가운데 시작 버튼 + 고정 앱 | 위쪽 메뉴 막대 + 아래 독 |
| 왼쪽 위 | — | 오늘의 달 모양 + 지금 쓰는 앱 이름 (누르면 시스템 메뉴) |
| 창 버튼 | KDE 기본 | 동그란 버튼, 오른쪽 (최소화 · 최대화 · 닫기) |

```bash
dalbit-theme light          # 라이트로 (배치는 그대로)
dalbit-theme --mac          # 맥식 배치로
dalbit-theme --windows      # Windows식 배치로
dalbit-theme --buttons-left # 맥식 배치의 창 버튼을 왼쪽으로 (맥 순서)
```

배치를 바꾸면 작업표시줄 위젯이 새로 만들어집니다. 창 장식 SVG는 `tools/gen-mac-decorations.py`로 만듭니다.

## 로드맵

지금 어디까지 왔는지, 무엇이 확인됐고 무엇이 남았는지는 [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)에 정리합니다.

- [ ] 1. 두 기기 하드웨어 테스트 → `docs/01-hardware-test.md` — 노트북은 실사용 중, 체크리스트 기록과 8600G 확인이 남음
- [x] 2. GitHub 저장소 생성 및 첫 이미지 자동 빌드
- [ ] 3. Fedora Kinoite 설치 후 Dalbit 이미지로 전환 — 노트북 완료, 8600G 확인 필요
- [x] 4. 브랜딩 (이름, 로고, 부팅 화면, 테마, 배경화면)
- [x] 5. Dalbit 전용 설치 ISO 빌드 (Actions에서 수동 실행)
- [ ] 6. 일상 사용하며 개선 / 전용 도구 개발 — 진행 중

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
