# n8n + ngrok Setup (Mac/Linux + Windows)

Use this guide to run locally and share your chat page publicly.

## 1) Start Docker services

Mac/Linux:

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
docker compose up -d
docker compose ps
```

Windows (PowerShell):

```powershell
cd C:\path\to\comp3520-ai\brian\n8n
docker compose up -d
docker compose ps
```

Expected: `n8n`, `postgres`, `whisper`, `tts` are `Up`.

## 2) Set ngrok token (one-time)

```bash
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
ngrok config check
```

## 3) Start static chat server (Terminal A)

Mac/Linux:

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
python3 -m http.server 8080
```

Windows (PowerShell):

```powershell
cd C:\path\to\comp3520-ai\brian\n8n
py -m http.server 8080
```

## 4) Start ngrok tunnels (Terminal B)

Mac/Linux:

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
./start_ngrok.sh
```

Windows (PowerShell):

```powershell
cd C:\path\to\comp3520-ai\brian\n8n
ngrok start --all --config "$env:USERPROFILE\AppData\Local\ngrok\ngrok.yml,./ngrok.yml"
```

Expected ngrok output includes:
- `... -> http://localhost:8080` (chat page)
- `... -> http://localhost:5678` (n8n backend)

## 5) Open public chat URL

```text
https://<chat-ngrok-domain>/chat.html?n8nBase=https://<n8n-ngrok-domain>
```

Example:

```text
https://abcd.ngrok-free.app/chat.html?n8nBase=https://wxyz.ngrok-free.app
```

## 6) Quick health checks

Mac/Linux:

```bash
curl -I http://localhost:8080/chat.html
curl -I http://localhost:5678
```

Windows (PowerShell):

```powershell
curl.exe -I http://localhost:8080/chat.html
curl.exe -I http://localhost:5678
```

Both should return `200`.

## 7) When ngrok URL changes (free plan)

1. Restart ngrok command in Terminal B
2. Copy new forwarding URLs
3. Reopen chat URL with the new `n8nBase`
4. If backend is stale, click `Reset` button in chat page

## Common errors (fast fixes)

- `ERR_NGROK_108`: multiple ngrok sessions -> run one command with both tunnels
- `ERR_NGROK_4018`: token/account issue -> rerun `ngrok config add-authtoken <token>`
- `ERR_NGROK_8012`: tunnel up but local service down -> restart Docker or HTTP server
- Chat `404`: started HTTP server in wrong folder -> must run from `brian/n8n`
