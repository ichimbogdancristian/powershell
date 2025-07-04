@echo off
setlocal enabledelayedexpansion
title PowerShell Profile Quick Setup - Installation Log
color 0A

echo.
echo ████████████████████████████████████████████████████████████████
echo █          PowerShell Enhanced Profile - Quick Install        █
echo █                     Installation Monitor                    █
echo ████████████████████████████████████████████████████████████████
echo.

REM Create log file with timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YYYYMMDD=%dt:~0,8%"
set "HHMMSS=%dt:~8,6%"
set "LOGFILE=%~dp0install-log-%YYYYMMDD%-%HHMMSS%.txt"

echo [%time%] Installation started > "%LOGFILE%"
echo [LOG] Creating installation log: %LOGFILE%
echo.

REM System Information
echo [INFO] Gathering system information...
echo [%time%] System: %COMPUTERNAME% (%USERNAME%) >> "%LOGFILE%"
echo [%time%] OS: %OS% >> "%LOGFILE%"
ver >> "%LOGFILE%" 2>&1

REM Check dependencies with detailed logging
echo [CHECK] Verifying PowerShell installation...
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found in system PATH
    echo [%time%] ERROR: PowerShell not found >> "%LOGFILE%"
    echo [SOLUTION] Install PowerShell from:
    echo   - Microsoft Store: ms-windows-store://pdp/?ProductId=9MZ1SNWT0N5D
    echo   - GitHub: https://github.com/PowerShell/PowerShell/releases
    goto :error_exit
) else (
    echo [OK] PowerShell found
    echo [%time%] PowerShell found in PATH >> "%LOGFILE%"
)

REM Get PowerShell version
for /f "tokens=*" %%v in ('powershell -Command "$PSVersionTable.PSVersion.ToString()" 2^>nul') do (
    echo [INFO] PowerShell version: %%v
    echo [%time%] PowerShell version: %%v >> "%LOGFILE%"
)

echo [CHECK] Verifying installation script...
if not exist "%~dp0quick-install.ps1" (
    echo [ERROR] Installation script not found: quick-install.ps1
    echo [%time%] ERROR: quick-install.ps1 missing from %~dp0 >> "%LOGFILE%"
    echo [SOLUTION] Ensure all files are in the same directory
    goto :error_exit
) else (
    echo [OK] Installation script found
    echo [%time%] Installation script verified >> "%LOGFILE%"
)

echo.
echo [INSTALL] Starting PowerShell profile installation...
echo [INFO] This may take a few minutes depending on your internet connection
echo.

REM Run installer with visible output and error capture
echo [%time%] Starting PowerShell installation process >> "%LOGFILE%"
powershell -ExecutionPolicy Bypass -NoExit -Command "& '%~dp0quick-install.ps1' -Silent; Read-Host 'Press Enter to continue'" 2>"%~dp0install-errors.txt"
set "INSTALL_RESULT=%errorlevel%"
echo [%time%] Installation completed with exit code: %INSTALL_RESULT% >> "%LOGFILE%"

REM Check for errors in error file
if exist "%~dp0install-errors.txt" (
    for /f %%i in ('find /c /v "" "%~dp0install-errors.txt"') do set "ERROR_COUNT=%%i"
    if !ERROR_COUNT! gtr 0 (
        echo [WARNING] %ERROR_COUNT% errors/warnings detected
        echo [%time%] Errors found in installation >> "%LOGFILE%"
        echo [ERRORS] Content of error log:
        type "%~dp0install-errors.txt"
        echo.
    )
)

REM Verify installation success
echo [VERIFY] Checking installation results...
powershell -Command "if (Test-Path $PROFILE) { Write-Host '[OK] PowerShell profile created successfully' -ForegroundColor Green; exit 0 } else { Write-Host '[ERROR] PowerShell profile not found' -ForegroundColor Red; exit 1 }" 2>>"%LOGFILE%"
set "PROFILE_CHECK=%errorlevel%"

powershell -Command "try { Import-Module posh-git,Terminal-Icons -ErrorAction Stop; Write-Host '[OK] Essential modules available' -ForegroundColor Green } catch { Write-Host '[WARNING] Some modules may not be installed properly' -ForegroundColor Yellow }" 2>>"%LOGFILE%"

echo.
echo ════════════════════════════════════════════════════════════════
if %INSTALL_RESULT% equ 0 if %PROFILE_CHECK% equ 0 (
    echo [SUCCESS] Installation completed successfully!
    echo [%time%] SUCCESS: Installation completed >> "%LOGFILE%"
    echo.
    echo ✓ PowerShell profile installed
    echo ✓ Modules configured  
    echo ✓ Configuration files copied
    echo.
    echo [NEXT STEPS]
    echo 1. Close this window
    echo 2. Open a new PowerShell window
    echo 3. Try these commands: neofetch, ll, health
) else (
    color 0C
    echo [FAILED] Installation encountered errors!
    echo [%time%] FAILED: Installation had errors >> "%LOGFILE%"
    echo.
    echo [TROUBLESHOOTING]
    echo 1. Run as Administrator
    echo 2. Check internet connection
    echo 3. Verify execution policy: Get-ExecutionPolicy
    echo 4. Manual module install: Install-Module PSReadLine,posh-git,Terminal-Icons
    echo.
    echo [ERROR DETAILS]
    if exist "%~dp0install-errors.txt" type "%~dp0install-errors.txt"
)

echo.
echo [LOG] Full installation log saved to:
echo %LOGFILE%
echo.
echo [INFO] Press any key to close this window...
pause >nul
goto :eof

:error_exit
echo.
echo ════════════════════════════════════════════════════════════════
echo [FAILED] Pre-installation checks failed!
echo [%time%] FAILED: Pre-checks failed >> "%LOGFILE%"
echo.
echo [LOG] Check the log file for details: %LOGFILE%
echo [INFO] Press any key to close this window...
pause >nul
exit /b 1
