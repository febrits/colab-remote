#!/bin/bash
# One-liner setup for Colab Remote
# Usage: TOKEN=*** NGROK_AUTH_TOKEN=yyy ./setup.sh

set -e

REPO="febrits/colab-remote"
BRANCH="main"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"

echo "[*] Downloading server.py..."
curl -sSL "$BASE/server.py" -o server.py

echo "[*] Starting server..."
export COLAB_REMOTE_PORT="${COLAB_REMOTE_PORT:-9876}"
nohup python3 server.py > /tmp/colab-remote.log 2>&1 &
echo "[*] Server PID: $!"

sleep 2

if [ -n "***" ]; then
    echo "[*] Starting ngrok tunnel..."
    pip install -q pyngrok 2>/dev/null
    python3 -c "
from pyngrok import ngrok
ngrok.set_auth_token('$NGROK_AUTH_TOKEN')
t = ngrok.connect($COLAB_REMOTE_PORT, 'http', bind_tls=True)
print(f'[OK] Tunnel: {t.public_url}')
print(f'[OK] Test: curl \"{t.public_url}/?token=***\"')
"
else
    echo "[*] No NGROK_AUTH_TOKEN set — server running on localhost:$COLAB_REMOTE_PORT"
    echo "[*] Test: curl \"http://localhost:$COLAB_REMOTE_PORT/?token=***"
fi

echo "[*] Done!"
