@echo off
setlocal

wsl echo "ok" >nul 2>&1
if errorlevel 1 (
    echo WSL2 is not available. Run setup-server-windows.bat first.
    pause
    exit /b 1
)

for /f "delims=" %%i in ('wsl bash -c "wslpath '%~dp0' | tr -d '\r'"') do set WSL_DIR=%%i
wsl sed -i "s/\r//" "%WSL_DIR%start-codex-server-linux.sh" >nul 2>&1
wsl bash "%WSL_DIR%start-codex-server-linux.sh"
pause
