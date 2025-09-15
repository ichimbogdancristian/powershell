@echo off
setlocal enabledelayedexpansion
title PowerShell Profile Quick Setup - GitHub Installation
color 0A

echo.
echo ████████████████████████████████████████████████████████████████
echo █          PowerShell Enhanced Profile - GitHub Install       █
echo █                    Repository Download                      █
echo ████████████████████████████████████████████████████████████████
echo.

REM Repository configuration
set "REPO_URL=https://github.com/ichimbogdancristian/powershell"
set "TEMP_DIR=%TEMP%\powershell-profile-install"
set "ZIP_FILE=%TEMP_DIR%\powershell-main.zip"
set "EXTRACT_DIR=%TEMP_DIR%\powershell-main"

echo [INFO] Repository: %REPO_URL%
echo [INFO] Temporary directory: %TEMP_DIR%
echo.

rem --- create timestamped logfile for install run ---
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

REM === Profile Management (interactive loop below) ===

:profile_menu
echo [PROFILE] Choose an option before continuing:
echo   1. Proceed to installation
echo   2. Backup current profile
echo   3. Restore previous backup
echo   4. Restore Microsoft default profile
echo   5. Manage backups (list/delete)
echo   6. Quit
set /p PROFILE_CHOICE="Enter your choice (1-6): "

rem sanitize input: take first token so '1 anything' becomes '1'
for /f "tokens=1" %%A in ("%PROFILE_CHOICE% ") do set "PROFILE_CHOICE=%%~A"

echo [DEBUG] PROFILE_CHOICE=%PROFILE_CHOICE%
echo [DEBUG] PROFILE_CHOICE=%PROFILE_CHOICE% >> "%LOG_FILE%" 2>nul

rem validate numeric choice (1-6)
if "%PROFILE_CHOICE%"=="1" goto _valid_choice
if "%PROFILE_CHOICE%"=="2" goto _valid_choice
if "%PROFILE_CHOICE%"=="3" goto _valid_choice
if "%PROFILE_CHOICE%"=="4" goto _valid_choice
if "%PROFILE_CHOICE%"=="5" goto _valid_choice
if "%PROFILE_CHOICE%"=="6" goto _valid_choice

echo [ERROR] Invalid choice: %PROFILE_CHOICE%
echo [ERROR] Invalid choice: %PROFILE_CHOICE% >> "%LOG_FILE%" 2>nul
echo.
goto profile_menu

:_valid_choice

if "%PROFILE_CHOICE%"=="2" (
    if exist "%PS_PROFILE%" (
        rem generate timestamp using PowerShell to avoid locale issues
        for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')" 2^>nul`) do set BACKUP_TIMESTAMP=%%T
        if not defined BACKUP_TIMESTAMP set BACKUP_TIMESTAMP=unknown
        set "BACKUP_FILE=%PROFILE_DIR%%PROFILE_NAME%.%BACKUP_TIMESTAMP%.backup"
        echo [INFO] Backing up profile:
        echo   Source: %PS_PROFILE%
        echo   Dest:   !BACKUP_FILE!
        
        REM Ensure profile directory exists
        if not exist "%PROFILE_DIR%" (
            echo [INFO] Creating profile directory: %PROFILE_DIR%
            mkdir "%PROFILE_DIR%" 2>nul
        )
        
        copy "%PS_PROFILE%" "!BACKUP_FILE!" /Y >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Profile backed up to: !BACKUP_FILE!
        ) else (
            echo [ERROR] Failed to copy profile to backup location.
        )
    ) else (
        echo [INFO] No existing profile to backup: %PS_PROFILE%
    )
    echo.
    goto profile_menu
)

