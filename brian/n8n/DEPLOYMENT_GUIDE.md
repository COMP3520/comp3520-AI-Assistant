# 🚀 Deployment Guide: n8n + ngrok + Streamlit Cloud

This guide explains how to run your local n8n AI Agent via Docker, expose it to the internet using ngrok, and connect it to a beautiful Streamlit UI hosted on Streamlit Cloud.

---

## 🛠️ Step 1: Start Local Services (Docker & n8n)

First, make sure your n8n backend is running locally.

1. Open a terminal and navigate to the project directory:
   ```bash
   cd path/to/comp3520-AI-Assistant/brian/n8n
   ```

2. Start the Docker containers (n8n, Postgres, Ollama):
   ```bash
   docker-compose up -d
   ```

3. Verify n8n is running by opening your browser and going to:
   [http://localhost:5678](http://localhost:5678)

4. Ensure your workflow (`AI Agent - UI with summary.md.json`) is imported and the **Active toggle is ON** (Green).

---

## 🌐 Step 2: Expose n8n with ngrok

Since Streamlit Cloud is on the internet, it cannot talk to your `localhost`. We use ngrok to create a secure public URL.

1. Open a **new** terminal window.
2. Start ngrok pointing to your n8n port:
   ```bash
   ngrok http 5678
   ```
3. You will see a screen with a `Forwarding` URL. 
   Copy the **HTTPS URL** (e.g., `https://b6d5-175-159-182-197.ngrok-free.app`). 
   *Leave this terminal running!*

---

## ☁️ Step 3: Deploy to Streamlit Cloud

Now we host the chat interface on Streamlit.

1. Go to [share.streamlit.io](https://share.streamlit.io) and log in.
2. Click **New app**.
3. Fill in the repository details:
   - **Repository:** `hck717/comp3520-AI-Assistant`
   - **Branch:** `main`
   - **Main file path:** `brian/n8n/streamlit_app.py`
4. Click **Advanced settings** (Important!).
5. In the **Secrets** text box, add your ngrok URL like this:
   ```toml
   N8N_BASE_URL = "https://YOUR-NGROK-URL.ngrok-free.app"
   ```
   *(The code will automatically append `/webhook` if you forget it)*
6. Click **Save** and then **Deploy**.

Wait a minute for the app to build. Your AI Agent UI is now live on the cloud!

---

## 🔄 How to update the URL when ngrok restarts

Because the free version of ngrok changes your URL every time you restart your computer or the ngrok terminal, you will need to update Streamlit Cloud when this happens:

1. Start ngrok again: `ngrok http 5678`
2. Copy the **new** HTTPS URL.
3. Go to your Streamlit Cloud Dashboard.
4. Click the **⋮ (three dots)** menu next to your app and select **Settings**.
5. Go to the **Secrets** tab.
6. Update the `N8N_BASE_URL` with your new ngrok URL.
7. Click **Save** (the app will automatically reboot and apply the new URL).

### 💡 Pro Tip: Is your App not responding?
Check the sidebar in your Streamlit App. It will show the exact `Full API URL` it is trying to reach. Ensure this matches the `Forwarding` URL shown in your current ngrok terminal!
