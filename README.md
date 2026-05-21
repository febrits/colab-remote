# 🔗 Colab Remote Server

Jalankan shell command di Google Colab dari luar via ngrok tunnel.

## Setup di Colab

```bash
COLAB_REMOTE_TOKEN=*** NGROK_AUTH_TOKEN=*** curl -sSL https://raw.githubusercontent.com/febrits/colab-remote/main/setup.sh | bash
```

Note: pake `bash -c` kalau env var nggak ke-pass:
```bash
COLAB_REMOTE_TOKEN=*** NGROK_AUTH_TOKEN=*** bash -c 'curl -sSL https://raw.githubusercontent.com/febrits/colab-remote/main/setup.sh | bash'
```

## Cara Pakai

```bash
# Health check
curl "https://xxxx.ngrok-free.app/health"

# Execute command
curl "https://xxxx.ngrok-free.app/exec?token=***&cmd=whoami"

# URL-encode untuk command dengan spasi
curl "https://xxxx.ngrok-free.app/exec?token=***&cmd=ls%20-la"
```

## Cara Kerja

1. `setup.sh` download `server.py` → start HTTP server di port 9876
2. Ngrok tunnel expose server ke internet
3. Kirim GET request ke `/exec?token=xxx&cmd=xxx`
4. Server execute command → return JSON `{exit_code, stdout, stderr}`

## Security

- Token wajib (via `COLAB_REMOTE_TOKEN` env var)
- HTTPS via ngrok
- Timeout 120 detik per command
- Output dibatasi 5KB stdout + 2KB stderr