if "%PROFILE_CHOICE%"=="3" (
    rem attempt to restore the newest matching backup (by modified date)
    set "LATEST="
    for /f "usebackq delims=" %%F in (`dir "%PROFILE_DIR%%PROFILE_NAME%*.backup" /b /o:-d 2^>nul`) do (
        set "LATEST=%PROFILE_DIR%%%F"
        goto have_latest
    )
    :have_latest
    if defined LATEST (
        echo [INFO] Restoring newest backup:
        echo   Source: !LATEST!
        echo   Dest:   %PS_PROFILE%
        
        REM Ensure profile directory exists
        if not exist "%PROFILE_DIR%" (
            echo [INFO] Creating profile directory: %PROFILE_DIR%
            mkdir "%PROFILE_DIR%" 2>nul
        )
        
        copy "!LATEST!" "%PS_PROFILE%" /Y >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Profile restored from: !LATEST!
        ) else (
            echo [ERROR] Failed to restore profile from: !LATEST!
        )
    ) else (
        echo [ERROR] No backups found matching: %PROFILE_DIR%%PROFILE_NAME%*.backup
    )
    echo.
    goto profile_menu
)

if "%PROFILE_CHOICE%"=="4" (
    echo [INFO] Restoring Microsoft default (empty) profile at: %PS_PROFILE%
    
    REM Ensure profile directory exists
    if not exist "%PROFILE_DIR%" (
        echo [INFO] Creating profile directory: %PROFILE_DIR%
        mkdir "%PROFILE_DIR%" 2>nul
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to create profile directory: %PROFILE_DIR%
            goto profile_menu
        )
    )
    
    powershell -NoProfile -Command "try { Remove-Item -Path '%PS_PROFILE%' -ErrorAction SilentlyContinue; New-Item -Path '%PS_PROFILE%' -ItemType File -Force | Out-Null; exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }" 2>nul
    if !errorlevel! equ 0 (
        echo [OK] Microsoft default profile restored (empty profile).
    ) else (
        echo [ERROR] Failed to create default profile file: %PS_PROFILE%
    )
    echo.
    goto profile_menu
)

if "%PROFILE_CHOICE%"=="5" (
    echo [INFO] Looking for backups matching: %PROFILE_DIR%%PROFILE_NAME%*.backup
    set BK_COUNT=0
    for %%B in ("%PROFILE_DIR%%PROFILE_NAME%*.backup") do (
        if exist "%%~fB" (
            set /a BK_COUNT+=1
            set "BK!BK_COUNT!=%%~fB"
        )
    )
    if !BK_COUNT! equ 0 (
        echo [INFO] No backups found for %PROFILE_NAME%
        echo.
        goto profile_menu
    )
    echo [BACKUPS]
    for /L %%I in (1,1,!BK_COUNT!) do (
        call echo %%I. %%BK%%I%%
    )
    echo.
    set /p ACTION="Enter 'd' to delete, 'r' to restore, 'a' to delete all, or press Enter to return: "
    if "!ACTION!"=="" (
        echo.
        goto profile_menu
    )
    if /i "!ACTION!"=="a" (
        set /p CONFIRM="Are you sure you want to delete ALL backups? (y/n): "
        if /i "!CONFIRM!"=="y" (
            rem move all to DeletedBackups folder
            set "DELETED_DIR=%PROFILE_DIR%DeletedBackups\"
            if not exist "!DELETED_DIR!" (
                echo [INFO] Creating DeletedBackups directory: !DELETED_DIR!
                mkdir "!DELETED_DIR!" 2>nul
            )
            for /L %%I in (1,1,!BK_COUNT!) do (
                call move "%%BK%%I%%" "!DELETED_DIR!" >nul 2>&1
            )
            echo [OK] Moved !BK_COUNT! backups to: !DELETED_DIR!
        ) else (
            echo [INFO] Cancelled.
        )
        echo.
        goto profile_menu
    )
    if /i "!ACTION!"=="d" (
        set /p DEL_CHOICE="Enter number to delete, or press Enter to cancel: "
        if "!DEL_CHOICE!"=="" (
            echo [INFO] Cancelled.
            echo.
            goto profile_menu
        )
        if !DEL_CHOICE! gtr !BK_COUNT! (
            echo [ERROR] Invalid selection.
            echo.
            goto profile_menu
        )
        call set "TARGET=%%BK!DEL_CHOICE!%%"
        if "!TARGET!"=="" (
            echo [ERROR] Invalid selection.
            echo.
            goto profile_menu
        )
        set "DELETED_DIR=%PROFILE_DIR%DeletedBackups\"
        if not exist "!DELETED_DIR!" (
            echo [INFO] Creating DeletedBackups directory: !DELETED_DIR!
            mkdir "!DELETED_DIR!" 2>nul
        )
        set /p CONFIRM="Are you sure you want to move '!TARGET!' to DeletedBackups? (y/n): "
        if /i "!CONFIRM!"=="y" (
            move "!TARGET!" "!DELETED_DIR!" >nul 2>&1
            if !errorlevel! equ 0 (
                echo [OK] Moved to: !DELETED_DIR!
            ) else (
                echo [ERROR] Failed to move: !TARGET!
            )
        ) else (
            echo [INFO] Cancelled.
        )
        echo.
        goto profile_menu
    )
    if /i "!ACTION!"=="r" (
        set /p REST_CHOICE="Enter number to restore, or press Enter to cancel: "
        if "!REST_CHOICE!"=="" (
            echo [INFO] Cancelled.
            echo.
            goto profile_menu
        )
        if !REST_CHOICE! gtr !BK_COUNT! (
            echo [ERROR] Invalid selection.
            echo.
            goto profile_menu
        )
        call set "TARGET=%%BK!REST_CHOICE!%%"
        if "!TARGET!"=="" (
            echo [ERROR] Invalid selection.
            echo.
            goto profile_menu
        )
        set /p CONFIRM="Are you sure you want to restore '!TARGET!' to %PS_PROFILE%? (y/n): "
        if /i "!CONFIRM!"=="y" (
            if not exist "%PROFILE_DIR%" (
                echo [INFO] Creating profile directory: %PROFILE_DIR%
                mkdir "%PROFILE_DIR%" 2>nul
            )
            copy "!TARGET!" "%PS_PROFILE%" /Y >nul 2>&1
            if !errorlevel! equ 0 (
                echo [OK] Restored profile from: !TARGET!
            ) else (
                echo [ERROR] Failed to restore from: !TARGET!
            )
        ) else (
            echo [INFO] Cancelled.
        )
        echo.
        goto profile_menu
    )
    echo [ERROR] Unknown action. Please try again.
    echo.
    goto profile_menu
)

