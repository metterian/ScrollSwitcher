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
        --trackpad-traditional  트랙패드를 Traditional 방식으로 변경
        --mouse-natural         마우스를 Natural 방식으로 변경
        --horizontal            수평 스크롤에도 동일하게 적용

    스크롤 방식:
        - Natural: 콘텐츠가 손가락/휠 방향을 따라감 (터치스크린 방식)
        - Traditional: 스크롤바 조작 방식 (휠 아래 = 페이지 다운)

    기본 동작:
        - 트랙패드: Natural (macOS 기본값 유지)
        - 마우스: Traditional (휠 아래 = 페이지 다운)

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
    interceptor.trackpadNatural = !args.contains("--trackpad-traditional")
    interceptor.mouseNatural = args.contains("--mouse-natural")
    interceptor.applyHorizontal = args.contains("--horizontal")

    print("ScrollSwitcher 시작...")
    print("설정:")
    print("  - 트랙패드: \(interceptor.trackpadNatural ? "Natural" : "Traditional")")
    print("  - 마우스: \(interceptor.mouseNatural ? "Natural" : "Traditional")")
    print("  - 수평 스크롤: \(interceptor.applyHorizontal ? "적용" : "미적용")")
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
