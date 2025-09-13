@echo off
setlocal enabledelayedexpansion
title PowerShell Enhanced Profile - Complete Installer
color 0A

REM ═══════════════════════════════════════════════════════════════════════════════
REM PowerShell Enhanced Profile - Complete Installation Script
REM Author: Bogdan Ichim
REM Combines download, extraction, and installation in one file
REM ═══════════════════════════════════════════════════════════════════════════════

REM Check for Administrator Privileges
openfiles >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Administrator privileges required. Re-launching...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo                PowerShell Enhanced Profile - Complete Installer
echo ═══════════════════════════════════════════════════════════════════════════════
echo.

set "REPO_URL=https://github.com/ichimbogdancristian/powershell"
set "TEMP_DIR=%TEMP%\powershell-complete-install"

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
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "& {$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%REPO_URL%/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\repo.zip' -UseBasicParsing; Write-Host '[OK] Downloaded' -ForegroundColor Green } catch { Write-Host '[ERROR] Download failed' -ForegroundColor Red; exit 1 }}"

if %errorlevel% neq 0 goto :error_exit

echo [EXTRACT] Extracting files...
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "& {$ProgressPreference='SilentlyContinue'; try { Expand-Archive '%TEMP_DIR%\repo.zip' '%TEMP_DIR%' -Force; Write-Host '[OK] Extracted' -ForegroundColor Green } catch { Write-Host '[ERROR] Extract failed' -ForegroundColor Red; exit 1 }}"

if %errorlevel% neq 0 goto :error_exit

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo [INSTALL] Running PowerShell profile installation...
echo.

