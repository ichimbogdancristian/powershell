@echo off
title PowerShell Profile Quick Setup

echo PowerShell Enhanced Profile - Quick Install
echo ===========================================

REM Check dependencies
where powershell >nul 2>nul || (echo ERROR: PowerShell not found & exit /b 1)
if not exist "%~dp0quick-install.ps1" (echo ERROR: quick-install.ps1 not found & exit /b 1)

echo Installing... Please wait...

REM Run silent installer
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0quick-install.ps1" -Silent

REM Show result
if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: PowerShell profile installed!
    echo Restart PowerShell and try: neofetch, ll, health
) else (
    echo.
    echo WARNING: Installation may have issues
    echo Try running as Administrator
)

echo.
echo Auto-closing in 3 seconds...
timeout /t 3 /nobreak >nul
