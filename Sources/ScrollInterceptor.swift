import Cocoa
import Foundation

/// 스크롤 이벤트 소스 타입
enum ScrollEventSource {
    case mouse      // 일반 마우스 휠 (이산 스크롤)
    case trackpad   // 트랙패드/Magic Mouse (연속 스크롤)
}

/// 스크롤 이벤트 인터셉터
/// CGEventTap을 사용하여 시스템 레벨에서 스크롤 이벤트를 가로채고 수정
class ScrollInterceptor {
    static let shared = ScrollInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    // 설정 옵션
    var invertMouseScroll = true       // 마우스 스크롤 반전
    var invertTrackpadScroll = false   // 트랙패드 스크롤 반전 (기본: Natural 유지)
    var invertVertical = true          // 수직 스크롤 반전
    var invertHorizontal = false       // 수평 스크롤 반전
    var verbose = false                // 디버그 출력

    private init() {}

    /// CGEventTap 콜백 함수
    /// C 함수 포인터로 전달되므로 static/global 형태로 정의
    private static let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
        let interceptor = ScrollInterceptor.shared

        // 이벤트 탭이 비활성화된 경우 재활성화
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = interceptor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // 스크롤 이벤트가 아니면 통과
        guard type == .scrollWheel else {
            return Unmanaged.passRetained(event)
        }

        // 입력 소스 감지 (핵심 로직)
        let source = detectSource(event: event)

        // 반전 여부 결정
        let shouldInvert: Bool
        switch source {
        case .mouse:
            shouldInvert = interceptor.invertMouseScroll
        case .trackpad:
            shouldInvert = interceptor.invertTrackpadScroll
        }

        if interceptor.verbose {
            let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
            let deltaX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
            print("[\(source)] deltaY: \(deltaY), deltaX: \(deltaX), invert: \(shouldInvert)")
        }

        // 스크롤 반전 적용
        if shouldInvert {
            // 수직 스크롤 반전
            if interceptor.invertVertical {
                let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
                event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -deltaY)

                // FixedPt와 PointDelta도 함께 반전 (일관성 유지)
                let fixedY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
                event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedY)

                let pointY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
                event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointY)
            }

            // 수평 스크롤 반전
            if interceptor.invertHorizontal {
                let deltaX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
                event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -deltaX)

                let fixedX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
                event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fixedX)

                let pointX = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
                event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -pointX)
            }
        }

        return Unmanaged.passRetained(event)
    }

    /// 스크롤 이벤트 소스 감지
    /// kCGScrollWheelEventIsContinuous 필드를 사용하여 트랙패드와 마우스 구분
    private static func detectSource(event: CGEvent) -> ScrollEventSource {
        // 핵심: isContinuous 필드로 구분
        // - 0: 트랙패드 (픽셀 단위 연속 스크롤)
        // - 1: 마우스 휠 (라인 단위 이산 스크롤)
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)

        if isContinuous != 0 {
            return .mouse
        }

        // isContinuous == 0: 추가 검증
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)

        // 모멘텀이나 스크롤 페이즈가 있으면 트랙패드
        if momentumPhase != 0 || scrollPhase != 0 {
            return .trackpad
        }

        // 기본적으로 트랙패드
        return .trackpad
    }

    /// 접근성 권한 확인
    func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 접근성 권한 요청
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// 스크롤 인터셉터 시작
    func start() -> Bool {
        guard !isRunning else {
            print("ScrollInterceptor is already running")
            return true
        }

        // 접근성 권한 확인
        guard checkAccessibility() else {
            print("Accessibility permission required")
            requestAccessibility()
            return false
        }

        // CGEventTap 생성
        let eventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,            // HID 레벨에서 캡처
            place: .tailAppendEventTap,      // 이벤트 체인 끝에 추가
            options: .defaultTap,            // 이벤트 수정 가능
            eventsOfInterest: eventMask,
            callback: ScrollInterceptor.eventCallback,
            userInfo: nil
        )

        guard let tap = eventTap else {
            print("Failed to create event tap. Check accessibility permissions.")
            return false
        }

        // RunLoop에 등록
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        print("ScrollInterceptor started")
        print("  - Mouse scroll invert: \(invertMouseScroll)")
        print("  - Trackpad scroll invert: \(invertTrackpadScroll)")

        return true
    }

    /// 스크롤 인터셉터 중지
    func stop() {
        guard isRunning, let tap = eventTap else { return }

        CGEvent.tapEnable(tap: tap, enable: false)

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false

        print("ScrollInterceptor stopped")
    }
}
