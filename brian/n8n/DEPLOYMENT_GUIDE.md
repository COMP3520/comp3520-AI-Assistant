# n8n + ngrok Setup (Short Guide)

Use this guide to run the project locally and share it via ngrok.

## 1) Go to project folder

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
```

## 2) Start Docker services

```bash
docker compose up -d
docker compose ps
```

Expected: `n8n`, `postgres`, `whisper`, `tts` are `Up`.

## 3) Set ngrok token (one-time)

```bash
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
ngrok config check
```

## 4) Start static chat server

Run in terminal A:

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
python3 -m http.server 8080
```

## 5) Start ngrok tunnels (free plan safe)

Run in terminal B:

```bash
cd /Users/brianho/comp3520-ai/brian/n8n
./start_ngrok.sh
```

If needed once:

```bash
chmod +x ./start_ngrok.sh
```

Expected ngrok output includes 2 forwarding URLs:
- `... -> http://localhost:8080` (chat page)
- `... -> http://localhost:5678` (n8n backend)

## 6) Open public chat URL

```text
https://<chat-ngrok-domain>/chat.html?n8nBase=https://<n8n-ngrok-domain>
```

Example:

```text
https://abcd.ngrok-free.app/chat.html?n8nBase=https://wxyz.ngrok-free.app
```

## 7) Quick health checks

```bash
curl -I http://localhost:8080/chat.html
curl -I http://localhost:5678
```

Both should return `200`.

## 8) When ngrok URL changes (very common on free plan)

1. Restart ngrok with `./start_ngrok.sh`
2. Copy new forwarding URLs
3. Reopen chat URL with new `n8nBase` query parameter
4. If chat still uses old backend, click `Reset` button in the page

## Common errors (fast fixes)

- `ERR_NGROK_108`: multiple ngrok sessions on free plan -> use only `./start_ngrok.sh`
- `ERR_NGROK_4018`: token/account issue -> run `ngrok config add-authtoken <token>` again
- `ERR_NGROK_8012`: tunnel up but local service down -> restart `python3 -m http.server 8080` and check Docker
- Chat 404: server started in wrong folder -> run server from `brian/n8n`
