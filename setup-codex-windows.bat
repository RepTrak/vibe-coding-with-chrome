@echo off
setlocal

wsl echo "ok" >nul 2>&1
if errorlevel 1 (
    echo WSL2 is not available. Run setup-server-windows.bat first.
    pause
    exit /b 1
)

for /f "delims=" %%i in ('wsl wslpath "%~dp0"') do set WSL_DIR=%%i
wsl bash "%WSL_DIR%setup-codex-linux.sh"
if errorlevel 1 (
    echo.
    echo Setup did not complete successfully. Check the errors above.
)
pause
