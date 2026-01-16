#!/bin/bash

BINARY_NAME="ScrollSwitcher"
INSTALL_DIR="$HOME/bin"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_NAME="com.scrollswitcher.plist"

echo "🗑️  ScrollSwitcher 제거 시작..."

# 1. LaunchAgent 언로드
echo "⏹️  서비스 중지 중..."
launchctl unload "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME" 2>/dev/null || true

# 2. LaunchAgent 파일 삭제
if [ -f "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME" ]; then
    rm "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_NAME"
    echo "   LaunchAgent 삭제됨"
fi

# 3. 바이너리 삭제
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    rm "$INSTALL_DIR/$BINARY_NAME"
    echo "   바이너리 삭제됨"
fi

# 4. 로그 파일 삭제
rm -f /tmp/scrollswitcher.log /tmp/scrollswitcher.err 2>/dev/null || true

echo ""
echo "✅ 제거 완료!"
