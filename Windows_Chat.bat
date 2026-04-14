@echo off
setlocal enabledelayedexpansion

:: ═══════════════════════════════════════════════════════════════════════════
::  Chat Server Launcher  —  double-click to start & open browser
:: ═══════════════════════════════════════════════════════════════════════════

set "SERVE_DIR=%~dp0brian\n8n"
set PORT=8080
set URL=http://localhost:%PORT%/chat.html

:: ── 1. Check the folder exists ─────────────────────────────────────────────
if not exist "%SERVE_DIR%\" (
    echo.
    echo  ERROR: Folder not found:
    echo    %SERVE_DIR%
    echo.
    echo  Edit SERVE_DIR in this file to point to your chat.html folder.
    pause
    exit /b 1
)

:: ── 2. Check Python is available ───────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Python not found on PATH.
    echo  Install Python from https://python.org and tick "Add to PATH".
    pause
    exit /b 1
)

:: ── 3. Free port %PORT% if already in use ──────────────────────────────────
for /f "tokens=5" %%P in (
    'netstat -ano ^| findstr ":%PORT%" ^| findstr "LISTENING"'
) do (
    echo  Port %PORT% in use ^(PID %%P^) — stopping it...
    taskkill /f /pid %%P >nul 2>&1
)

:: ── 4. Start server ────────────────────────────────────────────────────────
::  KEY FIX: use  start /d "dir"  instead of nesting cd inside the command.
::  This avoids the broken-quotes problem when the path contains spaces.
echo  Starting server at %URL% ...
start "Chat HTTP Server" /min /d "%SERVE_DIR%" cmd /c "python -m http.server %PORT%"

:: ── 5. Wait until port is actually listening (up to 10 s) ──────────────────
set /a TRIES=0
:WAIT_LOOP
    timeout /t 1 /nobreak >nul
    netstat -ano | findstr ":%PORT%" | findstr "LISTENING" >nul 2>&1
    if not errorlevel 1 goto READY
    set /a TRIES+=1
    if %TRIES% lss 10 goto WAIT_LOOP
    echo  WARNING: Server did not respond in 10 s — opening browser anyway.

:READY
:: ── 6. Open browser ────────────────────────────────────────────────────────
start "" "%URL%"

:: ── 7. Launcher window closes itself ───────────────────────────────────────
echo  Done. To stop the server, close the minimised "Chat HTTP Server" window.
timeout /t 3 /nobreak >nul
exit /b 0
