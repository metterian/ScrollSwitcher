import Cocoa
import Foundation

/// 사용법 출력
func printUsage() {
    print("""
    ScrollSwitcher - macOS 트랙패드/마우스 스크롤 방향 개별 설정

    사용법:
        ScrollSwitcher [옵션]

    옵션:
        --help, -h              이 도움말 출력
        --verbose, -v           디버그 출력 활성화
        --invert-trackpad       트랙패드 스크롤도 반전 (기본: Natural 유지)
        --no-invert-mouse       마우스 스크롤 반전 비활성화
        --invert-horizontal     수평 스크롤도 반전

    기본 동작:
        - 트랙패드: Natural scrolling 유지 (손가락 방향 = 콘텐츠 방향)
        - 마우스: Traditional scrolling (휠 아래 = 콘텐츠 아래)

    필수 권한:
        시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서
        이 앱에 권한을 부여해야 합니다.

    종료: Ctrl+C
    """)
}

/// 시그널 핸들러 설정
func setupSignalHandler() {
    signal(SIGINT) { _ in
        print("\n종료 중...")
        ScrollInterceptor.shared.stop()
        exit(0)
    }

    signal(SIGTERM) { _ in
        ScrollInterceptor.shared.stop()
        exit(0)
    }
}

/// 메인 함수
func main() {
    let args = CommandLine.arguments

    // 옵션 파싱
    if args.contains("--help") || args.contains("-h") {
        printUsage()
        return
    }

    let interceptor = ScrollInterceptor.shared

    // 옵션 적용
    interceptor.verbose = args.contains("--verbose") || args.contains("-v")
    interceptor.invertTrackpadScroll = args.contains("--invert-trackpad")
    interceptor.invertMouseScroll = !args.contains("--no-invert-mouse")
    interceptor.invertHorizontal = args.contains("--invert-horizontal")

    print("ScrollSwitcher 시작...")
    print("설정:")
    print("  - 마우스 스크롤 반전: \(interceptor.invertMouseScroll)")
    print("  - 트랙패드 스크롤 반전: \(interceptor.invertTrackpadScroll)")
    print("  - 수평 스크롤 반전: \(interceptor.invertHorizontal)")
    print("")

    // 접근성 권한 확인
    if !interceptor.checkAccessibility() {
        print("⚠️  접근성 권한이 필요합니다.")
        print("   시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서")
        print("   이 앱에 권한을 부여해 주세요.")
        print("")
        interceptor.requestAccessibility()

        // 권한 획득까지 폴링
        print("권한 대기 중... (권한 부여 후 자동으로 시작됩니다)")
        while !interceptor.checkAccessibility() {
            Thread.sleep(forTimeInterval: 1.0)
        }
        print("✓ 접근성 권한 획득!")
    }

    // 시그널 핸들러 설정
    setupSignalHandler()

    // 인터셉터 시작
    guard interceptor.start() else {
        print("❌ ScrollInterceptor 시작 실패")
        exit(1)
    }

    print("")
    print("✓ 스크롤 감지 활성화됨")
    print("  종료하려면 Ctrl+C를 누르세요")
    print("")

    // 메인 RunLoop 실행 (이벤트 처리를 위해 필수)
    RunLoop.main.run()
}

// 프로그램 시작
main()
