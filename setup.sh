#!/bin/bash
# One-liner setup: COLAB_REMOTE_TOKEN=*** NGROK_AUTH_TOKEN=*** ./setup.sh
set -e

BASE="https://raw.githubusercontent.com/febrits/colab-remote/main"

echo "[*] Downloading server.py..."
curl -sSL "$BASE/server.py" -o server.py

PORT="${COLAB_REMOTE_PORT:-9876}"
TOKEN=***

# Kill old processes
kill $(pgrep -f "python3 server.py") 2>/dev/null || true
sleep 1

# Start server with token directly via env var (no sed needed)
echo "[*] Starting server on port $PORT with token: ${TOKEN:***"
COLAB_REMOTE_TOKEN="$TOKEN" nohup python3 server.py > /tmp/colab-remote.log 2>&1 &
echo "[*] Server PID: $!"
sleep 2

# Verify server is running
HEALTH=$(curl -s http://localhost:$PORT/health 2>/dev/null || echo "failed")
if [ "$HEALTH" = '{"status":"ok"}' ]; then
    echo "[OK] Server running. Token: $TOKEN"
else
    echo "[!] Server may not be running. Check: cat /tmp/colab-remote.log"
fi

if [ -n "***" ]; then
    echo "[*] Starting ngrok..."
    pip install -q pyngrok 2>/dev/null

    NGROK_AUTH_TOKEN="***" python3 << 'PYEOF'
import os, time
from pyngrok import ngrok

ngrok.set_auth_token(os.environ["NGROK_AUTH_TOKEN"])
port = int(os.environ.get("COLAB_REMOTE_PORT", 9876))

t = ngrok.connect(port, "http", bind_tls=True)
time.sleep(2)

token = os.environ.get("COLAB_REMOTE_TOKEN", "")
print(f"[OK] Tunnel URL: {t.public_url}")
print(f"[OK] Test: curl -s \"{t.public_url}/exec?token=***&cmd=whoami\"")

while True:
    time.sleep(3600)
PYEOF
else
    echo "[*] Skipping ngrok (no NGROK_AUTH_TOKEN)"
fi
