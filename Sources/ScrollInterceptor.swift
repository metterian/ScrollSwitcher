import Cocoa
import Foundation

/// 스크롤 이벤트 소스 타입
enum ScrollEventSource {
    case mouse      // 일반 마우스 휠 (discrete scroll)
    case trackpad   // 트랙패드/Magic Mouse (continuous scroll)
}

/// 스크롤 설정 자동 전환기
/// 트랙패드/마우스 감지 시 macOS Natural Scrolling 설정을 자동으로 토글
class ScrollInterceptor {
    static let shared = ScrollInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    // 직렬 큐로 상태 보호
    private let stateQueue = DispatchQueue(label: "com.scrollswitcher.state")
    private var _currentSource: ScrollEventSource?
    private var currentSource: ScrollEventSource? {
        get { stateQueue.sync { _currentSource } }
        set { stateQueue.sync { _currentSource = newValue } }
    }

    // 설정 변경을 위한 백그라운드 큐
    private let settingsQueue = DispatchQueue(label: "com.scrollswitcher.settings")

    // 설정
    var verbose = false

    // 트랙패드일 때 Natural Scrolling 사용 (기본: true)
    var trackpadNatural = true
    // 마우스일 때 Natural Scrolling 사용 (기본: false)
    var mouseNatural = false

    private init() {}

    /// 현재 시스템의 Natural Scrolling 설정 읽기
    private func isSystemNaturalScrollEnabled() -> Bool {
        let result = UserDefaults.standard.bool(forKey: "com.apple.swipescrolldirection")
        return result
    }

    /// Natural Scrolling 설정 변경 (백그라운드에서 실행)
    private func setNaturalScrolling(_ enabled: Bool, for source: ScrollEventSource) {
        settingsQueue.async { [weak self] in
            guard let self = self else { return }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            task.arguments = ["write", "NSGlobalDomain", "com.apple.swipescrolldirection", "-bool", enabled ? "true" : "false"]

            let errorPipe = Pipe()
            task.standardError = errorPipe

            do {
                try task.run()
                task.waitUntilExit()

                // 종료 상태 확인
                guard task.terminationStatus == 0 else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    print("defaults 명령 실패 (exit \(task.terminationStatus)): \(errorMessage)")
                    return
                }

                // 설정 활성화
                let activateTask = Process()
                activateTask.executableURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings")
                activateTask.arguments = ["-u"]

                let activateErrorPipe = Pipe()
                activateTask.standardError = activateErrorPipe

                try activateTask.run()
                activateTask.waitUntilExit()

                guard activateTask.terminationStatus == 0 else {
                    let errorData = activateErrorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    print("activateSettings 실패 (exit \(activateTask.terminationStatus)): \(errorMessage)")
                    return
                }

                // 성공 시에만 currentSource 업데이트
                self.currentSource = source

                if self.verbose {
                    print("  ✓ Switched to \(enabled ? "Natural" : "Traditional") Scrolling")
                }
            } catch {
                print("설정 변경 실패: \(error)")
            }
        }
    }

    /// CGEventTap 콜백 함수
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

        // 입력 소스 감지
        let source = detectSource(event: event)

        // 같은 소스면 스킵 (중복 전환 방지)
        if source == interceptor.currentSource {
            return Unmanaged.passRetained(event)
        }

        // 원하는 설정 결정
        let wantNatural: Bool
        switch source {
        case .trackpad:
            wantNatural = interceptor.trackpadNatural
        case .mouse:
            wantNatural = interceptor.mouseNatural
        }

        // 현재 시스템 설정 확인
        let currentNatural = interceptor.isSystemNaturalScrollEnabled()

        if interceptor.verbose {
            print("[\(source)] detected, system: \(currentNatural ? "Natural" : "Traditional"), want: \(wantNatural ? "Natural" : "Traditional")")
        }

        // 설정이 다르면 비동기로 변경 (콜백 블로킹 방지)
        if currentNatural != wantNatural {
            if interceptor.verbose {
                print("  → Switching to \(wantNatural ? "Natural" : "Traditional") Scrolling...")
            }
            interceptor.setNaturalScrolling(wantNatural, for: source)
        } else {
            // 설정이 이미 맞으면 바로 currentSource 업데이트
            interceptor.currentSource = source
        }

        return Unmanaged.passRetained(event)
    }

    /// 스크롤 이벤트 소스 감지
    private static func detectSource(event: CGEvent) -> ScrollEventSource {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)

        if isContinuous != 0 {
            return .trackpad
        }

        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)

        if momentumPhase != 0 || scrollPhase != 0 {
            return .trackpad
        }

        return .mouse
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

    /// 인터셉터 시작
    func start() -> Bool {
        guard !isRunning else {
            print("ScrollInterceptor is already running")
            return true
        }

        guard checkAccessibility() else {
            print("Accessibility permission required")
            requestAccessibility()
            return false
        }

        let eventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,  // 이벤트 수정 없이 감지만
            eventsOfInterest: eventMask,
            callback: ScrollInterceptor.eventCallback,
            userInfo: nil
        )

        guard let tap = eventTap else {
            print("Failed to create event tap. Check accessibility permissions.")
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        print("ScrollInterceptor started")
        print("  - Trackpad → \(trackpadNatural ? "Natural" : "Traditional")")
        print("  - Mouse → \(mouseNatural ? "Natural" : "Traditional")")

        return true
    }

    /// 인터셉터 중지
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
