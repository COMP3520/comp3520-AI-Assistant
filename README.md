# 🧠 AI Personal Operations Center (POC) - "The Second Brain"

## 📖 Project Overview
A local-first, privacy-focused agentic AI assistant built on **n8n**, **Ollama**, and **Docker**.
It handles intelligent chat, secure SSH terminal execution, expense tracking with built-in charting,
Google Workspace integration, and automated morning briefings — all running on your own machine.

***

## 🏗 System Architecture

The following diagram illustrates the flow of data between the User, the Supervisor Agent, and the main tools, all inside your own UI and terminal environment.

```mermaid
graph TD
    User([👤 User]) -->|Text / Voice| UI[Chat UI\nchat.html served by n8n]
    UI -->|POST /webhook/chat-response| RCV[Receive Msg]
    UI -->|POST /webhook/whisper-proxy| WSP[Whisper STT Container]
    UI -->|GET /webhook/tts-proxy| TTS[TTS Container :5000]

    RCV --> MEM[Read summary.md\nMEMORY_PATH]
    MEM --> TC[Task Classifier Agent\nllama3.2]

    TC -->|command| CMD[Command Task Summarizer]
    TC -->|normal| CC[Complexity Classifier\nllama3.2]
    TC -->|expense| EXP[Expense Extractor Agent\nllama3.2]
    TC -->|visualize| VIS[Get rows from DataTable]

    CMD --> OS[OS Detection\nuname -s / env:OS via SSH]
    OS --> MTA[Multi-Platform Terminal Assistant\nllama3.2]
    MTA --> PCJ[Parse Command JSON]
    PCJ --> APV{Approval Overlay\nin Chat UI}
    APV -->|Approved| SSH[SSH Execute\nPrivate Key Auth]
    APV -->|Denied| DEN[Denied Response]
    SSH --> FMT[Format Result]

    CC -->|Simple| SIM[Simple Task AI Agent\nllama3.2]
    CC -->|Hard| HRD[Hard Task AI Agent\nqwen3:8b]

    SIM --> TOOLS1[Google Workspace Tools\nCalendar · Docs · Sheets · Drive · Gmail · Tavily]
    HRD --> TOOLS2[Google Workspace Tools\nCalendar · Docs · Sheets · Drive · Gmail · Tavily]

    EXP --> FMT4[Format Response 4\namount · category · gain · date]
    FMT4 --> DBQ{expenses Table\nexists?}
    DBQ -->|Yes| INS[Insert Row\nn8n DataTable]
    DBQ -->|No| CRT[Create expenses Table\nthen Insert Row]
    INS --> RET[Return Response]
    CRT --> RET

    VIS --> AGG[JS Aggregation\nby category]
    AGG --> CA2[Classifier Agent2\nGain or Loss]
    CA2 -->|Gain| GC[gainChart\nQuickChart Pie PNG]
    CA2 -->|Loss| LC[lossChart\nQuickChart Pie PNG]
    GC --> RIMG[Respond to UI\nimage/png]
    LC --> RIMG

    CRON([⏰ 7 AM Cron]) --> GCAL[Get Today's Calendar\nGoogle Calendar]
    GCAL --> GEML[Get Overnight Emails\nGmail urgent/HSBC]
    GEML --> BLD[Build Briefing Context\nJS node]
    BLD --> MAA[Morning Analyst Agent\nllama3.2]
    MAA --> SND[Send Morning Briefing\nGmail]

    subgraph Memory
        SUMMD[summary.md]
    end
    MEM <--> SUMMD
```

***

## 🛠 Tech Stack

| Component               | Technology                                                       | Docker Image                            |
| ----------------------- | ---------------------------------------------------------------- | --------------------------------------- |
| Orchestration           | n8n                                                              | n8nio/n8n                               |
| LLM (Simple/Classifier) | Ollama — llama3.2:latest                                         | ollama/ollama                           |
| LLM (Hard tasks)        | Ollama — qwen3:8b                                                | ollama/ollama                           |
| Chat UI                 | chat.html (inline in n8n webhook, vanilla JS)                    | /                                       |
| Containerization        | Docker + Docker Compose                                          | /                                       |
| Public Tunnel           | ngrok                                                            | ngrok/ngrok                             |
| Speech-to-Text          | Whisper (self-hosted container)                                  | onerahmet/openai-whisper-asr-webservice |
| Text-to-Speech          | TTS (self-hosted container on port 5000)                         | synesthesiam/wyoming-piper              |
| Integrations            | Gmail, Google Calendar, Google Docs, Google Sheets, Google Drive | /                                       |
| Web Search              | Tavily                                                           | /                                       |
| SSH Execution           | OpenSSH (private key auth, Windows/macOS/Linux)                  | /                                       |
| Memory                  | summary.md file via $env.MEMORY_PATH                             | /                                       |
| Expense DB              | n8n built-in DataTable (table name: expenses)                    | /                                       |
| Chart Generation        | n8n built-in QuickChart node (pie charts, PNG output)            | /                                       |

