@echo off
setlocal

echo.
echo Checking WSL2...

wsl echo "ok" >nul 2>&1
if errorlevel 1 (
    echo WSL2 is not available or no Linux distribution is installed.
    echo.
    echo Before running this script, complete these steps manually:
    echo   1. Open PowerShell as Administrator
    echo   2. Run: wsl --install
    echo   3. Restart Windows when prompted
    echo   4. Open the Ubuntu app once, set a username/password, then close it
    echo   5. Re-run this script
    echo.
    pause
    exit /b 1
)
echo [ok]  WSL2 available
echo.

for /f "delims=" %%i in ('wsl wslpath "%~dp0"') do set WSL_DIR=%%i
wsl sed -i "s/\r//" "%WSL_DIR%setup-server-linux.sh" >nul 2>&1
wsl bash "%WSL_DIR%setup-server-linux.sh"
if errorlevel 1 (
    echo.
    echo Setup did not complete successfully. Check the errors above.
)
pause
