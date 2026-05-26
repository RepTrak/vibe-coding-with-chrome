@echo off
setlocal

wsl echo "ok" >nul 2>&1
if errorlevel 1 (
    echo WSL2 is not available.
    pause
    exit /b 1
)

echo Stopping vibe server...

wsl bash -c "pkill -f vibe-server-start.py 2>/dev/null && echo '  [ok]  vibe-server-start.py stopped' || echo '  [--]  vibe-server-start.py was not running'"
wsl bash -c "pkill -f ttyd 2>/dev/null && echo '  [ok]  ttyd stopped' || echo '  [--]  ttyd was not running'"

echo.
echo Done. Run clear-server-session-windows.bat if you also want to clear the tmux session.
pause