***

## 🚀 Core Features & Workflows

### 🔧 Tools Available to Agents
- **Gmail** — read messages, send emails
- **Google Calendar** — create events, list events
- **Google Docs** — get / update documents
- **Google Sheets** — get rows, append/update rows, create sheets
- **Google Drive** — search files and folders
- **Tavily** — web search
- **SSH Terminal** — execute shell commands on host machine (dedicated pipeline)
- **n8n DataTable** — read / write expenses database
- **n8n QuickChart** — generate pie charts (PNG)

### 1. 🎙️ Telegram Voice Interface ("Walk & Talk")
**Goal:** Hands-free interaction while walking via Telegram.
- **Input:** User sends Voice Note via **Telegram** (not yet connected; currently browser-only)
- **Transcribe:** n8n Webhook receives audio → Whisper Container
- **Think:** Transcript returned to Chat UI → auto-sent to `/webhook/chat-response` → **Task Classifier Agent** → Ollama (llama3.2 / qwen3:8b)
- **Speak:** LLM response → **Kokoro TTS** → Audio file
- **Output:** n8n sends audio file back to Telegram as a reply

### 2. 👮 Supervisor & Sub-Agents Pattern
**Goal:** Break down complex tasks into atomic actions.
- **Supervisor Agent:** Task Classifier Agent (llama3.2) analyzes intent and routes to specific workers
  - **Worker A (Command):** Multi-Platform Terminal Assistant — executes shell commands via SSH
  - **Worker B (Simple Task):** Simple Task AI Agent (llama3.2) — handles factual lookups and lightweight tasks
  - **Worker C (Hard Task):** Hard Task AI Agent (qwen3:8b) — handles reasoning, multi-step logic, and coding
  - **Worker D (Expense):** Expense Extractor AI Agent (llama3.2) — parses and logs expense transactions
  - **Worker E (Visualize):** QuickChart pipeline — aggregates DataTable and renders pie charts

### 3. 🔒 Secure SSH & Human-in-the-Loop
**Goal:** Execute terminal commands safely with user approval.
- **Draft:** Command Task Summarizer (llama3.2) rewrites user intent into a plain English task → Multi-Platform Terminal Assistant (llama3.2) generates the correct shell command per OS (Windows/macOS/Linux)
- **Risk Assessment:** Command is classified as 🟢 low / 🟡 medium / 🔴 high with a reason
- **Human Gate:** Chat UI shows an Approval Overlay with command, description, and risk — user clicks **[Approve] / [Deny]**
- **Execution:** SSH node runs command via private key only upon explicit approval
- **OS Detection:** Runs `uname -s` (macOS/Linux) and `$env:OS` (Windows) in parallel to detect host OS

### 4. 🧠 Long-Term Memory
**Goal:** Continuity across sessions.
- **Session Start:** Workflow reads `summary.md` (user profile) via `$env.MEMORY_PATH` before processing every query
- **On Every Message:** Memory Updater (llama3.2) rewrites and saves an updated `summary.md` in parallel with the agent response — not at session end
- Profile stores projects, preferences, schedule context, and study interests

### 5. 💰 Expense Tracker
**Goal:** Frictionless expense logging with visual insights.
- **Input:** User texts naturally, e.g. *"Spent $50 on lunch"*
- **Extraction:** Expense Extractor Agent parses `{"amount": 50, "category": "Food", "date": "...", "gain": false}`
- **Storage:** Appended to **n8n's built-in DataTable** (`expenses` table); auto-created if absent
- **Visualization:**
  - **Trigger:** User asks *"Show my spending chart"*
  - **Action:** Reads all rows from DataTable → JS node aggregates totals by category → Classifier Agent2 picks Gain or Loss
  - **Output:** **n8n QuickChart node** generates a pie chart (PNG) returned directly to Chat UI

### 6. 🌅 Morning Analyst Briefing
**Goal:** Executive summary delivered at 7:00 AM.
- **Trigger:** Cron schedule — every day at 7:00 AM
- **Data Sources:**
  - **Calendar:** Fetches today's events from Google Calendar
  - **Gmail:** Filters for `urgent` or `@hsbc.com` emails received overnight (last 12 hours)
- **Synthesis:** Morning Analyst Agent (llama3.2) generates a structured briefing with: Markets, Today's Schedule, Overnight Emails, Action Items Before Noon
- **Output:** Briefing delivered via Gmail to configured address

***

## 📁 Key Files

