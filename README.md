# ScrollSwitcher

macOS에서 트랙패드와 마우스의 스크롤 방향을 개별적으로 설정하는 유틸리티입니다.

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

ScrollSwitcher는 입력 장치를 실시간 감지하여 각각 다른 스크롤 방식을 적용합니다:
- **트랙패드**: Natural 유지 (터치스크린처럼 자연스럽게)
- **마우스**: Traditional 적용 (휠 아래 = 페이지 다운)

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
| `--trackpad-traditional` | 트랙패드를 Traditional 방식으로 변경 |
| `--mouse-natural` | 마우스를 Natural 방식으로 변경 |
| `--horizontal` | 수평 스크롤에도 동일하게 적용 |

### 기본 동작

| 장치 | 기본 방식 | 옵션으로 변경 |
|------|----------|--------------|
| 트랙패드 | Natural | `--trackpad-traditional` |
| 마우스 | Traditional | `--mouse-natural` |

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
스크롤 이벤트 → isContinuous 필드 확인 → 장치 판별 → 스크롤 방식 적용
```

### 장치 감지

| `isContinuous` | 장치 | 기본 동작 |
|----------------|------|----------|
| 0 | 마우스 | Traditional (Natural → Traditional 변환) |
| ≠0 | 트랙패드 | Natural (변환 없음) |

### 리소스 사용

- **CPU**: 이벤트 기반, 스크롤 시에만 동작 (~0%)
- **메모리**: ~2MB
- **배터리**: 영향 없음

## 참고 프로젝트

- [Scroll-Reverser](https://github.com/pilotmoon/Scroll-Reverser)
- [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels)

## 라이선스

MIT License
