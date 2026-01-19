# ScrollSwitcher

macOS에서 트랙패드와 마우스의 스크롤 방향을 자동으로 전환하는 유틸리티입니다.

## 스크롤 방식

| 방식 | 설명 | 동작 |
|------|------|------|
| **Natural** | 콘텐츠가 손가락/휠 방향을 따라감 | 위로 스와이프 → 콘텐츠 위로 |
| **Traditional** | 스크롤바 조작 방식 | 휠 아래 → 페이지 다운 |

## 문제

macOS는 트랙패드와 마우스의 스크롤 방향 설정이 연동되어 있습니다:
- "자연스러운 스크롤" ON → 트랙패드 Natural ✓, 마우스 Natural ✗ (불편)
- "자연스러운 스크롤" OFF → 트랙패드 Traditional ✗ (불편), 마우스 Traditional ✓

## 해결

ScrollSwitcher는 입력 장치를 실시간 감지하여 macOS 시스템 설정을 자동으로 전환합니다:
- **트랙패드 감지** → Natural Scrolling ON
- **마우스 감지** → Natural Scrolling OFF (Traditional)

## 설치

### 요구사항
- macOS 12.0 이상
- Swift 5.7 이상

### 빠른 설치

```bash
git clone https://github.com/metterian/ScrollSwitcher.git
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
# 기본 실행 (트랙패드: Natural, 마우스: Traditional)
ScrollSwitcher

# 디버그 모드
ScrollSwitcher --verbose

# 도움말
ScrollSwitcher --help
```

### 옵션

| 옵션 | 설명 |
|------|------|
| `--help`, `-h` | 도움말 출력 |
| `--verbose`, `-v` | 디버그 출력 활성화 |
| `--trackpad-traditional` | 트랙패드 감지 시 Traditional로 전환 |
| `--mouse-natural` | 마우스 감지 시 Natural로 전환 |

### 기본 동작

| 장치 감지 | 시스템 설정 변경 | 옵션으로 반전 |
|----------|-----------------|--------------|
| 트랙패드 | Natural ON | `--trackpad-traditional` |
| 마우스 | Natural OFF | `--mouse-natural` |

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

CGEventTap으로 스크롤 이벤트를 감지하고, 입력 장치가 변경되면 macOS 시스템 설정을 자동으로 전환합니다:

```
스크롤 이벤트 → isContinuous 필드로 장치 판별 → 장치 변경 시 시스템 설정 전환
```

### 장치 감지

| `isContinuous` | 장치 | 시스템 설정 변경 |
|----------------|------|-----------------|
| 0 | 마우스 | `defaults write ... -bool false` |
| ≠0 | 트랙패드 | `defaults write ... -bool true` |

### 설정 변경 방식

```bash
# Natural Scrolling 토글
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool [true/false]
# 설정 즉시 적용
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
```

### 리소스 사용

- **CPU**: 이벤트 기반, 장치 전환 시에만 설정 변경 (~0%)
- **메모리**: ~2MB
- **배터리**: 영향 없음

## 참고 프로젝트

- [Scroll-Reverser](https://github.com/pilotmoon/Scroll-Reverser)
- [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels)

## 라이선스

MIT License
