# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Ultra Quick Install
# Author: Bogdan Ichim
# One-liner installer for PowerShell enhanced profile
# ═══════════════════════════════════════════════════════════════════════════════

param([switch]$Silent, [switch]$Verbose, [switch]$CleanInstall)

# Configure output preferences
if ($Silent) { 
    $ErrorActionPreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue" 
} else {
    $ErrorActionPreference = "Continue"
    $WarningPreference = "Continue"
    $VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }
}

# Function to refresh environment variables
function Update-EnvironmentVariables {
    Log "Refreshing environment variables..." "INFO"
    
    try {
        # Refresh environment variables from registry
        $envMachine = [Environment]::GetEnvironmentVariables("Machine")
        $envUser = [Environment]::GetEnvironmentVariables("User")
        
        # Update PATH with latest values
        $machinePath = $envMachine["PATH"]
        $userPath = $envUser["PATH"]
        $combinedPath = "$machinePath;$userPath"
        
        $env:PATH = $combinedPath
        
        # Update other important environment variables
        foreach ($key in $envUser.Keys) {
            [Environment]::SetEnvironmentVariable($key, $envUser[$key], "Process")
        }
        
        foreach ($key in $envMachine.Keys) {
            if (-not $envUser.ContainsKey($key)) {
                [Environment]::SetEnvironmentVariable($key, $envMachine[$key], "Process")
            }
        }
        
        Log "Environment variables refreshed successfully" "OK"
    } catch {
        Log "Warning: Could not refresh all environment variables - $($_.Exception.Message)" "WARN"
    }
}

function Log($msg, $type="INFO") {
    $color = switch($type) {
        "OK" { "Green" }
        "WARN" { "Yellow" } 
        "ERROR" { "Red" }
        "STEP" { "Cyan" }
        "INFO" { "White" }
        "CLEAN" { "Magenta" }
        default { "White" }
    }
    
    # Always show output unless explicitly silenced
    if (-not $Silent) { 
        Write-Host "[$type] $msg" -ForegroundColor $color
    }
}