if "%PROFILE_CHOICE%"=="6" (
    echo [INFO] Installation cancelled by user.
    goto :eof
)

if "%PROFILE_CHOICE%"=="1" (
    echo [INFO] Proceeding to installation...
    echo.
    echo [INFO] Press any key to begin installation. If you launched this by double-click, this prevents the window from closing immediately.
    pause
    echo [DEBUG] pause completed, proceeding to :do_install
    echo [DEBUG] pause completed, proceeding to :do_install >> "%LOG_FILE%" 2>nul
    goto do_install
)

:do_install
REM === Dependency and Module Checks ===
echo [CHECK] Checking for existing dependencies and modules...
echo [DEBUG] Entered :do_install label
echo [DEBUG] Entered :do_install label >> "%LOG_FILE%" 2>nul

REM Check PowerShell modules using file-based communication
set "CHECK_FILE=%TEMP%\ps_module_check_%TIMESTAMP%.tmp"

REM Check posh-git
powershell -NoProfile -Command "try { Get-Module posh-git -ListAvailable -ErrorAction Stop | Out-Null; 'POSH_GIT_OK' | Out-File -FilePath '%CHECK_FILE%' -Append -Encoding ASCII; Write-Host '[OK] posh-git module found' -ForegroundColor Green } catch { Write-Host '[INFO] posh-git module not found' -ForegroundColor Yellow }" 2>nul

REM Check Terminal-Icons
powershell -NoProfile -Command "try { Get-Module Terminal-Icons -ListAvailable -ErrorAction Stop | Out-Null; 'TERMINAL_ICONS_OK' | Out-File -FilePath '%CHECK_FILE%' -Append -Encoding ASCII; Write-Host '[OK] Terminal-Icons module found' -ForegroundColor Green } catch { Write-Host '[INFO] Terminal-Icons module not found' -ForegroundColor Yellow }" 2>nul

