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

# Function to get all PowerShell profile directories
function Get-PowerShellProfileDirs {
    $documentsPath = [Environment]::GetFolderPath("MyDocuments")
    $profileDirs = @()
    
    # PowerShell Core (7+) directory
    $coreDir = "$documentsPath\PowerShell"
    if ((Get-Command pwsh -ErrorAction SilentlyContinue) -or (Test-Path "$env:ProgramFiles\PowerShell\*\pwsh.exe")) {
        $profileDirs += @{
            Path = $coreDir
            Name = "PowerShell Core (7+)"
            ProfileFile = "$coreDir\Microsoft.PowerShell_profile.ps1"
            Version = "Core"
        }
    }
    
    # Windows PowerShell (5.1) directory
    $winDir = "$documentsPath\WindowsPowerShell"
    if ((Get-Command powershell -ErrorAction SilentlyContinue) -or (Test-Path "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe")) {
        $profileDirs += @{
            Path = $winDir
            Name = "Windows PowerShell (5.1)"
            ProfileFile = "$winDir\Microsoft.PowerShell_profile.ps1"
            Version = "Desktop"
        }
    }
    
    return $profileDirs
}

# Function to clean old profile installations
function Clear-OldProfiles {
    param($ProfileDirs)
    
    Log "Cleaning old profile installations..." "CLEAN"
    
    foreach ($profileDir in $ProfileDirs) {
        $path = $profileDir.Path
        $name = $profileDir.Name
        
        if (Test-Path $path) {
            Log "Cleaning $name directory: $path" "CLEAN"
            
            # Create backup first
            $backupPath = "$path\backup-before-clean-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
            try {
                if (Test-Path $profileDir.ProfileFile) {
                    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
                    Copy-Item $profileDir.ProfileFile "$backupPath\Microsoft.PowerShell_profile.ps1.bak" -Force
                    Log "Backed up existing profile to: $backupPath" "OK"
                }
            } catch {
                Log "Warning: Could not backup existing profile" "WARN"
            }
            
            # Remove old files but keep backups
            try {
                # Remove profile
                if (Test-Path $profileDir.ProfileFile) {
                    Remove-Item $profileDir.ProfileFile -Force
                    Log "Removed old profile from $name" "OK"
                }
                
                # Remove theme files
                Get-ChildItem "$path\*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
                Log "Removed old theme files from $name" "OK"
                
                # Remove old modules (but preserve user-installed ones)
                $modulesPath = "$path\Modules"
                if (Test-Path $modulesPath) {
                    $knownModules = @('posh-git', 'Terminal-Icons', 'PSReadLine')
                    foreach ($module in $knownModules) {
                        $modulePath = "$modulesPath\$module"
                        if (Test-Path $modulePath) {
                            Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
                            Log "Removed old $module module from $name" "OK"
                        }
                    }
                }
                
                # Remove any installation temp files
                Get-ChildItem "$path\temp-*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
                Get-ChildItem "$path\install-*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
                
            } catch {
                Log "Warning: Some files could not be removed from $name - $($_.Exception.Message)" "WARN"
            }
        } else {
            Log "$name directory doesn't exist, will be created" "INFO"
        }
    }
}

try {
    Log "Starting PowerShell profile installation..." "STEP"
    Log "Script location: $PSScriptRoot" "INFO"
    Log "Current PowerShell version: $($PSVersionTable.PSVersion)" "INFO"
    
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
        
        # Create profile directory if it doesn't exist
        if (-not (Test-Path $targetPath)) { 
            Log "Creating profile directory for $targetName..." "INFO"
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null 
            Log "Profile directory created: $targetPath" "OK"
        }
        
        # Copy main profile file
        $profileSrc = "$PSScriptRoot\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $profileSrc) {
            try {
                # Use UTF8 encoding for PowerShell files to preserve emojis
                $content = Get-Content $profileSrc -Raw -Encoding UTF8
                [System.IO.File]::WriteAllText($targetProfile, $content, [System.Text.Encoding]::UTF8)
                Log "Profile copied to $targetName successfully" "OK"
            } catch {
                Log "Failed to copy profile to $targetName - $($_.Exception.Message)" "ERROR"
                continue
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
        Write-Host "   • neofetch    - System information" -ForegroundColor Gray
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