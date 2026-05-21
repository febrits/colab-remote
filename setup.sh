#!/bin/bash
# One-liner setup: TOKEN=*** NGROK_AUTH_TOKEN=xxx ./setup.sh
set -e

BASE="https://raw.githubusercontent.com/febrits/colab-remote/main"

echo "[*] Downloading server.py..."
curl -sSL "$BASE/server.py" -o server.py

PORT="${COLAB_REMOTE_PORT:-9876}"
TOKEN="${COLAB_REMOTE_TOKEN:-changeme}"

echo "[*] Starting server on port $PORT..."
nohup python3 server.py > /tmp/colab-remote.log 2>&1 &
echo "[*] Server PID: $!"
sleep 2

if [ -n "***" ]; then
    echo "[*] Starting ngrok..."
    pip install -q pyngrok 2>/dev/null
    python3 -c "
import os, time
from pyngrok import ngrok
ngrok.set_auth_token(os.environ['NGROK_AUTH_TOKEN'])
t = ngrok.connect(int(os.environ.get('COLAB_REMOTE_PORT', 9876)), 'http', bind_tls=True)
time.sleep(1)
print(f'[OK] Tunnel URL: {t.public_url}')
print(f'[OK] Test: curl -s \"{t.public_url}/exec?token={os.environ.get(\"COLAB_REMOTE_TOKEN\",\"changeme\")}&cmd=whoami\" | python3 -m json.tool')
"
else
    echo "[*] Skipping ngrok (no NGROK_AUTH_TOKEN)"
    echo "[*] Test: curl -s \"http://localhost:$PORT/exec?token=$TOKEN&cmd=whoami\""
fi
