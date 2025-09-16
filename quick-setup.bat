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

REM === SECURITY CHECK - Execution Policy ===
echo [SECURITY] Checking PowerShell execution policy...
for /f "tokens=*" %%p in ('powershell -NoProfile -Command "Get-ExecutionPolicy" 2^>nul') do set "EXEC_POLICY=%%p"
echo [INFO] Current execution policy: %EXEC_POLICY%

if /i "%EXEC_POLICY%"=="Restricted" (
    echo [WARNING] Execution policy is Restricted. PowerShell scripts cannot run.
    echo [SOLUTION] Run this command in PowerShell as Administrator:
    echo            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
    echo [PROMPT] Would you like me to attempt to fix this automatically? (y/n)
    set /p FIX_POLICY="Choice: "
    if /i "!FIX_POLICY!"=="y" (
        echo [INFO] Attempting to set execution policy...
        powershell -NoProfile -Command "try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host '[OK] Execution policy updated' -ForegroundColor Green } catch { Write-Host '[ERROR] Failed to update execution policy. Run as Administrator.' -ForegroundColor Red; exit 1 }"
        if errorlevel 1 (
            echo [ERROR] Could not update execution policy. Please run as Administrator or set manually.
            goto :error_exit
        )
    ) else (
        echo [ERROR] Cannot proceed with Restricted execution policy.
        goto :error_exit
    )
)
echo [OK] Execution policy is compatible
echo.

REM Check internet connectivity
echo [CHECK] Testing internet connectivity...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot reach GitHub. Check your internet connection.
    goto :error_exit
)
echo [OK] Internet connectivity verified
echo.

REM === Enhanced Module Installation ===
echo [MODULES] Checking and installing required PowerShell modules...

powershell -NoProfile -Command "
$modules = @('PSReadLine', 'posh-git', 'Terminal-Icons')
$failed = @()

foreach ($module in $modules) {
    try {
        Write-Host '[CHECK] Checking module:' $module -ForegroundColor Cyan
        
        $installed = Get-Module $module -ListAvailable -ErrorAction SilentlyContinue
        if ($installed) {
            $version = ($installed | Sort-Object Version -Descending | Select-Object -First 1).Version
            Write-Host '  [OK]' $module '(' $version ') already installed' -ForegroundColor Green
        } else {
            Write-Host '  [INSTALL] Installing' $module '...' -ForegroundColor Yellow
            
            # Install with comprehensive error handling
            Install-Module $module -Repository PSGallery -Force -AllowClobber -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop
            
            # Verify installation
            $newInstall = Get-Module $module -ListAvailable -ErrorAction SilentlyContinue
            if ($newInstall) {
                $version = ($newInstall | Sort-Object Version -Descending | Select-Object -First 1).Version
                Write-Host '  [OK]' $module '(' $version ') installed successfully' -ForegroundColor Green
            } else {
                throw 'Installation verification failed'
            }
        }
    } catch {
        Write-Host '  [ERROR]' $module 'installation failed:' $_.Exception.Message -ForegroundColor Red
        $failed += $module
    }
}

if ($failed.Count -gt 0) {
    Write-Host '[WARNING] Failed modules:' ($failed -join ', ') -ForegroundColor Yellow
    Write-Host '[INFO] You may need to install these manually later' -ForegroundColor Yellow
    exit 2
} else {
    Write-Host '[SUCCESS] All required modules are available' -ForegroundColor Green
    exit 0
}
"

set MODULE_RESULT=%errorlevel%
if %MODULE_RESULT%==1 (
    echo [ERROR] Critical module installation failure
    goto :error_exit
) else if %MODULE_RESULT%==2 (
    echo [WARNING] Some modules failed to install, but continuing...
)
echo.

REM === Enhanced Tool Installation ===
echo [TOOLS] Checking and installing required tools with winget...

REM Check if winget is available
where winget >nul 2>&1
if errorlevel 1 (
    echo [WARN] winget not found. Tools must be installed manually:
    echo   - oh-my-posh: https://ohmyposh.dev/
    echo   - git: https://git-scm.com/
    echo   - zoxide: https://github.com/ajeetdsouza/zoxide
) else (
    echo [INFO] winget found, checking tools...
    
    REM Enhanced tool checking and installation
    call :check_and_install_tool "oh-my-posh" "JanDeDobbeleer.OhMyPosh"
    call :check_and_install_tool "git" "Git.Git"
    call :check_and_install_tool "zoxide" "ajeetdsouza.zoxide"
)
echo.

goto :skip_tool_subroutine

:check_and_install_tool
set "TOOL_EXE=%~1"
set "TOOL_ID=%~2"

echo [CHECK] Checking tool: %TOOL_EXE%
where %TOOL_EXE% >nul 2>&1
if errorlevel 1 (
    echo [INSTALL] Installing %TOOL_EXE%...
    winget install %TOOL_ID% --silent --accept-source-agreements --accept-package-agreements >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Failed to install %TOOL_EXE% via winget
        echo [INFO] You may need to install %TOOL_EXE% manually
    ) else (
        echo [OK] %TOOL_EXE% installed successfully
        REM Refresh PATH for current session
        call :refresh_path
        REM Verify installation
        where %TOOL_EXE% >nul 2>&1
        if errorlevel 1 (
            echo [INFO] %TOOL_EXE% installed but may require a new session to be available
        ) else (
            echo [VERIFY] %TOOL_EXE% is now available
        )
    )
) else (
    echo [OK] %TOOL_EXE% already available
    REM Show version if possible
    %TOOL_EXE% --version >nul 2>&1 && (
        for /f "tokens=*" %%v in ('%TOOL_EXE% --version 2^>nul ^| head -1') do echo [INFO] Version: %%v
    )
)
exit /b 0

:refresh_path
REM Refresh environment variables for current session
for /f "usebackq tokens=2,*" %%A in (`reg query HKCU\Environment /v PATH 2^>nul`) do (
    if not "%%B"=="" set "PATH=%%B;%PATH%"
)
for /f "usebackq tokens=2,*" %%A in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul`) do (
    if not "%%B"=="" set "PATH=%%B;%PATH%"
)
exit /b 0

:skip_tool_subroutine

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

REM Enhanced verification with detailed module status
powershell -NoProfile -Command "
Write-Host '[VERIFY] Checking module availability...' -ForegroundColor Cyan
$modules = @('PSReadLine', 'posh-git', 'Terminal-Icons')
$available = 0
foreach ($module in $modules) {
    $mod = Get-Module $module -ListAvailable -ErrorAction SilentlyContinue
    if ($mod) {
        $version = ($mod | Sort-Object Version -Descending | Select-Object -First 1).Version
        Write-Host '  [OK]' $module '(' $version ')' -ForegroundColor Green
        $available++
    } else {
        Write-Host '  [MISSING]' $module -ForegroundColor Yellow
    }
}
Write-Host '[INFO] Available modules:' $available 'of' $modules.Count -ForegroundColor Cyan
"
echo.

REM === Success ===
color 0A
echo ═══════════════════════════════════════════════════════════════════════════════
echo [SUCCESS] PowerShell profile installed successfully!
echo ═══════════════════════════════════════════════════════════════════════════════
echo.
echo ✓ Repository downloaded from GitHub
echo ✓ PowerShell profile configured  
echo ✓ Essential modules checked/installed
echo ✓ Required tools verified
echo ✓ Execution policy verified
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