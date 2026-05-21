#!/usr/bin/env python3
"""Colab Remote Server — receive shell commands via HTTP."""

import subprocess, json, logging, os, sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("colab-remote")

PORT = int(os.environ.get("COLAB_REMOTE_PORT", 9876))
TOKEN = os.environ.get("COLAB_REMOTE_TOKEN", "change-me")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path)
        q = parse_qs(p.query)

        if p.path == "/health":
            return self.send_json(200, {"status": "ok"})

        if p.path == "/exec":
            token = q.get("token", [None])[0]
            if token != TOKEN:
                return self.send_json(403, {"error": "unauthorized"})
            cmd = q.get("cmd", [None])[0]
            if not cmd:
                return self.send_json(400, {"error": "missing cmd"})
            try:
                r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
                return self.send_json(200, {
                    "exit_code": r.returncode,
                    "stdout": r.stdout[-5000:] if r.stdout else "",
                    "stderr": r.stderr[-2000:] if r.stderr else "",
                })
            except subprocess.TimeoutExpired:
                return self.send_json(408, {"error": "timeout"})
            except Exception as e:
                return self.send_json(500, {"error": str(e)})

        self.send_json(404, {"error": "not found"})

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
    log.info(f"Listening on 0.0.0.0:{PORT}")
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
