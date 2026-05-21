# 🔗 Colab Remote Server

Jalankan shell command di Google Colab dari luar via ngrok tunnel.

## Setup di Colab (satu command)

```bash
TOKEN=*** NGROK_AUTH_TOKEN=yyy curl -sSL https://raw.githubusercontent.com/febrits/colab-remote/main/setup.sh | bash
```

## Kirim Command

```bash
# health check
curl "https://xxxx.ngrok-free.app/health"

# execute command
curl "https://xxxx.ngrok-free.app/exec?token=***&cmd=whoami"

# command with spaces (URL encode)
curl "https://xxxx.ngrok-free.app/exec?token=***&cmd=ls%20-la"
```

## Cara Kerja

1. `setup.sh` download `server.py` + start HTTP server di port 9876
2. Ngrok tunnel expose server ke internet
3. Kirim GET request dengan `?cmd=...&token=...`
4. Server execute command, return JSON output

## Security

- Token required (via `TOKEN` env var)
- HTTPS via ngrok
- Command timeout 120 detik
- Output dibatasi 5KB stdout + 2KB stderr
