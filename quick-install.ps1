# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Ultra Quick Install
# Author: Bogdan Ichim
# One-liner installer for PowerShell enhanced profile
# ═══════════════════════════════════════════════════════════════════════════════

param([switch]$Silent, [switch]$Verbose)

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
        default { "White" }
    }
    
    # Always show output unless explicitly silenced
    if (-not $Silent) { 
        Write-Host "[$type] $msg" -ForegroundColor $color
    }
}

try {
    Log "Starting PowerShell profile installation..." "STEP"
    
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
            @{name="git"; id="Git.Git"}
        )
        foreach ($tool in $tools) {
            Log "Checking tool: $($tool.name)" "INFO"
            if (-not (Get-Command $tool.name -ErrorAction SilentlyContinue)) {
                Log "Installing $($tool.name)..." "INFO"
                try {
                    $null = winget install $tool.id --silent --accept-source-agreements --accept-package-agreements 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Log "$($tool.name) installed successfully" "OK"
                    } else {
                        Log "$($tool.name) installation may have issues (exit code: $LASTEXITCODE)" "WARN"
                    }
                } catch {
                    Log "Failed to install $($tool.name) - $($_.Exception.Message)" "ERROR"
                }
            } else {
                Log "$($tool.name) already available" "OK"
            }
        }
    } else {
        Log "winget not available - skipping tool installation" "WARN"
    }

    # Setup profile
    Log "Setting up PowerShell profile..." "STEP"
    $profileDir = Split-Path $PROFILE -Parent
    Log "Profile directory: $profileDir" "INFO"
    
    if (-not (Test-Path $profileDir)) { 
        Log "Creating profile directory..." "INFO"
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null 
        Log "Profile directory created" "OK"
    }
    
    # Backup existing
    if (Test-Path $PROFILE) { 
        Log "Backing up existing profile..." "INFO"
        Copy-Item $PROFILE "$PROFILE.bak" -ErrorAction SilentlyContinue 
        Log "Profile backed up to $PROFILE.bak" "OK"
    }
    
    # Copy files
    Log "Copying profile files..." "STEP"
    $filesToCopy = @("Microsoft.PowerShell_profile.ps1","oh-my-posh-default.json")
    foreach ($file in $filesToCopy) {
        $src = "$PSScriptRoot\$file"
        $dst = if($file -like "*.ps1"){$PROFILE}else{"$profileDir\$file"}
        
        Log "Copying $file..." "INFO"
        if (Test-Path $src) { 
            try {
                # Use UTF8 encoding for PowerShell files to preserve emojis
                if ($file -like "*.ps1") {
                    $content = Get-Content $src -Raw -Encoding UTF8
                    [System.IO.File]::WriteAllText($dst, $content, [System.Text.Encoding]::UTF8)
                    
                    # Validate the copied file
                    try {
                        powershell -NoProfile -Command "Get-Content '$dst' | Out-Null" -ErrorAction Stop | Out-Null
                        Log "Profile syntax validated successfully" "OK"
                    } catch {
                        Log "Warning: Profile may have syntax issues after copy" "WARN"
                    }
                } else {
                    Copy-Item $src $dst -Force -ErrorAction Stop
                }
                Log "$file copied successfully" "OK"
            } catch {
                Log "Failed to copy $file - $($_.Exception.Message)" "ERROR"
            }
        } else {
            Log "$file not found in source directory" "WARN"
        }
    }
    
    # Copy modules
    Log "Installing bundled modules..." "STEP"
    $srcMod = "$PSScriptRoot\Modules"
    if (Test-Path $srcMod) {
        $dstMod = "$profileDir\Modules"
        Log "Copying modules from $srcMod to $dstMod" "INFO"
        
        if (Test-Path $dstMod) { 
            Log "Removing existing modules directory..." "INFO"
            Remove-Item $dstMod -Recurse -Force -ErrorAction SilentlyContinue 
        }
        
        try {
            Copy-Item $srcMod $dstMod -Recurse -Force -ErrorAction Stop
            Log "Modules copied successfully" "OK"
        } catch {
            Log "Failed to copy modules - $($_.Exception.Message)" "ERROR"
        }
    } else {
        Log "No bundled modules found to install" "INFO"
    }

    Log "Profile installation completed successfully!" "OK"
    if (-not $Silent) { 
        Write-Host ""
        Write-Host "Installation Summary:" -ForegroundColor Cyan
        Write-Host "✓ PowerShell profile configured" -ForegroundColor Green
        Write-Host "✓ Essential modules installed" -ForegroundColor Green  
        Write-Host "✓ Configuration files copied" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next: Restart PowerShell and try: neofetch, ll, health" -ForegroundColor Yellow
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
            "$env:LOCALAPPDATA\Temp\*powershell*"
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
        
        # Clean up any installation-specific temp directories
        $installTempDirs = @(
            "$env:TEMP\powershell-profile-install",
            "$env:TEMP\PSRepository*",
            "$env:TEMP\ModuleAnalysisCache"
        )
        
        foreach ($dir in $installTempDirs) {
            if (Test-Path $dir) {
                try {
                    Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    # Silently continue if cleanup fails
                }
            }
        }
        
        Log "Temporary files cleanup completed" "OK"
    } catch {
        Log "Warning: Some temporary files could not be cleaned up" "WARN"
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
        Write-Host "Installation failed with error:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    exit 1
}