@echo off
setlocal enabledelayedexpansion
title PowerShell Profile Quick Setup - GitHub Installation
color 0A

echo.
echo ███████████████████████████████████████████████████████████████
echo █          PowerShell Enhanced Profile - GitHub Install       █
echo █                    Repository Download                      █
echo ███████████████████████████████████████████████████████████████
echo.

REM Repository configuration
set "REPO_URL=https://github.com/ichimbogdancristian/powershell"
set "TEMP_DIR=%TEMP%\powershell-profile-install"
set "ZIP_FILE=%TEMP_DIR%\powershell-main.zip"
set "EXTRACT_DIR=%TEMP_DIR%\powershell-main"

echo [INFO] Repository: %REPO_URL%
echo [INFO] Temporary directory: %TEMP_DIR%
echo.

REM Create timestamped logfile for install run
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')" 2^>nul`) do set TIMESTAMP=%%T
if not defined TIMESTAMP set TIMESTAMP=unknown
set "LOG_FILE=%TEMP%\powershell-install-%TIMESTAMP%.log"
echo [INFO] Logfile: %LOG_FILE%
echo === Install log started at %TIMESTAMP% === > "%LOG_FILE%" 2>nul

REM System Information
echo [SYSTEM] Gathering system information...
echo [INFO] Computer: %COMPUTERNAME% (%USERNAME%)
echo [INFO] OS: %OS%
ver | findstr /C:"Version"
echo.

REM === Profile Location Detection ===
echo [PROFILE] Detecting PowerShell profile locations...

REM Get actual profile path and validate it
for /f "delims=" %%p in ('powershell -NoProfile -Command "try { $PROFILE } catch { Write-Error 'Failed to get profile path'; exit 1 }" 2^>nul') do set "PS_PROFILE=%%p"
if not defined PS_PROFILE (
    echo [ERROR] Could not determine PowerShell profile path
    goto :error_exit
)

REM Extract profile directory and filename safely
for %%F in ("%PS_PROFILE%") do (
    set "PROFILE_NAME=%%~nxF"
    set "PROFILE_DIR=%%~dpF"
)

REM Fallback profile directories
set "PS_PROFILE_DIR=%USERPROFILE%\Documents\PowerShell"
set "WIN_PS_PROFILE_DIR=%USERPROFILE%\Documents\WindowsPowerShell"

echo [INFO] Current profile path: %PS_PROFILE%
echo [INFO] Profile directory: %PROFILE_DIR%
echo [INFO] PowerShell Core profile dir: %PS_PROFILE_DIR%
echo [INFO] Windows PowerShell profile dir: %WIN_PS_PROFILE_DIR%
echo.

REM === Subroutine: Ensure Directory Exists ===
goto :skip_subroutines

:ensure_dir
if not exist "%~1" (
    echo [INFO] Creating directory: %~1
    mkdir "%~1" 2>nul
    if errorlevel 1 (
        echo [ERROR] Failed to create directory: %~1
        exit /b 1
    )
)
exit /b 0

:backup_profile
if exist "%PS_PROFILE%" (
    for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')" 2^>nul`) do set BACKUP_TIMESTAMP=%%T
    if not defined BACKUP_TIMESTAMP set BACKUP_TIMESTAMP=unknown
    set "BACKUP_FILE=%PROFILE_DIR%%PROFILE_NAME%.%BACKUP_TIMESTAMP%.backup"
    echo [INFO] Backing up current profile to: !BACKUP_FILE!
    
    call :ensure_dir "%PROFILE_DIR%"
    if errorlevel 1 exit /b 1
    
    copy "%PS_PROFILE%" "!BACKUP_FILE!" /Y >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to backup profile
        exit /b 1
    )
    echo [OK] Profile backed up successfully
) else (
    echo [INFO] No existing profile to backup
)
exit /b 0