REM Run the complete PowerShell installation inline
powershell.exe -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "& {
    # Configure output preferences
    $ErrorActionPreference = 'Continue'
    $WarningPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'

    function Write-Status {
        param([string]$Message, [string]$Level = 'INFO')
        $color = switch ($Level) {
            'OK'    { 'Green' }
            'STEP'  { 'Cyan' }
            'INFO'  { 'White' }
            'WARN'  { 'Yellow' }
            'ERROR' { 'Red' }
            default { 'Gray' }
        }
        Write-Host '[$Level] $Message' -ForegroundColor $color
    }

    function Get-DocumentsPath {
        $paths = @()
        try { $paths += [Environment]::GetFolderPath('MyDocuments') } catch {}
        try { if ($env:USERPROFILE) { $paths += Join-Path $env:USERPROFILE 'Documents' } } catch {}
        try { if ($env:OneDrive) { $paths += Join-Path $env:OneDrive 'Documents' } } catch {}
        
        foreach ($p in $paths | Where-Object { $_ -and (Test-Path $_) }) {
            if ((Test-Path $p) -and (Test-Path $p -PathType Container)) {
                return $p
            }
        }
        return $null
    }

    function Get-ProfileDirectories {
        $dirs = @()
        $pwshPaths = @(
            $PROFILE.AllUsersCurrentHost,
            $PROFILE.AllUsersAllHosts,
            $PROFILE.CurrentUserCurrentHost,
            $PROFILE.CurrentUserAllHosts
        ) | Select-Object -Unique

        foreach ($profilePath in $pwshPaths) {
            if ($profilePath) {
                $dir = Split-Path $profilePath -Parent
                $dirs += [PSCustomObject]@{
                    Name = $profilePath
                    Path = $dir
                    ProfileFile = $profilePath
                }
            }
        }
        return $dirs
    }

    function Install-RequiredModules {
        Write-Status 'Installing required modules...' 'STEP'
        $modules = @('PSReadLine', 'posh-git', 'Terminal-Icons', 'oh-my-posh')
        $successCount = 0
        $skipCount = 0
        
        foreach ($module in $modules) {
            $existing = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Status \"$module already installed (v$($existing[0].Version)) - skipping\" 'OK'
                $skipCount++
            } else {
                Write-Status \"Installing $module...\" 'INFO'
                try {
                    Install-Module $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                    $installed = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue
                    if ($installed) {
                        Write-Status \"$module installed successfully (v$($installed[0].Version))\" 'OK'
                        $successCount++
                    } else {
                        Write-Status \"$module installation completed but module not found\" 'WARN'
                    }
                } catch {
                    Write-Status \"Failed to install $module`: $($_.Exception.Message)\" 'ERROR'
                }
            }
        }
        
        Write-Status \"Module installation summary: $successCount installed, $skipCount skipped\" 'INFO'
        return ($successCount + $skipCount -gt 0)
    }

    function Install-RequiredTools {
        Write-Status 'Installing required tools...' 'STEP'
        
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Status 'winget not available, skipping tool installation' 'WARN'
            Write-Status 'To install winget: Visit Microsoft Store or GitHub releases' 'INFO'
            return $false
        }
        
        $tools = @(
            @{name='oh-my-posh'; id='JanDeDobbeleer.OhMyPosh'},
            @{name='git'; id='Git.Git'},
            @{name='zoxide'; id='ajeetdsouza.zoxide'}
        )
        
        $successCount = 0
        $skipCount = 0
        
        foreach ($tool in $tools) {
            $existing = Get-Command $tool.name -ErrorAction SilentlyContinue
            if ($existing) {
                try {
                    # Try to get version info
                    $version = ''
                    switch ($tool.name) {
                        'oh-my-posh' { 
                            $versionOutput = & $tool.name --version 2>$null
                            if ($versionOutput) { $version = \" (v$versionOutput)\" }
                        }
                        'git' { 
                            $versionOutput = & $tool.name --version 2>$null
                            if ($versionOutput) { $version = \" ($($versionOutput -split ' ')[2])\" }
                        }
                        'zoxide' { 
                            $versionOutput = & $tool.name --version 2>$null
                            if ($versionOutput) { $version = \" (v$versionOutput)\" }
                        }
                    }
                    Write-Status \"$($tool.name) already available$version - skipping\" 'OK'
                } catch {
                    Write-Status \"$($tool.name) already available - skipping\" 'OK'
                }
                $skipCount++
            } else {
                Write-Status \"Installing $($tool.name)...\" 'INFO'
                try {
                    $process = Start-Process winget -ArgumentList 'install', $tool.id, '--silent', '--accept-source-agreements', '--accept-package-agreements' -Wait -PassThru -NoNewWindow -ErrorAction Stop
                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq -1978335189) {
                        # Verify installation
                        Start-Sleep -Seconds 2
                        if (Get-Command $tool.name -ErrorAction SilentlyContinue) {
                            Write-Status \"$($tool.name) installed successfully\" 'OK'
                            $successCount++
                        } else {
                            Write-Status \"$($tool.name) installation completed but command not found (may need PATH refresh)\" 'WARN'
                        }
                    } else {
                        Write-Status \"$($tool.name) installation failed (exit code: $($process.ExitCode))\" 'ERROR'
                    }
                } catch {
                    Write-Status \"Failed to install $($tool.name): $($_.Exception.Message)\" 'ERROR'
                }
            }
        }
        
        Write-Status \"Tool installation summary: $successCount installed, $skipCount skipped\" 'INFO'
        return ($successCount + $skipCount -gt 0)
    }

    function Test-SystemCompatibility {
        Write-Status 'Testing system compatibility...' 'STEP'
        
        $issues = @()
        $warnings = @()
        
        # Check Documents folder access
        $docsPath = Get-DocumentsPath
        if (-not $docsPath) {
            $issues += 'No writable Documents folder found'
        } else {
            Write-Status \"Documents folder: $docsPath\" 'INFO'
        }
        
        # Check PowerShell versions
        if (-not (Get-Command powershell -ErrorAction SilentlyContinue) -and 
            -not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            $issues += 'No PowerShell installations found'
        }
        
        # Check execution policy
        $policy = Get-ExecutionPolicy -Scope CurrentUser
        if ($policy -eq 'Restricted') {
            $warnings += 'Execution policy is Restricted - will attempt to change'
        }
        
        # Check internet connectivity
        try {
            $null = Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 5
            Write-Status 'Internet connectivity verified' 'OK'
        } catch {
            $warnings += 'Internet connectivity issues detected'
        }
        
        # Check disk space (minimum 100MB)
        $systemDrive = Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq $env:SystemDrive
        $freeSpaceMB = [math]::Round($systemDrive.FreeSpace / 1MB)
        if ($freeSpaceMB -lt 100) {
            $issues += \"Insufficient disk space: ${freeSpaceMB}MB available\"
        }
        
        # Report results
        if ($warnings.Count -gt 0) {
            Write-Status \"Warnings: $($warnings -join '; ')\" 'WARN'
        }
        
        if ($issues.Count -eq 0) {
            Write-Status 'System compatibility check passed' 'OK'
            return $true
        } else {
            Write-Status \"Compatibility issues: $($issues -join '; ')\" 'ERROR'
            return $false
        }
    }

    function Backup-ExistingProfile {
        param($ProfilePath)
        if (Test-Path $ProfilePath) {
            $backupPath = \"$ProfilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')\"
            Copy-Item $ProfilePath $backupPath -Force
            Write-Status \"Backed up existing profile to $(Split-Path $backupPath -Leaf)\" 'INFO'
            return $backupPath
        }
        return $null
    }

    function Restore-ProfileBackups {
        param($ProfileDirs)
        Write-Status 'Restoring profile backups due to installation failure...' 'WARN'
        foreach ($profileDir in $ProfileDirs) {
            $backupFiles = Get-ChildItem \"$($profileDir.ProfileFile).backup.*\" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
            if ($backupFiles) {
                $latestBackup = $backupFiles[0]
                Copy-Item $latestBackup.FullName $profileDir.ProfileFile -Force
                Write-Status \"Restored backup: $($latestBackup.Name)\" 'INFO'
            }
        }
    }

    function Install-ProfileContent {
        param($ProfileDirs)
        
        Write-Status 'Installing profile content...' 'STEP'
        
        $scriptDir = '%TEMP_DIR%\powershell-main'
        
        foreach ($profileDir in $ProfileDirs) {
            Write-Status \"Configuring $($profileDir.Name)...\" 'INFO'
            
            # Create directory if it doesn't exist
            if (-not (Test-Path $profileDir.Path)) {
                New-Item -ItemType Directory -Path $profileDir.Path -Force | Out-Null
            }
            
            # Backup existing profile before overwriting
            Backup-ExistingProfile -ProfilePath $profileDir.ProfileFile | Out-Null
            
            # Install new profile
            $profileSrc = Join-Path $scriptDir 'Microsoft.PowerShell_profile.ps1'
            if (Test-Path $profileSrc) {
                Copy-Item $profileSrc $profileDir.ProfileFile -Force | Out-Null
                Write-Status \"Profile installed for $($profileDir.Name)\" 'OK'
            } else {
                Write-Status 'Profile source file not found' 'ERROR'
            }
            
            # Install theme file
            $themeSrc = Join-Path $scriptDir 'oh-my-posh-default.json'
            if (Test-Path $themeSrc) {
                $themeDst = Join-Path $profileDir.Path 'oh-my-posh-default.json'
                Copy-Item $themeSrc $themeDst -Force | Out-Null
                Write-Status \"Theme installed for $($profileDir.Name)\" 'OK'
            }
        }
    }

    function Test-Installation {
        param($ProfileDirs)
        
        Write-Status 'Verifying installation...' 'STEP'
        
        $success = $true
        foreach ($profileDir in $ProfileDirs) {
            if (Test-Path $profileDir.ProfileFile) {
                Write-Status \"$($profileDir.Name): Profile installed\" 'OK'
            } else {
                Write-Status \"$($profileDir.Name): Profile missing\" 'ERROR'
                $success = $false
            }
        }
        
        return $success
    }

        # Main Installation Logic
        try {
            Write-Status 'Starting PowerShell profile installation...' 'STEP'
            
            if (-not (Test-SystemCompatibility)) {
                throw 'System compatibility test failed - see issues above'
            }
            
            Write-Status 'Setting execution policy...' 'INFO'
            try {
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
                Write-Status 'Execution policy updated successfully' 'OK'
            } catch {
                Write-Status 'Could not set execution policy - continuing anyway' 'WARN'
            }
            
            $profileDirs = Get-ProfileDirectories
            Write-Status \"Found $($profileDirs.Count) PowerShell installation(s)\" 'INFO'
            
            # Install dependencies with error checking
            Write-Status 'Installing PowerShell modules...' 'STEP'
            Install-RequiredModules
            
            Write-Status 'Installing external tools...' 'STEP'
            $toolsSuccess = Install-RequiredTools
            if (-not $toolsSuccess) {
                Write-Status 'Tool installation had issues - some features may not work' 'WARN'
            }
            
            # Refresh PATH environment
            Write-Status 'Refreshing environment PATH...' 'INFO'
            $env:PATH = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
            
            # Install profile content
            Install-ProfileContent -ProfileDirs $profileDirs
            
            # Verify installation
            $verificationResult = Test-Installation -ProfileDirs $profileDirs
            
            if (-not $verificationResult) {
                Restore-ProfileBackups -ProfileDirs $profileDirs
                throw 'Profile installation verification failed'
            }        # Final dependency verification
        Write-Status 'Verifying final installation status...' 'STEP'
        $modules = @('PSReadLine', 'posh-git', 'Terminal-Icons', 'oh-my-posh')
        $tools = @('oh-my-posh', 'git', 'zoxide')
        
        Write-Host '  PowerShell Modules:' -ForegroundColor Yellow
        foreach ($module in $modules) {
            $installed = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue
            if ($installed) {
                Write-Host \"    [OK] $module (v$($installed[0].Version))\" -ForegroundColor Green
            } else {
                Write-Host \"    [MISSING] $module\" -ForegroundColor Red
            }
        }
        
        Write-Host '  External Tools:' -ForegroundColor Yellow
        foreach ($tool in $tools) {
            $available = Get-Command $tool -ErrorAction SilentlyContinue
            if ($available) {
                Write-Host \"    [OK] $tool available\" -ForegroundColor Green
            } else {
                Write-Host \"    [MISSING] $tool\" -ForegroundColor Red
            }
        }

        Write-Host ''
        Write-Host '═══════════════════════════════════════════════════════════════' -ForegroundColor Cyan
        Write-Host '                INSTALLATION COMPLETE' -ForegroundColor Cyan
        Write-Host '═══════════════════════════════════════════════════════════════' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'Installed for:' -ForegroundColor Yellow
        foreach ($profileDir in $profileDirs) {
            $status = if (Test-Path $profileDir.ProfileFile) { '[OK]' } else { '[FAIL]' }
            $color = if (Test-Path $profileDir.ProfileFile) { 'Green' } else { 'Red' }
            Write-Host \"  $status $($profileDir.Name)\" -ForegroundColor $color
        }
        Write-Host ''
        Write-Host 'Next Steps:' -ForegroundColor Cyan
        Write-Host '1. Restart PowerShell' -ForegroundColor White
        Write-Host '2. Try: ll, health, help-profile' -ForegroundColor White
        Write-Host ''
        
        if ($verificationResult) {
            exit 0
        } else {
            exit 1
        }
        
    } catch {
        Write-Status \"Installation failed: $($_.Exception.Message)\" 'ERROR'
        Write-Host ''
        Write-Host '═══════════════════════════════════════════════════════════════' -ForegroundColor Red
        Write-Host '                INSTALLATION FAILED' -ForegroundColor Red
        Write-Host '═══════════════════════════════════════════════════════════════' -ForegroundColor Red
        Write-Host \"Error: $($_.Exception.Message)\" -ForegroundColor Red
        Write-Host ''
        Write-Host 'Troubleshooting:' -ForegroundColor Yellow
        Write-Host '1. Run as Administrator' -ForegroundColor White
        Write-Host '2. Check internet connection' -ForegroundColor White
        Write-Host '3. Verify PowerShell execution policy' -ForegroundColor White
        Write-Host ''
        exit 1
    }
}"

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
echo [REQUIREMENTS]
echo 1. Internet connection
echo 2. PowerShell installed
echo 3. Administrator rights (recommended)
echo.
echo Press any key to close...
pause >nul
exit /b 1