REM Check PSReadLine
powershell -NoProfile -Command "try { Get-Module PSReadLine -ListAvailable -ErrorAction Stop | Out-Null; 'PSREADLINE_OK' | Out-File -FilePath '%CHECK_FILE%' -Append -Encoding ASCII; Write-Host '[OK] PSReadLine module found' -ForegroundColor Green } catch { Write-Host '[INFO] PSReadLine module not found' -ForegroundColor Yellow }" 2>nul

REM Read results from file
set "MODULES_OK=1"
if exist "%CHECK_FILE%" (
    findstr /C:"POSH_GIT_OK" "%CHECK_FILE%" >nul 2>&1 || set "MODULES_OK=0"
    findstr /C:"TERMINAL_ICONS_OK" "%CHECK_FILE%" >nul 2>&1 || set "MODULES_OK=0"
    findstr /C:"PSREADLINE_OK" "%CHECK_FILE%" >nul 2>&1 || set "MODULES_OK=0"
    del "%CHECK_FILE%" 2>nul
) else (
    set "MODULES_OK=0"
)

REM Check tools
set "TOOLS_OK=1"
where oh-my-posh >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] oh-my-posh tool found
) else (
    echo [INFO] oh-my-posh tool not found
    set "TOOLS_OK=0"
)

where git >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] git tool found
) else (
    echo [INFO] git tool not found
    set "TOOLS_OK=0"
)

where zoxide >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] zoxide tool found
) else (
    echo [INFO] zoxide tool not found
    set "TOOLS_OK=0"
)

if !MODULES_OK! equ 1 if !TOOLS_OK! equ 1 (
    echo [INFO] All dependencies and modules are already installed.
    echo [QUESTION] Do you want to skip installation and just update the profile?
    choice /M "Skip full installation and update profile only" 2>nul
    if !errorlevel! equ 2 (
        echo [INFO] User chose to continue with full install >> "%LOG_FILE%" 2>nul
    ) else (
        echo [INFO] User chose to skip full install and update profile only >> "%LOG_FILE%" 2>nul
        set "SKIP_INSTALL=1"
        goto :skip_install
    )
)
echo.

REM Check dependencies
echo [CHECK] Verifying system dependencies...

REM Check PowerShell
where powershell >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] PowerShell not found in system PATH
    echo [SOLUTION] Install PowerShell from:
    echo   - Microsoft Store: ms-windows-store://pdp/?ProductId=9MZ1SNWT0N5D
    echo   - GitHub: https://github.com/PowerShell/PowerShell/releases
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
if !errorlevel! neq 0 (
    echo [ERROR] Cannot reach GitHub. Check your internet connection.
    goto :error_exit
)
echo [OK] Internet connectivity verified
echo.

echo [DOWNLOAD] Preparing to download repository...

REM Clean up previous installations with better error handling
if exist "%TEMP_DIR%" (
    echo [INFO] Cleaning up previous installation files...
    for /l %%i in (1,1,3) do (
        rmdir /s /q "%TEMP_DIR%" 2>nul
        if not exist "%TEMP_DIR%" goto cleanup_success
        echo [INFO] Cleanup attempt %%i failed, retrying...
        timeout /t 1 /nobreak >nul 2>&1
    )
    echo [WARNING] Could not completely clean previous installation files
    :cleanup_success
)

REM Create temporary directory with error handling
echo [INFO] Creating temporary directory...
mkdir "%TEMP_DIR%" 2>nul
if !errorlevel! neq 0 (
    echo [ERROR] Cannot create temporary directory: %TEMP_DIR%
    goto :error_exit
)
echo [OK] Temporary directory created
echo.

echo [DOWNLOAD] Downloading PowerShell profile repository...
echo [INFO] This may take a moment depending on your connection...

REM Download repository using PowerShell with improved error handling
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/heads/main.zip' -OutFile '%ZIP_FILE%' -UseBasicParsing -TimeoutSec 60; Write-Host '[OK] Repository downloaded successfully' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Download failed:' $_.Exception.Message -ForegroundColor Red; exit 1 }" 2>nul