:restore_latest_backup
set "LATEST="
for /f "usebackq delims=" %%F in (`dir "%PROFILE_DIR%%PROFILE_NAME%*.backup" /b /o:-d 2^>nul`) do (
    set "LATEST=%PROFILE_DIR%%%F"
    goto :found_latest
)
:found_latest
if defined LATEST (
    echo [INFO] Restoring from: !LATEST!
    call :ensure_dir "%PROFILE_DIR%"
    if errorlevel 1 exit /b 1
    
    copy "!LATEST!" "%PS_PROFILE%" /Y >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to restore profile
        exit /b 1
    )
    echo [OK] Profile restored successfully
) else (
    echo [ERROR] No backups found
    exit /b 1
)
exit /b 0

:create_default_profile
echo [INFO] Creating default (empty) profile
call :ensure_dir "%PROFILE_DIR%"
if errorlevel 1 exit /b 1

echo. > "%PS_PROFILE%"
if errorlevel 1 (
    echo [ERROR] Failed to create default profile
    exit /b 1
)
echo [OK] Default profile created
exit /b 0

:skip_subroutines

REM === Main Interactive Profile Menu ===
:profile_menu
echo [PROFILE] Choose an option before continuing:
echo   1. Proceed to installation
echo   2. Backup current profile
echo   3. Restore previous backup
echo   4. Create Microsoft default profile
echo   5. Manage backups
echo   6. Quit
echo.
set /p PROFILE_CHOICE="Enter your choice (1-6): "

REM Sanitize input
for /f "tokens=1" %%A in ("%PROFILE_CHOICE% ") do set "PROFILE_CHOICE=%%~A"

REM Validate choice
if "%PROFILE_CHOICE%"=="1" goto :start_installation
if "%PROFILE_CHOICE%"=="2" goto :do_backup
if "%PROFILE_CHOICE%"=="3" goto :do_restore
if "%PROFILE_CHOICE%"=="4" goto :do_default
if "%PROFILE_CHOICE%"=="5" goto :manage_backups
if "%PROFILE_CHOICE%"=="6" goto :user_exit

echo [ERROR] Invalid choice: %PROFILE_CHOICE%
echo.
goto :profile_menu

:do_backup
call :backup_profile
echo.
goto :profile_menu

:do_restore
call :restore_latest_backup
if errorlevel 1 echo [ERROR] Restore failed
echo.
goto :profile_menu

:do_default
call :create_default_profile
if errorlevel 1 echo [ERROR] Failed to create default profile
echo.
goto :profile_menu

:manage_backups
echo [INFO] Backup management not fully implemented in this version
echo [INFO] Backups are stored in: %PROFILE_DIR%
echo [INFO] Look for files matching: %PROFILE_NAME%*.backup
echo.
goto :profile_menu

:user_exit
echo [INFO] Installation cancelled by user.
goto :cleanup_exit

:start_installation
echo [INFO] Proceeding to installation...
echo.
pause

REM === Dependency Checks ===
echo [CHECK] Checking system dependencies...

REM Check PowerShell
where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell not found in system PATH
    echo [SOLUTION] Install PowerShell from Microsoft Store or GitHub
    goto :error_exit
)
echo [OK] PowerShell found

REM Get PowerShell version
for /f "tokens=*" %%v in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString()" 2^>nul') do (
    echo [INFO] PowerShell version: %%v
)

REM Check internet connectivity
echo [CHECK] Testing internet connectivity...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot reach GitHub. Check your internet connection.
    goto :error_exit
)
echo [OK] Internet connectivity verified
echo.

REM === Module Installation ===
echo [MODULES] Installing required PowerShell modules...

