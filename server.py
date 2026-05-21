#!/usr/bin/env python3
"""
Colab Remote Server - receive commands via HTTP and execute in shell.
Usage: python server.py
"""

import subprocess
import json
import logging
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("colab-remote")

# Config
PORT = int(os.environ.get("COLAB_REMOTE_PORT", 9876))
TOKEN = os.environ.get("COLAB_REMOTE_TOKEN", "change-me-to-something-secret")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)

        # Health check
        if parsed.path == "/health":
            self.send_json(200, {"status": "ok"})
            return

        # Auth check
        query = parse_qs(parsed.query)
        token = query.get("token", [None])[0]
        if token != TOKEN:
            self.send_json(403, {"error": "unauthorized"})
            return

        # Execute command
        cmd = query.get("cmd", [None])[0]
        if not cmd:
            self.send_json(400, {"error": "missing cmd parameter"})
            return

        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=120
            )
            self.send_json(200, {
                "exit_code": result.returncode,
                "stdout": result.stdout[-5000:] if result.stdout else "",
                "stderr": result.stderr[-2000:] if result.stderr else "",
            })
        except subprocess.TimeoutExpired:
            self.send_json(408, {"error": "command timed out"})
        except Exception as e:
            self.send_json(500, {"error": str(e)})

    def send_json(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        log.info(fmt % args)

if __name__ == "__main__":
    log.info(f"Starting Colab Remote Server on port {PORT}")
    log.info(f"Token: {'set' if TOKEN != 'change-me-to-something-secret' else 'DEFAULT — change it!'}")
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("Shutting down")
        server.shutdown()
