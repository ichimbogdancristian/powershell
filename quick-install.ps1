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
            @{name="git"; id="Git.Git"},
            @{name="zoxide"; id="ajeetdsouza.zoxide"}
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
    
    # Detect correct PowerShell profile directory for both PowerShell versions
    $profileDir = Split-Path $PROFILE -Parent
    $psVersion = $PSVersionTable.PSVersion.Major
    
    # For PowerShell Core (7+), ensure we use the correct directory
    if ($psVersion -ge 7) {
        $coreProfileDir = Split-Path $PROFILE -Parent
        $winPSProfileDir = $coreProfileDir -replace 'PowerShell$', 'WindowsPowerShell'
        
        # If this script is being run from Windows PowerShell but we want PowerShell Core compatibility
        if ($profileDir -like "*WindowsPowerShell*") {
            $profileDir = $coreProfileDir
            Log "Detected PowerShell Core environment - using PowerShell directory" "INFO"
        }
    }
    
    Log "Profile directory: $profileDir" "INFO"
    Log "PowerShell version: $($PSVersionTable.PSVersion)" "INFO"
    
    # Check if user has existing PowerShell configurations
    $hasExistingConfig = $false
    $existingThemes = @()
    $existingScripts = @()
    
    if (Test-Path $profileDir) {
        # Check for existing oh-my-posh themes
        $themeFiles = Get-ChildItem "$profileDir\*.json" -ErrorAction SilentlyContinue
        if ($themeFiles) {
            $existingThemes = $themeFiles.Name
            $hasExistingConfig = $true
            Log "Found existing oh-my-posh themes: $($existingThemes -join ', ')" "INFO"
        }
        
        # Check for existing custom scripts
        $scriptFiles = Get-ChildItem "$profileDir\*.ps1" -Exclude "Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
        if ($scriptFiles) {
            $existingScripts = $scriptFiles.Name
            $hasExistingConfig = $true
            Log "Found existing PowerShell scripts: $($existingScripts -join ', ')" "INFO"
        }
    }
    
    if (-not (Test-Path $profileDir)) { 
        Log "Creating profile directory..." "INFO"
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null 
        Log "Profile directory created" "OK"
    }
    
    # Create comprehensive backup if existing configuration found
    if ($hasExistingConfig) {
        $backupDir = "$profileDir\backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
        Log "Creating backup of existing configuration..." "INFO"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Backup existing profile
        if (Test-Path $PROFILE) {
            Copy-Item $PROFILE "$backupDir\Microsoft.PowerShell_profile.ps1.bak" -ErrorAction SilentlyContinue
        }
        
        # Backup existing themes and scripts
        foreach ($theme in $existingThemes) {
            Copy-Item "$profileDir\$theme" "$backupDir\$theme" -ErrorAction SilentlyContinue
        }
        foreach ($script in $existingScripts) {
            Copy-Item "$profileDir\$script" "$backupDir\$script" -ErrorAction SilentlyContinue
        }
        
        Log "Backup created at: $backupDir" "OK"
    } else {
        # Standard backup for just the profile
        if (Test-Path $PROFILE) { 
            Log "Backing up existing profile..." "INFO"
            Copy-Item $PROFILE "$PROFILE.bak" -ErrorAction SilentlyContinue 
            Log "Profile backed up to $PROFILE.bak" "OK"
        }
    }
    
    # Copy files
    Log "Copying profile files..." "STEP"
    $filesToCopy = @("Microsoft.PowerShell_profile.ps1","oh-my-posh-default.json","verify-theme.ps1")
    foreach ($file in $filesToCopy) {
        $src = "$PSScriptRoot\$file"
        $dst = if($file -like "*.ps1"){$PROFILE}else{"$profileDir\$file"}
        
        # Special handling for oh-my-posh theme files
        if ($file -like "*.json" -and $hasExistingConfig) {
            # Don't overwrite existing theme if user has custom themes
            if ($existingThemes -contains $file) {
                Log "Skipping $file - user has existing theme (backed up)" "INFO"
                continue
            } else {
                # Copy with a different name to avoid conflicts
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
                $extension = [System.IO.Path]::GetExtension($file)
                $dst = "$profileDir\$baseName-default$extension"
                Log "Copying $file as $baseName-default$extension to avoid conflicts..." "INFO"
            }
        } else {
            Log "Copying $file..." "INFO"
        }
        
        if (Test-Path $src) { 
            try {
                # Use UTF8 encoding for PowerShell files to preserve emojis
                if ($file -like "*.ps1") {
                    $content = Get-Content $src -Raw -Encoding UTF8
                    [System.IO.File]::WriteAllText($dst, $content, [System.Text.Encoding]::UTF8)
                } else {
                    # For JSON and other files, preserve exact content
                    Copy-Item $src $dst -Force -ErrorAction Stop
                }
                Log "Copied $file successfully" "OK"
            } catch {
                Log "Failed to copy $file - $($_.Exception.Message)" "ERROR"
            }
        } else { 
            Log "Source file not found: $src" "WARN" 
        }
    }
    
    # Ensure Oh My Posh theme is available for cross-platform installations
    Log "Ensuring Oh My Posh theme availability across PowerShell versions..." "STEP"
    $themeFile = "oh-my-posh-default.json"
    $themeSrc = "$PSScriptRoot\$themeFile"
    
    if (Test-Path $themeSrc) {
        # Copy theme to both PowerShell directories if they exist
        $allProfileDirs = @($profileDir)
        
        # Add other PowerShell directories
        $documentsPath = [Environment]::GetFolderPath("MyDocuments")
        $additionalDirs = @(
            "$documentsPath\PowerShell",
            "$documentsPath\WindowsPowerShell"
        )
        
        foreach ($dir in $additionalDirs) {
            if ($dir -ne $profileDir -and (Test-Path $dir)) {
                $allProfileDirs += $dir
            }
        }
        
        foreach ($dir in $allProfileDirs) {
            $themeDst = "$dir\$themeFile"
            if (-not (Test-Path $themeDst) -or ($dir -eq $profileDir)) {
                try {
                    Copy-Item $themeSrc $themeDst -Force -ErrorAction Stop
                    Log "Oh My Posh theme copied to: $dir" "OK"
                } catch {
                    Log "Warning: Could not copy theme to $dir - $($_.Exception.Message)" "WARN"
                }
            }
        }
    }
    
    # Copy modules
    Log "Installing bundled modules..." "STEP"
    $srcMod = "$PSScriptRoot\Modules"
    if (Test-Path $srcMod) {
        $dstMod = "$profileDir\Modules"
        Log "Copying modules from $srcMod to $dstMod" "INFO"
        
        # If user has existing modules, be more careful
        if ($hasExistingConfig -and (Test-Path $dstMod)) {
            Log "Existing modules directory found - merging instead of replacing..." "INFO"
            
            # Copy each module individually to avoid overwriting user modules
            $srcModules = Get-ChildItem $srcMod -Directory
            foreach ($module in $srcModules) {
                $dstModulePath = "$dstMod\$($module.Name)"
                if (Test-Path $dstModulePath) {
                    Log "Module $($module.Name) already exists - updating with compatibility fixes..." "INFO"
                    # For Terminal-Icons, make sure we have the format file
                    if ($module.Name -eq "Terminal-Icons") {
                        $formatFile = "$($module.FullName)\0.11.0\Terminal-Icons.format.ps1xml"
                        $dstFormatFile = "$dstModulePath\0.11.0\Terminal-Icons.format.ps1xml"
                        if ((Test-Path $formatFile) -and (-not (Test-Path $dstFormatFile))) {
                            try {
                                Copy-Item $formatFile $dstFormatFile -Force -ErrorAction Stop
                                Log "Terminal-Icons format file added for compatibility" "OK"
                            } catch {
                                Log "Warning: Could not copy Terminal-Icons format file" "WARN"
                            }
                        }
                        # Also update the manifest if needed
                        $manifestFile = "$($module.FullName)\0.11.0\Terminal-Icons.psd1"
                        $dstManifestFile = "$dstModulePath\0.11.0\Terminal-Icons.psd1"
                        if (Test-Path $manifestFile) {
                            try {
                                Copy-Item $manifestFile $dstManifestFile -Force -ErrorAction Stop
                                Log "Terminal-Icons manifest updated" "OK"
                            } catch {
                                Log "Warning: Could not update Terminal-Icons manifest" "WARN"
                            }
                        }
                    }
                } else {
                    try {
                        Copy-Item $module.FullName $dstModulePath -Recurse -Force -ErrorAction Stop
                        Log "Module $($module.Name) copied successfully" "OK"
                    } catch {
                        Log "Failed to copy module $($module.Name) - $($_.Exception.Message)" "ERROR"
                    }
                }
            }
        } else {
            # Standard behavior for new installations
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
        }
    } else {
        Log "No bundled modules found to install" "INFO"
    }

    Log "Profile installation completed successfully!" "OK"
    
    # Cross-compatibility: Ensure profile is available in both PowerShell versions
    Log "Ensuring cross-compatibility between PowerShell versions..." "STEP"
    try {
        # Define both profile directories
        $documentsPath = [Environment]::GetFolderPath("MyDocuments")
        $coreProfileDir = "$documentsPath\PowerShell"
        $winPSProfileDir = "$documentsPath\WindowsPowerShell"
        
        # Always install to both versions if they exist or can be created
        $targetDirs = @()
        
        # Check for PowerShell Core (7+)
        if ((Get-Command pwsh -ErrorAction SilentlyContinue) -or (Test-Path "$env:ProgramFiles\PowerShell\*\pwsh.exe")) {
            $targetDirs += @{Path = $coreProfileDir; Name = "PowerShell Core"}
        }
        
        # Check for Windows PowerShell (5.1)
        if ((Get-Command powershell -ErrorAction SilentlyContinue) -or (Test-Path "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe")) {
            $targetDirs += @{Path = $winPSProfileDir; Name = "Windows PowerShell"}
        }
        
        foreach ($target in $targetDirs) {
            $targetPath = $target.Path
            $targetName = $target.Name
            
            # Skip if this is the directory we already installed to
            if ($targetPath -eq $profileDir) {
                Log "$targetName profile already installed (primary installation)" "OK"
                continue
            }
            
            Log "Installing profile for $targetName..." "INFO"
            
            # Create target directory if it doesn't exist
            if (-not (Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                Log "Created $targetName profile directory" "OK"
            }
            
            # Copy profile
            $targetProfile = "$targetPath\Microsoft.PowerShell_profile.ps1"
            try {
                # Backup existing profile if it exists
                if (Test-Path $targetProfile) {
                    Copy-Item $targetProfile "$targetProfile.bak" -Force -ErrorAction SilentlyContinue
                    Log "Backed up existing $targetName profile" "OK"
                }
                
                # Copy the profile with UTF8 encoding
                $content = Get-Content $PROFILE -Raw -Encoding UTF8
                [System.IO.File]::WriteAllText($targetProfile, $content, [System.Text.Encoding]::UTF8)
                Log "$targetName profile copied successfully" "OK"
            } catch {
                Log "Warning: Could not copy profile to $targetName - $($_.Exception.Message)" "WARN"
                continue
            }
            
            # Copy theme files
            try {
                $themeFiles = Get-ChildItem "$profileDir\*.json" -ErrorAction SilentlyContinue
                foreach ($theme in $themeFiles) {
                    Copy-Item $theme.FullName "$targetPath\$($theme.Name)" -Force -ErrorAction SilentlyContinue
                }
                if ($themeFiles.Count -gt 0) {
                    Log "$targetName theme files copied ($($themeFiles.Count) files)" "OK"
                }
            } catch {
                Log "Warning: Could not copy theme files to $targetName" "WARN"
            }
            
            # Copy modules
            try {
                if (Test-Path "$profileDir\Modules") {
                    $targetModules = "$targetPath\Modules"
                    if (Test-Path $targetModules) {
                        # Merge modules instead of replacing
                        $srcModules = Get-ChildItem "$profileDir\Modules" -Directory
                        foreach ($module in $srcModules) {
                            $dstModulePath = "$targetModules\$($module.Name)"
                            if (-not (Test-Path $dstModulePath)) {
                                Copy-Item $module.FullName $dstModulePath -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        }
                        Log "$targetName modules merged successfully" "OK"
                    } else {
                        Copy-Item "$profileDir\Modules" $targetModules -Recurse -Force -ErrorAction SilentlyContinue
                        Log "$targetName modules copied successfully" "OK"
                    }
                }
            } catch {
                Log "Warning: Could not copy modules to $targetName" "WARN"
            }
        }
        
        if ($targetDirs.Count -gt 1) {
            Log "Profile installed for both PowerShell versions for maximum compatibility" "OK"
        } elseif ($targetDirs.Count -eq 1) {
            Log "Profile installed for available PowerShell version" "OK"
        } else {
            Log "Warning: No PowerShell installations detected for cross-compatibility" "WARN"
        }
        
    } catch {
        Log "Warning: Could not ensure cross-compatibility - $($_.Exception.Message)" "WARN"
    }
    
    if (-not $Silent) { 
        Write-Host ""
        Write-Host "Installation Summary:" -ForegroundColor Cyan
        Write-Host "✓ PowerShell profile configured" -ForegroundColor Green
        Write-Host "✓ Essential modules installed" -ForegroundColor Green  
        Write-Host "✓ Configuration files copied" -ForegroundColor Green
        
        if ($hasExistingConfig) {
            Write-Host ""
            Write-Host "Existing Configuration Preserved:" -ForegroundColor Yellow
            if ($existingThemes.Count -gt 0) {
                Write-Host "✓ Oh-My-Posh themes: $($existingThemes -join ', ')" -ForegroundColor Green
            }
            if ($existingScripts.Count -gt 0) {
                Write-Host "✓ Custom scripts: $($existingScripts -join ', ')" -ForegroundColor Green
            }
            Write-Host "✓ Full backup created in: backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')" -ForegroundColor Green
        }
        
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