| File | Purpose |
|:---|:---|
| `Main Workflow.json` | Full n8n workflow (all nodes + connections) |
| `brian/memory/summary.md` | Persistent user profile / memory file |
| `brian/n8n/SSH setup.md` | SSH configuration guide |
| `docker-compose.yml` | Container orchestration |
| `Windows_Chat.bat` | Windows launcher for Chat UI |
| `MAC_Chat.command` | macOS launcher for Chat UI |

## 📂 Folder Structure

```text
/ai-poc-project
├── docker-compose.yml       # Orchestrates n8n, ollama, whisper, db
├── .env                     # API Keys (Telegram, Google, OpenAI if needed)
├── /n8n_workflows           # JSON exports of n8n flows
│   ├── supervisor_agent.json
│   ├── voice_pipeline.json
│   └── morning_briefing.json
├── /python_sandbox          # Scripts for code interpreter
│   ├── market_data.py
│   └── generate_chart.py
├── /memory                  # Local storage for context
│   ├── summary.md
│   └── vector_store/
└── /data                    # Persistent volume data
```

***

## 🗓 Implementation Roadmap

### Phase 1: Foundation (Days 1-2)
- [ ] Set up `docker-compose.yml` with Ollama, n8n, and PostgreSQL.
- [ ] Connect Telegram Bot API to n8n Webhook.
- [ ] Verify Ollama is running `llama3.2` locally.

### Phase 2: The Brain & Tools (Days 3-5)
- [ ] Build the **Supervisor Agent** node in n8n.
- [ ] Integrate **Google Workspace** (Gmail/Calendar/Sheets) credentials.
- [ ] Implement **SSH Tool** with the "Human-in-the-Loop" Telegram button.

### Phase 3: Voice & Multimedia (Days 6-7)
- [ ] Deploy **Whisper** and **TTS** containers.
- [ ] Create the Audio processing workflow (Audio $\to$ Text $\to$ AI $\to$ Audio).

### Phase 4: Memory & Analysis (Days 8-10)
- [ ] Set up the **Expense Database** and Python Chart generation script.
- [ ] Implement the **"Read Summary.md"** logic at start of chat.
- [ ] Configure **LangFuse** for observability.

***

## 🗓 Workload Partitioning (3-Part Split)

To ensure manageable development, the project is divided into three equal workload sprints.

### Part 1: Core Infrastructure & Basic Orchestration
**Focus:** Setting up the "Body" (Docker/n8n) and "Brain" (Ollama) to establish basic communication.
*   [ ] **Infrastructure:** Configure `docker-compose.yml` with **n8n**, **Ollama** (pull `llama3.2`), **PostgreSQL**, and **LangFuse**.
*   [ ] **Interface:** Connect **Telegram Bot API** to n8n Webhook for text-based chat.
*   [ ] **Orchestration:** Build the foundational **Supervisor Agent** node in n8n to route basic "Chat" vs. "Task" intents.
*   [ ] **Observability:** Initialize **LangFuse** to trace LLM thoughts and debug the initial agent logic.
*   [ ] **Interface:** Make up and design the UI interface for the project ( streamlit/ Javascript) 

### Part 2: Tools, Security & Analytics
**Focus:** Giving the agent "Hands" (SSH/Tools) and "Eyes" (Google/Data) to perform work.
*   [ ] **Integrations:** Configure **Google Cloud Console** credentials for Gmail, Calendar, and Sheets access.
*   [ ] **Secure Ops:** Implement the **SSH Tool** with the "Human-in-the-Loop" Telegram button flow (Draft $\to$ Approve $\to$ Execute).
*   [ ] **Data Analysis:** Set up the **Python Sandbox** container and write the script for generating **Expense Charts** (`matplotlib`).
*   [ ] **Workflow:** Create the **"Morning Analyst"** automation to aggregate Calendar and Gmail data into a daily text summary.

### Part 3: Voice, Memory & Advanced Synthesis
**Focus:** Adding the "Ears/Voice" (Multimedia) and "Soul" (Long-term Context).
*   [ ] **Multimedia Stack:** Deploy **Whisper** (STT) and **Kokoro/Coqui** (TTS) containers to the Docker stack.
*   [ ] **Voice Pipeline:** Build the n8n workflow for **Audio Note $\to$ Transcript $\to$ LLM $\to$ Audio Reply**.
*   [ ] **Long-Term Memory:** Implement the **Vector Store** (ChromaDB/Pgvector) logic to read/write user facts.
*   [ ] **Context Injection:** Create the pre-prompt logic to read `summary.md` and inject user preferences into every new session.

***

## 🚦 Getting Started

Here’s a well-structured **README setup section** you can add (or replace) in your project's README.md. It focuses on a clear, step-by-step guide covering:

