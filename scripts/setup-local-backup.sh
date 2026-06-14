#!/bin/bash
# daily_nfl 레포를 iCloud 백업 폴더에 클론/동기화하고
# launchd로 자동 pull을 설정하는 스크립트

BACKUP_DIR="/Users/june/Library/Mobile Documents/com~apple~CloudDocs/github"
REPO_DIR="$BACKUP_DIR/daily_nfl"
REPO_URL="https://github.com/nfldictionary/daily_nfl.git"
PLIST_NAME="com.daily_nfl.backup"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "=== daily_nfl 로컬 백업 설정 ==="

# 1. 백업 폴더 생성 및 클론
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[1/3] 레포 클론 중..."
    mkdir -p "$BACKUP_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    echo "      완료: $REPO_DIR"
else
    echo "[1/3] 이미 클론됨 → pull 실행"
    git -C "$REPO_DIR" pull
fi

# 2. 동기화 스크립트 생성
SYNC_SCRIPT="$HOME/.daily_nfl_sync.sh"
cat > "$SYNC_SCRIPT" <<'SYNC'
#!/bin/bash
REPO_DIR="/Users/june/Library/Mobile Documents/com~apple~CloudDocs/github/daily_nfl"
git -C "$REPO_DIR" pull --ff-only >> "$HOME/.daily_nfl_sync.log" 2>&1
SYNC
chmod +x "$SYNC_SCRIPT"
echo "[2/3] 동기화 스크립트 생성: $SYNC_SCRIPT"

# 3. launchd plist 등록 (1시간마다 자동 pull)
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SYNC_SCRIPT</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"
echo "[3/3] launchd 등록 완료 (1시간마다 자동 pull)"

echo ""
echo "✅ 설정 완료!"
echo "   백업 위치: $REPO_DIR"
echo "   로그:     ~/.daily_nfl_sync.log"
echo "   수동 동기화: $SYNC_SCRIPT"