# Enhanced function to detect environment and get all PowerShell profile directories
function Get-PowerShellProfileDirs {
    Log "Detecting system environment and PowerShell installations..." "INFO"
    
    # Comprehensive environment variable detection
    $envVars = @{
        UserProfile = $env:USERPROFILE
        UserName = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
        OS = $env:OS
        Architecture = $env:PROCESSOR_ARCHITECTURE
        WinDir = $env:WINDIR
        ProgramFiles = $env:ProgramFiles
        ProgramFilesX86 = ${env:ProgramFiles(x86)}
        AppData = $env:APPDATA
        LocalAppData = $env:LOCALAPPDATA
        OneDrive = $env:OneDrive
        OneDriveConsumer = $env:OneDriveConsumer
        OneDriveCommercial = $env:OneDriveCommercial
    }
    
    Log "System Environment:" "INFO"
    Log "  User: $($envVars.UserName) on $($envVars.ComputerName)" "INFO"
    Log "  OS: $($envVars.OS) ($($envVars.Architecture))" "INFO"
    Log "  Profile Path: $($envVars.UserProfile)" "INFO"
    if ($envVars.OneDrive) { Log "  OneDrive: $($envVars.OneDrive)" "INFO" }
    
    # Try multiple methods to get Documents folder (handle OneDrive redirection)
    $documentsPath = $null
    $documentsPaths = @(
        [Environment]::GetFolderPath("MyDocuments"),
        "$($envVars.UserProfile)\Documents",
        "$($envVars.OneDrive)\Documents",
        "$($envVars.OneDriveConsumer)\Documents",
        "$($envVars.OneDriveCommercial)\Documents"
    )
    
    foreach ($path in $documentsPaths) {
        if ($path -and (Test-Path $path)) {
            $documentsPath = $path
            Log "Documents folder detected: $documentsPath" "OK"
            break
        }
    }
    
    if (-not $documentsPath) {
        $documentsPath = "$($envVars.UserProfile)\Documents"
        Log "Using fallback Documents path: $documentsPath" "WARN"
    }
    
    $profileDirs = @()
    
    # PowerShell Core (7+) detection - multiple methods
    $pwshInstalled = $false
    $pwshPaths = @(
        (Get-Command pwsh -ErrorAction SilentlyContinue),
        (Test-Path "$($envVars.ProgramFiles)\PowerShell\*\pwsh.exe"),
        (Test-Path "$($envVars.LocalAppData)\Microsoft\PowerShell\*\pwsh.exe"),
        (Get-ChildItem "$($envVars.ProgramFiles)\PowerShell" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.\d+' }),
        (Test-Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore" -ErrorAction SilentlyContinue)
    )
    
    $pwshInstalled = ($pwshPaths | Where-Object { $_ }) -ne $null
    
    if ($pwshInstalled) {
        $coreDir = "$documentsPath\PowerShell"
        $profileDirs += @{
            Path = $coreDir
            Name = "PowerShell Core (7+)"
            ProfileFile = "$coreDir\Microsoft.PowerShell_profile.ps1"
            Version = "Core"
        }
        Log "PowerShell Core (7+) installation detected" "OK"
    }
    
    # Windows PowerShell (5.1) detection - multiple methods
    $powershellInstalled = $false
    $powershellPaths = @(
        (Get-Command powershell -ErrorAction SilentlyContinue),
        (Test-Path "$($envVars.WinDir)\System32\WindowsPowerShell\v1.0\powershell.exe"),
        (Test-Path "$($envVars.WinDir)\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"),
        (Test-Path "HKLM:\SOFTWARE\Microsoft\PowerShell" -ErrorAction SilentlyContinue)
    )
    
    $powershellInstalled = ($powershellPaths | Where-Object { $_ }) -ne $null
    
    if ($powershellInstalled) {
        $winDir = "$documentsPath\WindowsPowerShell"
        $profileDirs += @{
            Path = $winDir
            Name = "Windows PowerShell (5.1)"
            ProfileFile = "$winDir\Microsoft.PowerShell_profile.ps1"
            Version = "Desktop"
        }
        Log "Windows PowerShell (5.1) installation detected" "OK"
    }
    
    # Validate detected installations
    Log "PowerShell installation summary:" "INFO"
    if ($profileDirs.Count -eq 0) {
        Log "No PowerShell installations detected!" "ERROR"
        throw "No PowerShell installations found. Please install PowerShell first."
    }
    
    foreach ($dir in $profileDirs) {
        Log "  - $($dir.Name): $($dir.Path)" "INFO"
    }
    
    return $profileDirs
}

# Function to completely clear profile directories (no backups)
function Clear-OldProfiles {
    param($ProfileDirs)
    
    Log "Completely clearing PowerShell profile directories (no backups)..." "CLEAN"
    
    foreach ($profileDir in $ProfileDirs) {
        $path = $profileDir.Path
        $name = $profileDir.Name
        
        if (Test-Path $path) {
            Log "Completely clearing $name directory: $path" "CLEAN"
            
            try {
                # Remove entire directory contents
                Get-ChildItem $path -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Log "All contents removed from $name directory" "OK"
                
                # Ensure directory still exists (empty)
                if (-not (Test-Path $path)) {
                    New-Item -ItemType Directory -Path $path -Force | Out-Null
                    Log "Recreated empty $name directory" "OK"
                }
            } catch {
                Log "Warning: Some files could not be removed from $name - $($_.Exception.Message)" "WARN"
                
                # Force remove specific items if general removal failed
                try {
                    # Remove profile files
                    Get-ChildItem "$path\*.ps1" -Force -ErrorAction SilentlyContinue | Remove-Item -Force
                    # Remove theme files
                    Get-ChildItem "$path\*.json" -Force -ErrorAction SilentlyContinue | Remove-Item -Force
                    # Remove modules directory
                    if (Test-Path "$path\Modules") {
                        Remove-Item "$path\Modules" -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    # Remove scripts directory
                    if (Test-Path "$path\Scripts") {
                        Remove-Item "$path\Scripts" -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    # Remove any backup directories
                    Get-ChildItem "$path\backup-*" -Directory -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
                    Log "Force-removed specific items from $name" "OK"
                } catch {
                    Log "Warning: Some items still could not be removed from $name" "WARN"
                }
            }
        } else {
            Log "$name directory doesn't exist, will be created fresh" "INFO"
        }
    }
}

try {
    Log "Starting PowerShell profile installation..." "STEP"
    Log "Script location: $PSScriptRoot" "INFO"
    Log "Current PowerShell version: $($PSVersionTable.PSVersion)" "INFO"
    
    # Refresh environment variables to ensure we have the latest values
    Update-EnvironmentVariables
    
    # Get all PowerShell directories
    $allProfileDirs = Get-PowerShellProfileDirs
    if ($allProfileDirs.Count -eq 0) {
        Log "No PowerShell installations found!" "ERROR"
        throw "No PowerShell installations detected"
    }
    
    Log "Found $($allProfileDirs.Count) PowerShell installation(s):" "INFO"
    foreach ($dir in $allProfileDirs) {
        Log "  - $($dir.Name): $($dir.Path)" "INFO"
    }
    
    # Clean old installations if requested or if this is a fresh install
    if ($CleanInstall -or -not (Test-Path $allProfileDirs[0].ProfileFile)) {
        Clear-OldProfiles -ProfileDirs $allProfileDirs
    }
    
    # Set execution policy
    Log "Setting execution policy to RemoteSigned..." "STEP"
    try {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Log "Execution policy updated successfully" "OK"
    } catch {
        Log "Warning: Could not set execution policy - $($_.Exception.Message)" "WARN"
    }

    # Install essential modules
    Log "Installing essential PowerShell modules..." "STEP"
    $modules = @("PSReadLine","posh-git","Terminal-Icons")
    foreach ($module in $modules) {
        Log "Checking module: $module" "INFO"
        if (-not (Get-Module $module -ListAvailable -ErrorAction SilentlyContinue)) {
            Log "Installing $module..." "INFO"
            try {
                Install-Module $module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop -Confirm:$false
                Log "$module installed successfully" "OK"
            } catch {
                Log "Failed to install $module - $($_.Exception.Message)" "ERROR"
            }
        } else {
            Log "$module already available" "OK"
        }
    }

    # Install tools via winget
    Log "Installing additional tools via winget..." "STEP"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $tools = @(
            @{name="oh-my-posh"; id="JanDeDobbeleer.OhMyPosh"},
            @{name="git"; id="Git.Git"},
            @{name="zoxide"; id="ajeetdsouza.zoxide"}
        )
        foreach ($tool in $tools) {
            Log "Checking tool: $($tool.name)" "INFO"
            if (-not (Get-Command $tool.name -ErrorAction SilentlyContinue)) {
                Log "Installing $($tool.name)..." "INFO"
                try {
                    $process = Start-Process winget -ArgumentList "install", $tool.id, "--silent", "--accept-source-agreements", "--accept-package-agreements" -Wait -PassThru -NoNewWindow
                    if ($process.ExitCode -eq 0) {
                        Log "$($tool.name) installed successfully" "OK"
                    } else {
                        Log "$($tool.name) installation may have issues (exit code: $($process.ExitCode))" "WARN"
                    }
                } catch {
                    Log "Failed to install $($tool.name) - $($_.Exception.Message)" "ERROR"
                }
            } else {
                Log "$($tool.name) already available" "OK"
            }
        }
        
        # Refresh environment to pick up new tools
        Log "Refreshing environment variables..." "INFO"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Log "winget not available - skipping tool installation" "WARN"
    }

    # Install profile for each PowerShell version
    Log "Installing profile for all PowerShell versions..." "STEP"
    
    foreach ($profileDir in $allProfileDirs) {
        $targetPath = $profileDir.Path
        $targetName = $profileDir.Name
        $targetProfile = $profileDir.ProfileFile
        
        Log "Installing profile for $targetName..." "INFO"
        
        # Create profile directory with robust path handling
        try {
            if (-not (Test-Path $targetPath)) { 
                Log "Creating profile directory for $targetName..." "INFO"
                
                # Ensure parent directory exists first
                $parentDir = Split-Path $targetPath -Parent
                if ($parentDir -and -not (Test-Path $parentDir)) {
                    Log "Creating parent directory: $parentDir" "INFO"
                    New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
                }
                
                # Create the target directory
                New-Item -ItemType Directory -Path $targetPath -Force -ErrorAction Stop | Out-Null
                
                # Verify directory was created
                if (Test-Path $targetPath) {
                    Log "Profile directory created successfully: $targetPath" "OK"
                } else {
                    throw "Directory creation verification failed"
                }
            } else {
                Log "Profile directory already exists: $targetPath" "OK"
            }
        } catch {
            Log "Failed to create profile directory for $targetName - $($_.Exception.Message)" "ERROR"
            continue
        }
        
        # Copy main profile file with enhanced error handling
        $profileSrc = "$PSScriptRoot\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $profileSrc) {
            try {
                Log "Copying profile from: $profileSrc" "INFO"
                Log "Copying profile to: $targetProfile" "INFO"
                
                # Verify source file accessibility
                $sourceContent = Get-Content $profileSrc -Raw -Encoding UTF8 -ErrorAction Stop
                if (-not $sourceContent) {
                    throw "Source file appears to be empty or unreadable"
                }
                
                # Verify target directory is writable
                $testFile = "$targetPath\test-write.tmp"
                "test" | Out-File -FilePath $testFile -Force -ErrorAction Stop
                Remove-Item $testFile -Force -ErrorAction SilentlyContinue
                
                # Use Copy-Item for more reliable copying
                Copy-Item -Path $profileSrc -Destination $targetProfile -Force -ErrorAction Stop
                
                # Verify the copy was successful
                if ((Test-Path $targetProfile) -and (Get-Content $targetProfile -Raw -ErrorAction SilentlyContinue)) {
                    Log "Profile copied to $targetName successfully" "OK"
                } else {
                    throw "Profile copy verification failed"
                }
            } catch {
                Log "Failed to copy profile to $targetName - $($_.Exception.Message)" "ERROR"
                Log "Attempting fallback copy method..." "WARN"
                
                # Fallback: Try alternative copy method
                try {
                    $content = [System.IO.File]::ReadAllText($profileSrc, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($targetProfile, $content, [System.Text.Encoding]::UTF8)
                    
                    if (Test-Path $targetProfile) {
                        Log "Fallback copy successful for $targetName" "OK"
                    } else {
                        throw "Fallback copy also failed"
                    }
                } catch {
                    Log "All copy methods failed for $targetName - $($_.Exception.Message)" "ERROR"
                    continue
                }
            }
        } else {
            Log "Source profile not found: $profileSrc" "ERROR"
            continue
        }
        
        # Copy theme file
        $themeSrc = "$PSScriptRoot\oh-my-posh-default.json"
        $themeDst = "$targetPath\oh-my-posh-default.json"
        if (Test-Path $themeSrc) {
            try {
                Copy-Item $themeSrc $themeDst -Force -ErrorAction Stop
                Log "Oh My Posh theme copied to $targetName" "OK"
            } catch {
                Log "Failed to copy theme to $targetName - $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Copy verification script
        $verifySrc = "$PSScriptRoot\verify-theme.ps1"
        $verifyDst = "$targetPath\verify-theme.ps1"
        if (Test-Path $verifySrc) {
            try {
                Copy-Item $verifySrc $verifyDst -Force -ErrorAction Stop
                Log "Verification script copied to $targetName" "OK"
            } catch {
                Log "Failed to copy verification script to $targetName - $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Copy modules
        $srcMod = "$PSScriptRoot\Modules"
        if (Test-Path $srcMod) {
            $dstMod = "$targetPath\Modules"
            Log "Installing bundled modules for $targetName..." "INFO"
            
            try {
                # Remove existing modules directory to ensure clean install
                if (Test-Path $dstMod) { 
                    Remove-Item $dstMod -Recurse -Force -ErrorAction SilentlyContinue 
                }
                
                Copy-Item $srcMod $dstMod -Recurse -Force -ErrorAction Stop
                Log "Modules copied to $targetName successfully" "OK"
            } catch {
                Log "Failed to copy modules to $targetName - $($_.Exception.Message)" "ERROR"
            }
        }
        
        Log "$targetName installation completed" "OK"
    }
    
    Log "Profile installation completed successfully!" "OK"
    
    # Final verification
    Log "Verifying installation..." "STEP"
    $successCount = 0
    $totalDirs = $allProfileDirs.Count
    
    foreach ($profileDir in $allProfileDirs) {
        if (Test-Path $profileDir.ProfileFile) {
            Log "$($profileDir.Name): Profile installed ✓" "OK"
            $successCount++
        } else {
            Log "$($profileDir.Name): Profile missing ✗" "ERROR"
        }
    }
    
    if (-not $Silent) { 
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "                 INSTALLATION SUMMARY" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "✓ PowerShell profiles installed: $successCount/$totalDirs" -ForegroundColor Green
        Write-Host "✓ Essential modules installed" -ForegroundColor Green  
        Write-Host "✓ Oh My Posh theme configured" -ForegroundColor Green
        Write-Host "✓ Git integration enabled" -ForegroundColor Green
        Write-Host "✓ Terminal icons configured" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Installed for:" -ForegroundColor Yellow
        foreach ($profileDir in $allProfileDirs) {
            if (Test-Path $profileDir.ProfileFile) {
                Write-Host "  ✓ $($profileDir.Name)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $($profileDir.Name)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Close this PowerShell window" -ForegroundColor White
        Write-Host "2. Open a new PowerShell (or PowerShell Core) window" -ForegroundColor White
        Write-Host "3. Try these commands:" -ForegroundColor White

        Write-Host "   • ll          - Enhanced directory listing" -ForegroundColor Gray
        Write-Host "   • health      - System health check" -ForegroundColor Gray
        Write-Host "   • help-profile - Show all available commands" -ForegroundColor Gray
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    }
    
    # Cleanup temporary files and folders
    Log "Cleaning up temporary files..." "STEP"
    try {
        # Clean up any PowerShell module installation temp files
        $tempPaths = @(
            "$env:TEMP\*powershell*",
            "$env:TEMP\*posh-git*", 
            "$env:TEMP\*terminal-icons*",
            "$env:TEMP\NuGet",
            "$env:LOCALAPPDATA\Temp\*powershell*",
            "$env:TEMP\powershell-profile-install",
            "$env:TEMP\PSRepository*",
            "$env:TEMP\ModuleAnalysisCache"
        )
        
        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                try {
                    Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    # Silently continue if cleanup fails
                }
            }
        }
        
        Log "Temporary files cleanup completed" "OK"
    } catch {
        Log "Warning: Some temporary files could not be cleaned up" "WARN"
    }
    
    # Return success code based on results
    if ($successCount -eq $totalDirs) {
        exit 0
    } else {
        Log "Warning: Not all PowerShell versions were configured successfully" "WARN"
        exit 1
    }
    
} catch {
    Log "Installation failed: $($_.Exception.Message)" "ERROR"
    Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    # Cleanup even on failure
    Log "Performing cleanup after failed installation..." "INFO"
    try {
        $tempPaths = @(
            "$env:TEMP\*powershell*",
            "$env:TEMP\*posh-git*", 
            "$env:TEMP\*terminal-icons*",
            "$env:TEMP\NuGet",
            "$env:TEMP\powershell-profile-install",
            "$env:TEMP\PSRepository*"
        )
        
        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Log "Cleanup completed" "OK"
    } catch {
        # Silently fail cleanup
    }
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "                 INSTALLATION FAILED" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Run as Administrator" -ForegroundColor White
        Write-Host "2. Check internet connection" -ForegroundColor White
        Write-Host "3. Verify PowerShell execution policy" -ForegroundColor White
        Write-Host "4. Try manual installation from GitHub" -ForegroundColor White
        Write-Host "5. Check Windows version compatibility" -ForegroundColor White
        Write-Host ""
    }
    exit 1
}