- Docker setup (assuming `docker-compose.yml` exists in the repo)
- n8n credentials configuration (including Google OAuth)
- ngrok setup (for exposing n8n/Streamlit/Telegram webhooks publicly)
- Streamlit access & run

```markdown
## Quick Start – Local Development Setup

This project runs as a Docker-based stack with n8n (workflow automation), Ollama (local LLM), Streamlit (UI), and optional public exposure via ngrok.

### Prerequisites

- Docker & Docker Compose installed  
  → https://docs.docker.com/get-docker/
- Git
- (Optional but recommended for public access / Telegram bot)  
  → ngrok account (free tier works)

### Step 1: Clone the Repository

```bash
git clone https://github.com/COMP3520/comp3520-AI-Assistant.git
cd comp3520-AI-Assistant
```

### Step 2: Prepare Environment Variables (.env)



**Important – Google Credentials setup**  
1. Go to https://console.cloud.google.com/apis/credentials  
2. Create OAuth 2.0 Client ID → Web application  
3. Add authorized redirect URIs:  
   - `http://localhost:5678/rest/oauth2-credential/callback` (local)  
   - Later: your-ngrok-URL/rest/oauth2-credential/callback  
4. Copy **Client ID** and **Client Secret** → paste into `.env`  
5. Enable APIs: Gmail API, Google Calendar API, Google Sheets API, Google Drive API (depending on your workflows)

### Step 3: Start the Docker Stack

```bash
docker compose up -d
```

Wait ~1–2 minutes for services to be healthy.

Check running containers:
```bash
docker compose ps
```

### Step 4: Initialize Ollama Model (once)

```bash
docker exec -it ollama ollama pull llama3.2   # or llama3.2:3b if you want smaller
# or run interactively:
docker exec -it ollama ollama run llama3.2
```

### Step 5: Configure n8n (Core Workflows + Credentials)

1. Open n8n UI → http://localhost:5678  
   Login with credentials from `.env` (admin / your-password)

2. **Set up credentials** (in n8n → Credentials tab):  
   - Telegram → Bot token from `.env`  
   - Google → OAuth2 → use the Client ID/Secret from `.env`  
     → n8n will guide you through Google sign-in & consent  
   - (Optional) OpenAI / other services if used

3. **Import workflows**  
   - Go to Workflows → ... → Import from File/URL  
   - Import files from `n8n_workflows/` folder (e.g. `supervisor_agent.json`, `voice_pipeline.json`, `morning_briefing.json`)  
   - Activate them

4. Test a simple workflow (e.g. Telegram trigger → LLM → reply)

### Step 6: Expose Services Publicly with ngrok (Telegram webhook, testing, etc.)

Many features (Telegram bot webhook, Google OAuth redirect) require a public HTTPS URL.

1. **Sign up** (free) → https://ngrok.com  
2. **Download & install ngrok**  
   - https://ngrok.com/download  
   - Unzip and move to a folder in your PATH (or run from Downloads)

3. Authenticate (only once):
   ```bash
   ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
   ```

4. Expose n8n (port 5678):
   ```bash
   ngrok http 5678
   ```

   → You'll get a URL like `https://abcd-1234.ngrok-free.app`

5. **Update Google OAuth redirect URI** (in Google Console):  
   Add `https://abcd-1234.ngrok-free.app/rest/oauth2-credential/callback`

6. **Update Telegram webhook** (in n8n Telegram node or via API):  
   Set webhook to `https://abcd-1234.ngrok-free.app/webhook/xxx`

7. (Optional) Expose Streamlit too:
   ```bash
   ngrok http 8501   # or whatever port Streamlit uses
   ```

**Tip**: Use ngrok paid plan or custom domain for static URLs (free URLs change on restart).

### Step 7: Access Streamlit UI

Once running:

- Local: http://localhost:8501 (or the port defined in docker-compose for Streamlit service)  
- Via ngrok: the https URL from ngrok http 8501

You should see the chat interface / dashboard for interacting with the AI assistant.

### Troubleshooting

- n8n not starting? Check logs: `docker compose logs n8n`  
- Google OAuth fails? Double-check redirect URI matches exactly  
- Ollama slow? Make sure you pulled the model  
- Ports conflict? Change them in `docker-compose.yml`

Enjoy your local-first AI Personal Operations Center! 🚀
```

Feel free to adjust port numbers, folder names (`n8n_workflows/`), or service names according to your actual `docker-compose.yml`. If your repo has different structure (e.g. no Streamlit service yet), you can add a note like:

> Streamlit is currently under development — you can run it manually via `streamlit run brian/streamlit.py` after installing requirements.

Let me know if you want to add screenshots, architecture diagram section, or more advanced options (e.g. Caddy reverse proxy instead of ngrok).