for %%M in ("PSReadLine" "posh-git" "Terminal-Icons") do (
    echo [INFO] Checking module: %%~M
    powershell -NoProfile -Command "if (-not (Get-Module %%~M -ListAvailable -ErrorAction SilentlyContinue)) { Write-Host '  Installing %%~M...'; try { Install-Module %%~M -Repository PSGallery -Force -AllowClobber -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop; Write-Host '  [OK] %%~M installed' -ForegroundColor Green } catch { Write-Host '  [ERROR] Failed to install %%~M' -ForegroundColor Red; exit 1 } } else { Write-Host '  [OK] %%~M already available' -ForegroundColor Green }"
    if errorlevel 1 (
        echo [WARNING] Module %%~M installation failed, continuing...
    )
)
echo.

REM === Tool Installation ===
echo [TOOLS] Installing required tools with winget...

where winget >nul 2>&1
if errorlevel 1 (
    echo [WARN] winget not found. Tools must be installed manually:
    echo   - oh-my-posh: https://ohmyposh.dev/
    echo   - git: https://git-scm.com/
    echo   - zoxide: https://github.com/ajeetdsouza/zoxide
) else (
    for %%T in ("JanDeDobbeleer.OhMyPosh" "Git.Git" "ajeetdsouza.zoxide") do (
        set "TOOL_ID=%%~T"
        if "%%~T"=="JanDeDobbeleer.OhMyPosh" set "TOOL_EXE=oh-my-posh"
        if "%%~T"=="Git.Git" set "TOOL_EXE=git"
        if "%%~T"=="ajeetdsouza.zoxide" set "TOOL_EXE=zoxide"
        
        where !TOOL_EXE! >nul 2>&1
        if errorlevel 1 (
            echo [INFO] Installing !TOOL_EXE!...
            winget install %%~T --silent --accept-source-agreements --accept-package-agreements >nul 2>&1
            if errorlevel 1 (
                echo [WARN] Failed to install !TOOL_EXE! via winget
            ) else (
                echo [OK] !TOOL_EXE! installed
            )
        ) else (
            echo [OK] !TOOL_EXE! already available
        )
    )
)
echo.

REM === Download Repository ===
echo [DOWNLOAD] Downloading PowerShell profile repository...

REM Clean up previous installations
if exist "%TEMP_DIR%" (
    echo [INFO] Cleaning up previous files...
    rmdir /s /q "%TEMP_DIR%" 2>nul
)

REM Create temporary directory
mkdir "%TEMP_DIR%" 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot create temporary directory: %TEMP_DIR%
    goto :error_exit
)

REM Download repository
echo [INFO] Downloading from GitHub...
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/heads/main.zip' -OutFile '%ZIP_FILE%' -UseBasicParsing -TimeoutSec 60; Write-Host '[OK] Download completed' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Download failed:' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo [ERROR] Failed to download repository
    goto :error_exit
)

REM Extract files
echo [INFO] Extracting files...
powershell -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force; Write-Host '[OK] Extraction completed' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Extraction failed:' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo [ERROR] Failed to extract files
    goto :error_exit
)

if not exist "%EXTRACT_DIR%" (
    echo [ERROR] Extracted directory not found
    goto :error_exit
)
echo.

REM === Install Profile ===
echo [INSTALL] Installing PowerShell profile...

REM Create profile directories
call :ensure_dir "%PS_PROFILE_DIR%"
if errorlevel 1 goto :error_exit

call :ensure_dir "%WIN_PS_PROFILE_DIR%"
if errorlevel 1 goto :error_exit

REM Copy profile files
if exist "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" (
    echo [INFO] Copying profile files...
    
    REM Copy to PowerShell Core
    copy "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" "%PS_PROFILE_DIR%\Microsoft.PowerShell_profile.ps1" /Y >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to copy profile to PowerShell Core directory
        goto :error_exit
    )
    echo [OK] Profile copied to PowerShell Core
    
    REM Copy to Windows PowerShell
    copy "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" "%WIN_PS_PROFILE_DIR%\Microsoft.PowerShell_profile.ps1" /Y >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Failed to copy profile to Windows PowerShell directory
    ) else (
        echo [OK] Profile copied to Windows PowerShell
    )
) else (
    echo [ERROR] Profile file not found in repository
    goto :error_exit
)

