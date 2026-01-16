#!/bin/bash

set -e

BINARY_NAME="ScrollSwitcher"
INSTALL_DIR="$HOME/bin"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_NAME="com.scrollswitcher.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 ScrollSwitcher 설치 시작..."

# 1. 빌드
echo "📦 빌드 중..."
cd "$SCRIPT_DIR"
swift build -c release

# 2. 설치 디렉토리 생성
mkdir -p "$INSTALL_DIR"

# 3. 바이너리 복사
echo "📁 바이너리 설치 중..."
cp ".build/release/$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# 4. LaunchAgent 설정
echo "⚙️  LaunchAgent 설정 중..."
mkdir -p "$LAUNCH_AGENT_DIR"

cat > "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.scrollswitcher</string>

    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$BINARY_NAME</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/scrollswitcher.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/scrollswitcher.err</string>
</dict>
</plist>
EOF

# 5. 기존 LaunchAgent 언로드 (있으면)
launchctl unload "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME" 2>/dev/null || true

# 6. LaunchAgent 로드
launchctl load "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME"

echo ""
echo "✅ 설치 완료!"
echo ""
echo "📍 설치 위치:"
echo "   바이너리: $INSTALL_DIR/$BINARY_NAME"
echo "   LaunchAgent: $LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME"
echo ""
echo "⚠️  접근성 권한이 필요합니다:"
echo "   시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용"
echo "   에서 '$BINARY_NAME'에 권한을 부여해주세요."
echo ""
echo "🔍 상태 확인: launchctl list | grep scrollswitcher"
echo "📋 로그 확인: cat /tmp/scrollswitcher.log"
