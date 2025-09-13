@echo off
setlocal enabledelayedexpansion
title PowerShell Profile Clean Install
color 0A

REM ═══════════════════════════════════════════════════════════════════════════════
REM Clean Installation - No Profile Loading
REM ═══════════════════════════════════════════════════════════════════════════════

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo                PowerShell Enhanced Profile - Clean Install
echo ═══════════════════════════════════════════════════════════════════════════════
echo.

set "REPO_URL=https://github.com/ichimbogdancristian/powershell"
set "TEMP_DIR=%TEMP%\powershell-clean-install"

echo [INFO] Clean installation mode - bypassing all profile conflicts
echo [INFO] Downloading from: %REPO_URL%
echo.

REM Clean and create temp directory
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
mkdir "%TEMP_DIR%" 2>nul

echo [DOWNLOAD] Downloading repository...
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "& {$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\repo.zip' -UseBasicParsing; Write-Host '[OK] Downloaded' -ForegroundColor Green } catch { Write-Host '[ERROR] Download failed' -ForegroundColor Red; exit 1 }}"

if %errorlevel% neq 0 goto :error_exit

echo [EXTRACT] Extracting files...
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "& {$ProgressPreference='SilentlyContinue'; try { Expand-Archive '%TEMP_DIR%\repo.zip' '%TEMP_DIR%' -Force; Write-Host '[OK] Extracted' -ForegroundColor Green } catch { Write-Host '[ERROR] Extract failed' -ForegroundColor Red; exit 1 }}"

if %errorlevel% neq 0 goto :error_exit

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo [INSTALL] Running clean installation...

cd /d "%TEMP_DIR%\powershell-main"
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "quick-install.ps1"
set "INSTALL_RESULT=%errorlevel%"

echo ═══════════════════════════════════════════════════════════════════════════════

if %INSTALL_RESULT% equ 0 (
    color 0A
    echo [SUCCESS] Installation completed successfully!
    echo.
    echo [OK] PowerShell profile configured
    echo [OK] Modules and tools installed  
    echo [OK] Theme configured
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
echo Press any key to close...
pause >nul
exit /b 1