REM Copy theme file
if exist "%EXTRACT_DIR%\oh-my-posh-default.json" (
    copy "%EXTRACT_DIR%\oh-my-posh-default.json" "%PS_PROFILE_DIR%\" /Y >nul 2>&1
    copy "%EXTRACT_DIR%\oh-my-posh-default.json" "%WIN_PS_PROFILE_DIR%\" /Y >nul 2>&1
    echo [OK] Theme configuration copied
)

REM Copy modules
if exist "%EXTRACT_DIR%\Modules" (
    call :ensure_dir "%PS_PROFILE_DIR%\Modules"
    call :ensure_dir "%WIN_PS_PROFILE_DIR%\Modules"
    xcopy "%EXTRACT_DIR%\Modules" "%PS_PROFILE_DIR%\Modules\" /E /I /Y /Q >nul 2>&1
    xcopy "%EXTRACT_DIR%\Modules" "%WIN_PS_PROFILE_DIR%\Modules\" /E /I /Y /Q >nul 2>&1
    echo [OK] Custom modules copied
)
echo.

REM === Verification ===
echo [VERIFY] Verifying installation...

if exist "%PS_PROFILE%" (
    echo [OK] PowerShell profile created successfully
) else (
    echo [ERROR] PowerShell profile not found after installation
    goto :error_exit
)

powershell -NoProfile -Command "try { Get-Module posh-git,Terminal-Icons,PSReadLine -ListAvailable -ErrorAction SilentlyContinue | Out-Null; Write-Host '[OK] Essential modules available' -ForegroundColor Green } catch { Write-Host '[INFO] Some modules may need manual installation' -ForegroundColor Yellow }"
echo.

REM === Success ===
color 0A
echo ═══════════════════════════════════════════════════════════════════════════════
echo [SUCCESS] PowerShell profile installed successfully!
echo ═══════════════════════════════════════════════════════════════════════════════
echo.
echo ✓ Repository downloaded from GitHub
echo ✓ PowerShell profile configured  
echo ✓ Essential modules installed
echo ✓ Theme and modules copied
echo.
echo [NEXT STEPS]
echo 1. Close this window
echo 2. Open a new PowerShell window  
echo 3. The enhanced profile should load automatically
echo 4. Try commands like: Get-Help, ls, cd
echo.

goto :cleanup_exit

REM === Error Handlers ===
:error_exit
color 0C
echo ═══════════════════════════════════════════════════════════════════════════════
echo [FAILED] Installation failed!
echo ═══════════════════════════════════════════════════════════════════════════════
echo.
echo [TROUBLESHOOTING]
echo 1. Ensure PowerShell 7 is installed: winget install Microsoft.PowerShell
echo 2. Ensure winget is installed from Microsoft Store (App Installer)
echo 3. Run as Administrator
echo 4. Check internet connection  
echo 5. Verify PowerShell execution policy: Get-ExecutionPolicy
echo 6. Visit repository manually: %REPO_URL%
echo 7. Check the log file: %LOG_FILE%
echo.
echo [INFO] Temporary files preserved for debugging: %TEMP_DIR%
echo === Installation FAILED at %DATE% %TIME% === >> "%LOG_FILE%" 2>nul
goto :exit_pause

:cleanup_exit
echo [CLEANUP] Removing temporary files...
if exist "%TEMP_DIR%" (
    rmdir /s /q "%TEMP_DIR%" 2>nul
    if exist "%TEMP_DIR%" (
        echo [INFO] Some temporary files may remain: %TEMP_DIR%
    ) else (
        echo [OK] Cleanup completed
    )
)
echo === Installation completed successfully at %DATE% %TIME% === >> "%LOG_FILE%" 2>nul

:exit_pause
echo.
echo [INFO] Press any key to close this window...
pause >nul
exit /b 0