# Zen 4 + Radeon 760M 최적화 (1단계)

대상: Ryzen 5 8600G (DeskMini X600), Ryzen 5 8640HS 노트북.
Fedora 기본 커널을 그대로 사용하므로 **Secure Boot를 켠 채로** 쓸 수 있습니다.

| 항목 | 설정 | 파일 |
|---|---|---|
| CPU 스케줄러 | sched_ext `scx_lavd --autopower` (반응성 우선, 전원 프로필 연동) | `usr/lib/systemd/system/dalbit-scx.service` |
| 메모리 압축 | zram = RAM 크기, zstd | `etc/systemd/zram-generator.conf` |
| 스왑 튜닝 | swappiness 180, page-cluster 0 (zram 전용 권장값) | `usr/lib/sysctl.d/99-dalbit.conf` |
| 노트북 화면 절전 | 배터리일 때 ABM 레벨 2, 충전 중에는 0 | `usr/libexec/dalbit/power-tune` + udev 규칙 |
| CPU 전력 | amd-pstate EPP + tuned-ppd (Fedora 기본, 배터리 시 자동 절전) | — |
| 영상 가속 | VA-API (Universal Blue 기본 포함), `vainfo`로 확인 | — |
| NPU | 커널 `amdxdna` 드라이버 (Fedora 기본) | — |

## 점검
설치 후 터미널에서 실행합니다.
```bash
dalbit-check
```

## 되돌리기
- 스케줄러 끄기: `sudo systemctl disable --now dalbit-scx` (기본 스케줄러로 복귀)
- 화면 절전 끄기: `sudo systemctl mask dalbit-power-tune`

## BIOS 권장 설정
- **CPPC**: Enabled (amd-pstate 동작에 필요)
- **UMA Frame Buffer Size**: Auto 또는 512MB~2GB. Linux는 필요하면 공유 메모리(GTT)를 추가로 씁니다.
- **IPU / NPU**: Enabled (메뉴가 있는 경우)

## RAM
| 기기 | 구성 | 비고 |
|---|---|---|
| 8600G | DDR5-4800 12GB × 2 | 듀얼 채널 24GB |
| 노트북 | DDR5-5600 8GB × 2 (예정) | 같은 모듈 2개로 듀얼 채널 필수. 760M 성능에 직결 |
