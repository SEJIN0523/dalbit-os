# 1단계: Live USB 하드웨어 테스트

설치 전에 두 기기가 Linux에서 문제없이 동작하는지 확인합니다. **디스크는 건드리지 않습니다.**

## 준비
1. 8GB 이상 USB
2. https://fedoraproject.org/kde/ 에서 **Fedora KDE Plasma Desktop** ISO 다운로드
3. Fedora Media Writer 또는 Rufus로 USB에 굽기
4. 부팅 시 F7/F11/F12(제조사별)로 부팅 메뉴 → USB 선택
   - Secure Boot는 켜둔 상태로 진행 가능합니다.

## 체크리스트

| 항목 | 8600G + X600 | 8640HS 노트북 |
|---|---|---|
| 부팅 및 화면 해상도 정상 | ☐ | ☐ |
| Wi-Fi 연결 | ☐ | ☐ |
| 유선 LAN | ☐ | — |
| Bluetooth (이어폰/마우스) | ☐ | ☐ |
| 소리 (스피커 / 이어폰 / HDMI) | ☐ | ☐ |
| USB 장치 인식 | ☐ | ☐ |
| 유튜브 1080p 재생이 부드러운가 | ☐ | ☐ |
| 외부 모니터 연결 | ☐ | ☐ |
| 절전 → 복귀 (뚜껑 닫았다 열기) | — | ☐ |
| 화면 밝기 조절 | — | ☐ |
| 터치패드 (스크롤, 두 손가락 제스처) | — | ☐ |
| Fn 키 (볼륨, 밝기) | — | ☐ |
| 배터리 잔량 표시 | — | ☐ |
| 웹캠 | — | ☐ |

## 하드웨어 정보 수집
문제가 생긴 항목이 있으면 터미널(Konsole)에서 아래 명령을 실행하고 결과를 공유해 주세요.

```bash
lspci -nn | grep -iE 'network|wireless|ethernet|audio'
lsusb
uname -r
```
