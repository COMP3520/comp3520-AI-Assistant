#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  Chat Server Launcher — double-click this file to start & open browser
#  No editing needed — works from any location.
# ═══════════════════════════════════════════════════════════════════════════

# ── Resolve paths ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="$SCRIPT_DIR/brian/n8n"
PORT=8080
URL="http://localhost:$PORT/chat.html"
LOG="/tmp/chat_server.log"
PID_FILE="/tmp/chat_server.pid"

# ── 1. Check the folder exists ──────────────────────────────────────────────
if [ ! -d "$SERVE_DIR" ]; then
    echo ""
    echo "  ERROR: Folder not found:"
    echo "    $SERVE_DIR"
    echo ""
    echo "  Make sure brian/n8n exists in the same folder as this script."
    read -p "  Press Enter to close..."
    exit 1
fi

# ── 2. Find Python (prefer python3) ─────────────────────────────────────────
if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null; then
    PYTHON=python
else
    echo ""
    echo "  ERROR: Python not found."
    echo "  Install it from https://python.org"
    read -p "  Press Enter to close..."
    exit 1
fi

# ── 3. Kill any existing process on port $PORT ──────────────────────────────
EXISTING_PID=$(lsof -ti:$PORT 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    echo "  Port $PORT in use (PID $EXISTING_PID) — stopping it..."
    kill -9 $EXISTING_PID 2>/dev/null
    sleep 0.5
fi

# ── 4. Start server in background, log to /tmp/chat_server.log ─────────────
#  nohup + & detaches it fully — closing this Terminal window won't kill it.
echo "  Starting server at $URL ..."
cd "$SERVE_DIR"
nohup $PYTHON -m http.server $PORT > "$LOG" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

# ── 5. Wait until port is actually listening (up to 10 s) ───────────────────
TRIES=0
while ! nc -z localhost $PORT 2>/dev/null; do
    sleep 1
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge 10 ]; then
        echo "  WARNING: Server did not respond in 10 s — opening browser anyway."
        break
    fi
done

# ── 6. Open browser ─────────────────────────────────────────────────────────
open "$URL"

# ── 7. Print status and close ───────────────────────────────────────────────
echo ""
echo "  ✓ Server running  (PID $SERVER_PID)"
echo ""
echo "  View logs : tail -f $LOG"
echo "  Stop      : kill \$(cat $PID_FILE)"
echo ""
echo "  This window will close in 5 seconds — the server keeps running."
sleep 5
