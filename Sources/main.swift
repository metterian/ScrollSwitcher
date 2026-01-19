import Cocoa
import Foundation

/// 사용법 출력
func printUsage() {
    print("""
    ScrollSwitcher - 트랙패드/마우스 감지 시 스크롤 방향 자동 전환

    사용법:
        ScrollSwitcher [옵션]

    옵션:
        --help, -h              이 도움말 출력
        --verbose, -v           디버그 출력 활성화
        --trackpad-traditional  트랙패드 감지 시 Traditional 스크롤
        --mouse-natural         마우스 감지 시 Natural 스크롤

    기본 동작:
        - 트랙패드 감지 → Natural Scrolling ON
        - 마우스 감지 → Natural Scrolling OFF (Traditional)

    필수 권한:
        시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서
        이 앱에 권한을 부여해야 합니다.

    종료: Ctrl+C
    """)
}

/// 시그널 소스 (DispatchSourceSignal 사용)
var sigintSource: DispatchSourceSignal?
var sigtermSource: DispatchSourceSignal?

/// 시그널 핸들러 설정 (DispatchSourceSignal 사용)
func setupSignalHandler() {
    // SIGINT 무시 설정 (DispatchSourceSignal이 처리)
    signal(SIGINT, SIG_IGN)
    signal(SIGTERM, SIG_IGN)

    sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSource?.setEventHandler {
        print("\n종료 중...")
        ScrollInterceptor.shared.stop()
        exit(0)
    }
    sigintSource?.resume()

    sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    sigtermSource?.setEventHandler {
        ScrollInterceptor.shared.stop()
        exit(0)
    }
    sigtermSource?.resume()
}

/// 메인 함수
func main() {
    let args = CommandLine.arguments

    if args.contains("--help") || args.contains("-h") {
        printUsage()
        return
    }

    let interceptor = ScrollInterceptor.shared

    // 옵션 적용
    interceptor.verbose = args.contains("--verbose") || args.contains("-v")
    interceptor.trackpadNatural = !args.contains("--trackpad-traditional")
    interceptor.mouseNatural = args.contains("--mouse-natural")

    print("ScrollSwitcher 시작...")
    print("설정:")
    print("  - 트랙패드 → \(interceptor.trackpadNatural ? "Natural" : "Traditional")")
    print("  - 마우스 → \(interceptor.mouseNatural ? "Natural" : "Traditional")")
    print("")

    // 접근성 권한 확인
    if !interceptor.checkAccessibility() {
        print("⚠️  접근성 권한이 필요합니다.")
        print("   시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서")
        print("   이 앱에 권한을 부여해 주세요.")
        print("")
        interceptor.requestAccessibility()

        print("권한 대기 중... (권한 부여 후 자동으로 시작됩니다)")
        while !interceptor.checkAccessibility() {
            Thread.sleep(forTimeInterval: 1.0)
        }
        print("✓ 접근성 권한 획득!")
    }

    setupSignalHandler()

    guard interceptor.start() else {
        print("❌ ScrollInterceptor 시작 실패")
        exit(1)
    }

    print("")
    print("✓ 입력 장치 감지 활성화됨")
    print("  트랙패드/마우스 전환 시 스크롤 방향이 자동으로 변경됩니다.")
    print("  종료하려면 Ctrl+C를 누르세요")
    print("")

    RunLoop.main.run()
}

main()
