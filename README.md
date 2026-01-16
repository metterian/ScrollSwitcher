# ScrollSwitcher

macOS에서 트랙패드와 마우스의 스크롤 방향을 개별적으로 설정하는 유틸리티입니다.

## 문제

macOS는 트랙패드와 마우스의 스크롤 방향 설정이 연동되어 있습니다:
- "자연스러운 스크롤"을 켜면 → 트랙패드 ✓, 마우스 ✗
- "자연스러운 스크롤"을 끄면 → 트랙패드 ✗, 마우스 ✓

## 해결

ScrollSwitcher는 입력 장치를 실시간 감지하여 각각 다른 스크롤 방향을 적용합니다:
- **트랙패드**: Natural scrolling 유지 (손가락 방향 = 콘텐츠 방향)
- **마우스**: Traditional scrolling (휠 아래 = 페이지 아래)

## 설치

### 요구사항
- macOS 12.0 이상
- Swift 5.7 이상

### 빠른 설치

```bash
git clone https://github.com/YOUR_USERNAME/ScrollSwitcher.git
cd ScrollSwitcher
./install.sh
```

### 수동 설치

```bash
# 빌드
swift build -c release

# 실행
.build/release/ScrollSwitcher
```

## 접근성 권한

최초 실행 시 접근성 권한이 필요합니다:

1. **시스템 설정** 열기
2. **개인정보 보호 및 보안** > **손쉬운 사용**
3. **ScrollSwitcher** 추가 및 권한 허용

## 사용법

```bash
# 기본 실행 (마우스만 반전)
ScrollSwitcher

# 디버그 모드
ScrollSwitcher --verbose

# 옵션
ScrollSwitcher --help
```

### 옵션

| 옵션 | 설명 |
|------|------|
| `--verbose`, `-v` | 디버그 출력 활성화 |
| `--invert-trackpad` | 트랙패드 스크롤도 반전 |
| `--no-invert-mouse` | 마우스 스크롤 반전 비활성화 |
| `--invert-horizontal` | 수평 스크롤도 반전 |

## 관리

```bash
# 상태 확인
launchctl list | grep scrollswitcher

# 중지
launchctl unload ~/Library/LaunchAgents/com.scrollswitcher.plist

# 시작
launchctl load ~/Library/LaunchAgents/com.scrollswitcher.plist

# 로그 확인
cat /tmp/scrollswitcher.log

# 완전 제거
./uninstall.sh
```

## 작동 원리

CGEventTap을 사용하여 시스템 레벨에서 스크롤 이벤트를 가로챕니다:

```
스크롤 이벤트 → isContinuous 필드 확인 → 장치 판별 → 조건부 반전
```

| `isContinuous` | 장치 | 동작 |
|----------------|------|------|
| 0 | 트랙패드 | 그대로 통과 |
| ≠0 | 마우스 | delta 반전 |

### 리소스 사용

- **CPU**: 이벤트 기반, 스크롤 시에만 동작 (~0%)
- **메모리**: ~2MB
- **배터리**: 영향 없음

## 참고 프로젝트

- [Scroll-Reverser](https://github.com/pilotmoon/Scroll-Reverser)
- [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels)

## 라이선스

MIT License
