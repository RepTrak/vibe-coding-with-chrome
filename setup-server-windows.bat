@echo off
setlocal

echo.
echo Checking WSL2...

wsl echo "ok" >nul 2>&1
if errorlevel 1 (
    echo WSL2 is not available or no distribution is installed.
    echo.
    echo To install WSL2 with Ubuntu, run in PowerShell as Administrator:
    echo   wsl --install
    echo   ^(then restart Windows and re-run this script^)
    echo.
    pause
    exit /b 1
)
echo [ok]  WSL2 available
echo.

for /f "delims=" %%i in ('wsl wslpath "%~dp0"') do set WSL_DIR=%%i
wsl bash "%WSL_DIR%setup-server-linux.sh"
pause