if !errorlevel! neq 0 (
    echo [ERROR] Failed to download repository
    goto :error_exit
)
echo.

echo [EXTRACT] Extracting repository files...

REM Extract ZIP file using PowerShell with better error handling
powershell -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force; Write-Host '[OK] Files extracted successfully' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Extraction failed:' $_.Exception.Message -ForegroundColor Red; exit 1 }" 2>nul

if !errorlevel! neq 0 (
    echo [ERROR] Failed to extract repository files
    goto :error_exit
)

REM Verify extraction
if not exist "%EXTRACT_DIR%" (
    echo [ERROR] Extracted directory not found: %EXTRACT_DIR%
    goto :error_exit
)
echo [OK] Repository extracted to temporary location
echo.

:skip_install
echo [INSTALL] Starting PowerShell profile installation...
echo [INFO] Running installation script from downloaded repository...

REM Check if we're in skip mode and handle accordingly
if "%SKIP_INSTALL%"=="1" (
    echo [INFO] Skipping full installation, updating profile only...
    
    REM Create profile directories if they don't exist
    if not exist "%PS_PROFILE_DIR%" (
        echo [INFO] Creating PowerShell profile directory: %PS_PROFILE_DIR%
        mkdir "%PS_PROFILE_DIR%" 2>nul
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to create directory: %PS_PROFILE_DIR%
            goto :error_exit
        )
    )
    
    if not exist "%WIN_PS_PROFILE_DIR%" (
        echo [INFO] Creating Windows PowerShell profile directory: %WIN_PS_PROFILE_DIR%
        mkdir "%WIN_PS_PROFILE_DIR%" 2>nul
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to create directory: %WIN_PS_PROFILE_DIR%
            goto :error_exit
        )
    )
    
    REM Copy profile files to both locations
    if exist "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" (
        copy "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" "%PS_PROFILE_DIR%\" /Y >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Copied profile to PowerShell Core directory
        ) else (
            echo [WARNING] Failed to copy profile to PowerShell Core directory
        )
        
        copy "%EXTRACT_DIR%\Microsoft.PowerShell_profile.ps1" "%WIN_PS_PROFILE_DIR%\" /Y >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Copied profile to Windows PowerShell directory
        ) else (
            echo [WARNING] Failed to copy profile to Windows PowerShell directory
        )
    ) else (
        echo [WARNING] Profile file not found in repository
    )
    
    REM Copy theme file if it exists
    if exist "%EXTRACT_DIR%\oh-my-posh-default.json" (
        copy "%EXTRACT_DIR%\oh-my-posh-default.json" "%PS_PROFILE_DIR%\" /Y >nul 2>&1
        copy "%EXTRACT_DIR%\oh-my-posh-default.json" "%WIN_PS_PROFILE_DIR%\" /Y >nul 2>&1
        echo [OK] Copied theme configuration
    )
    
    REM Copy modules if they exist
    if exist "%EXTRACT_DIR%\Modules" (
        if not exist "%PS_PROFILE_DIR%\Modules" mkdir "%PS_PROFILE_DIR%\Modules" 2>nul
        if not exist "%WIN_PS_PROFILE_DIR%\Modules" mkdir "%WIN_PS_PROFILE_DIR%\Modules" 2>nul
        
        xcopy "%EXTRACT_DIR%\Modules" "%PS_PROFILE_DIR%\Modules\" /E /I /Y /Q >nul 2>&1
        xcopy "%EXTRACT_DIR%\Modules" "%WIN_PS_PROFILE_DIR%\Modules\" /E /I /Y /Q >nul 2>&1
        echo [OK] Copied custom modules
    )
    
    echo [OK] Profile update completed
    set "INSTALL_RESULT=0"
    goto :verify_install
) else (
    REM Check if installation script exists
    if not exist "%EXTRACT_DIR%\quick-install.ps1" (
        echo [ERROR] Installation script not found in repository
        echo [INFO] Available files in repository:
        dir "%EXTRACT_DIR%" /b 2>nul
        goto :error_exit
    )

    echo.
    echo ═══════════════════════════════════════════════════════════════════════════════
    echo                   INSTALLATION PROGRESS
    echo ═══════════════════════════════════════════════════════════════════════════════

    REM Run installation script with visible output
    cd /d "%EXTRACT_DIR%" 2>nul
    if !errorlevel! neq 0 (
        echo [ERROR] Cannot change to extraction directory
        goto :error_exit
    )
    
    echo [INFO] Running installation with complete directory clearing (no backups)...
    powershell -ExecutionPolicy Bypass -NoProfile -Command "& '.\quick-install.ps1' -CleanInstall 2>&1; exit $LASTEXITCODE" 2>nul
    set "INSTALL_RESULT=!errorlevel!"

    echo.
    echo ═══════════════════════════════════════════════════════════════════════════════
)

