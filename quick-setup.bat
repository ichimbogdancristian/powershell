@echo off
setlocal enabledelayedexpansion
title PowerShell Profile Quick Setup
color 0A

REM ═══════════════════════════════════════════════════════════════════════════════
REM Check for Administrator Privileges
REM ═══════════════════════════════════════════════════════════════════════════════
openfiles >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Administrator privileges required. Re-launching...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo                PowerShell Enhanced Profile - Quick Setup
echo ═══════════════════════════════════════════════════════════════════════════════
echo.

set "REPO_URL=https://github.com/ichimbogdancristian/powershell"
set "TEMP_DIR=%TEMP%\powershell-profile-install"

echo [INFO] Downloading from: %REPO_URL%
echo [INFO] Computer: %COMPUTERNAME% (%USERNAME%)
echo.

REM Check PowerShell availability
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found
    echo [SOLUTION] Install PowerShell from Microsoft Store or GitHub
    goto :error_exit
)

REM Test internet connectivity
ping -n 1 github.com >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Cannot reach GitHub. Check internet connection.
    goto :error_exit
)
echo [OK] System checks passed

REM Clean and create temp directory
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
mkdir "%TEMP_DIR%" 2>nul

echo.
echo [DOWNLOAD] Downloading repository...
powershell -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\repo.zip' -UseBasicParsing; Write-Host '[OK] Downloaded' -ForegroundColor Green } catch { Write-Host '[ERROR] Download failed' -ForegroundColor Red; exit 1 }"

if %errorlevel% neq 0 goto :error_exit

echo [EXTRACT] Extracting files...
powershell -Command "$ProgressPreference='SilentlyContinue'; try { Expand-Archive '%TEMP_DIR%\repo.zip' '%TEMP_DIR%' -Force; Write-Host '[OK] Extracted' -ForegroundColor Green } catch { Write-Host '[ERROR] Extract failed' -ForegroundColor Red; exit 1 }"

if %errorlevel% neq 0 goto :error_exit

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo [INSTALL] Running installation...

cd /d "%TEMP_DIR%\powershell-main"
powershell -NoProfile -ExecutionPolicy Bypass -File "quick-install.ps1"
set "INSTALL_RESULT=%errorlevel%"

echo ═══════════════════════════════════════════════════════════════════════════════

if %INSTALL_RESULT% equ 0 (
    color 0A
    echo [SUCCESS] Installation completed successfully!
    echo.
    echo ✓ PowerShell profile configured
    echo ✓ Modules and tools installed  
    echo ✓ Theme configured
    echo.
    echo [NEXT] Close this window and open a new PowerShell
    echo [TRY] Commands: ll, health, help-profile
    echo.
) else (
    color 0C
    echo [FAILED] Installation encountered errors
    echo.
    echo [TROUBLESHOOTING]
    echo 1. Run as Administrator
    echo 2. Check internet connection  
    echo 3. Visit: %REPO_URL%
    echo.
)

echo [CLEANUP] Removing temporary files...
cd /d "%~dp0"
rmdir /s /q "%TEMP_DIR%" 2>nul

echo Press any key to close...
pause >nul
goto :eof

:error_exit
color 0C
echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo [FAILED] Setup failed - check requirements
echo ═══════════════════════════════════════════════════════════════════════════════
echo.
echo [REQUIREMENTS]
echo 1. Internet connection
echo 2. PowerShell installed
echo 3. Administrator rights (recommended)
echo.
echo Press any key to close...
pause >nul
exit /b 1