@echo off
setlocal EnableDelayedExpansion

echo ========================================
echo PowerShell Enhanced Profile Setup
echo Execution Policy Bypass Installer
echo ========================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found in PATH
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

echo Checking current directory...
if not exist "%~dp0install.ps1" (
    echo ERROR: install.ps1 not found in current directory
    echo Please ensure you're running this from the correct folder
    pause
    exit /b 1
)

echo.
echo This will install the PowerShell Enhanced Profile with:
echo - Linux-like aliases and commands
echo - Oh My Posh theme customization
echo - Enhanced autocompletion and history
echo - System monitoring functions
echo - Git integration
echo.

set /p CONFIRM="Do you want to continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Installation cancelled.
    pause
    exit /b 0
)

echo.
echo Starting installation with execution policy bypass...
echo This temporarily bypasses PowerShell execution restrictions.
echo.

REM Run the installer with execution policy bypass
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

REM Check if installation was successful
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Installation completed successfully!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Close this window
    echo 2. Open a new PowerShell window
    echo 3. Try commands like: neofetch, ll, health
    echo.
    echo The profile will be automatically loaded in new sessions.
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Installation failed with error code: %errorlevel%
    echo ========================================
    echo.
    echo Troubleshooting steps:
    echo 1. Run PowerShell as Administrator
    echo 2. Manually set execution policy:
    echo    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo 3. Try running: PowerShell -ExecutionPolicy Bypass -File install.ps1
    echo 4. Check if all files are present in the current directory
    echo ========================================
)

echo.
echo Press any key to exit...
pause >nul