:verify_install
REM Verify installation
echo [VERIFY] Checking installation results...

powershell -NoProfile -Command "if (Test-Path '$env:PS_PROFILE') { Write-Host '[OK] PowerShell profile created successfully' -ForegroundColor Green; exit 0 } else { Write-Host '[ERROR] PowerShell profile not found' -ForegroundColor Red; exit 1 }" 2>nul
set "PROFILE_CHECK=!errorlevel!"

powershell -NoProfile -Command "try { Get-Module posh-git,Terminal-Icons -ListAvailable -ErrorAction SilentlyContinue | Out-Null; Write-Host '[OK] Essential modules available' -ForegroundColor Green } catch { Write-Host '[INFO] Some modules may need installation' -ForegroundColor Yellow }" 2>nul

echo.
echo ═══════════════════════════════════════════════════════════════════════════════

if !INSTALL_RESULT! equ 0 if !PROFILE_CHECK! equ 0 (
    color 0A
    echo [SUCCESS] PowerShell profile installed successfully
    echo.
    echo ✓ Repository downloaded from GitHub
    echo ✓ PowerShell profile configured
    echo ✓ Essential modules installed
    echo ✓ Configuration files copied
    echo.
    echo [NEXT STEPS]
    echo 1. Close this window
    echo 2. Open a new PowerShell window
    echo 3. Try these commands: neofetch, ll, health
    echo.
    echo [CLEANUP] Removing temporary files...
    cd /d "%~dp0" 2>nul
    for /l %%i in (1,1,3) do (
        rmdir /s /q "%TEMP_DIR%" 2>nul
        if not exist "%TEMP_DIR%" goto cleanup_final_success
        timeout /t 1 /nobreak >nul 2>&1
    )
    echo [INFO] Some temporary files may remain: %TEMP_DIR%
    goto cleanup_final_done
    :cleanup_final_success
    echo [OK] Cleanup completed
    :cleanup_final_done
    echo.
    echo [INFO] Press any key to close this window...
    echo === Install completed successfully at %DATE% %TIME% === >> "%LOG_FILE%" 2>nul
    pause
) else (
    color 0C
    echo [FAILED] Installation encountered errors!
    echo.
    echo [TROUBLESHOOTING]
    echo 1. Run as Administrator
    echo 2. Check internet connection
    echo 3. Verify execution policy with: Get-ExecutionPolicy
    echo 4. Try manual installation from: %REPO_URL%
    echo 5. Use PowerShell directly: .\quick-install.ps1
    echo.
    echo [INFO] Temporary files left for debugging: %TEMP_DIR%
    echo [INFO] Press any key to close this window...
    echo === Install FAILED at %DATE% %TIME% === >> "%LOG_FILE%" 2>nul
    pause
)

goto :eof

:error_exit
echo.
echo ═══════════════════════════════════════════════════════════════════════════════
color 0C
echo [FAILED] Pre-installation checks failed!
echo.
echo [TROUBLESHOOTING]
echo 1. Check your internet connection
echo 2. Ensure PowerShell is properly installed
echo 3. Try running as Administrator
echo 4. Visit repository manually: %REPO_URL%
echo 5. Check Windows version compatibility
echo.
echo [INFO] Press any key to close this window...
echo === Pre-install checks FAILED at %DATE% %TIME% === >> "%LOG_FILE%" 2>nul
pause
exit /b 1