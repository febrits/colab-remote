#!/bin/bash
# Start ngrok tunnel + Colab Remote Server
# Usage: COLAB_REMOTE_TOKEN=your-secret-token ./start.sh

set -e

TOKEN="${COLAB_REMOTE_TOKEN:-change-me-to-something-secret}"
PORT="${COLAB_REMOTE_PORT:-9876}"

echo "[*] Installing dependencies..."
pip install pyngrok 2>/dev/null || true

echo "[*] Starting server on port $PORT..."
python3 server.py &
SERVER_PID=$!

echo "[*] Starting ngrok tunnel..."
python3 -c "
from pyngrok import ngrok
import os, sys

token = os.environ.get('NGROK_AUTH_TOKEN', '')
if token:
    ngrok.set_auth_token(token)

tunnel = ngrok.connect($PORT, 'http', bind_tls=True)
print(f'[OK] Ngrok tunnel: {public_url := tunnel.public_url}')
print(f'[OK] Example: curl \"{public_url}/?token={os.environ.get(\"COLAB_REMOTE_TOKEN\", \"change-me-to-something-secret\")}&cmd=whoami\"')

try:
    while True:
        import time
        time.sleep(60)
except KeyboardInterrupt:
    print()
    ngrok.disconnect(tunnel.public_url)
    print('[OK] Tunnel closed')
"

wait $SERVER_PID
