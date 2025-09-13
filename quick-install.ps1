# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Ultra Quick Install
# Author: Bogdan Ichim
# Always overwrites existing profiles with enhanced PowerShell configuration
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
    
    # Try multiple methods to get Documents folder (handle OneDrive redirection and localization)
    # Priority: OneDrive folders first, then system folders
    $documentsPath = $null
    $documentsPaths = @(
        "$($envVars.OneDrive)\Documents",
        "$($envVars.OneDrive)\Documente",  # Romanian localization
        "$($envVars.OneDrive)\Dokumenty",  # Polish localization
        "$($envVars.OneDrive)\Документы",  # Russian localization
        "$($envVars.OneDriveConsumer)\Documents",
        "$($envVars.OneDriveConsumer)\Documente",
        "$($envVars.OneDriveCommercial)\Documents",
        "$($envVars.OneDriveCommercial)\Documente",
        [Environment]::GetFolderPath("MyDocuments"),
        "$($envVars.UserProfile)\Documents"
    )
    
    # Check which Documents folder is actually writable
    foreach ($path in $documentsPaths) {
        if ($path -and (Test-Path $path)) {
            # Test if we can create a directory in this path
            try {
                $testDir = "$path\ps-test-$(Get-Random)"
                New-Item -Path $testDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Remove-Item $testDir -Force -ErrorAction SilentlyContinue
                $documentsPath = $path
                Log "Writable Documents folder found: $documentsPath" "OK"
                break
            } catch {
                Log "Documents folder not writable: $path" "WARN"
                continue
            }
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
    
    Log "Overwriting existing PowerShell profiles (no backups)..." "CLEAN"
    
    foreach ($profileDir in $ProfileDirs) {
        $path = $profileDir.Path
        $name = $profileDir.Name
        
        if (Test-Path $path) {
            Log "Overwriting existing $name profile: $path" "CLEAN"
            
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
    
    # Always clean and overwrite existing profiles
    Clear-OldProfiles -ProfileDirs $allProfileDirs
    
    # Set execution policy
    Log "Setting execution policy to RemoteSigned..." "STEP"
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($currentPolicy -ne "RemoteSigned") {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
            Log "Execution policy updated successfully" "OK"
        } else {
            Log "Execution policy already set correctly" "OK"
        }
    } catch {
        # Check if it's just a path issue but policy is actually set correctly
        $actualPolicy = try { Get-ExecutionPolicy -Scope CurrentUser } catch { "Unknown" }
        if ($actualPolicy -eq "RemoteSigned") {
            Log "Execution policy is already set correctly" "OK"
        } else {
            Log "Warning: Could not verify/set execution policy - continuing anyway" "WARN"
        }
    }

    # Install essential modules
    Log "Installing essential PowerShell modules..." "STEP"
    $modules = @("PSReadLine","posh-git","Terminal-Icons")
    foreach ($module in $modules) {
        Log "Checking module: $module" "INFO"
        if (-not (Get-Module $module -ListAvailable -ErrorAction SilentlyContinue)) {
            Log "Installing $module..." "INFO"
            try {
                # Use a job with timeout to prevent hanging
                $job = Start-Job -ScriptBlock {
                    param($ModuleName)
                    Install-Module $ModuleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop -Confirm:$false
                } -ArgumentList $module
                
                # Wait for job with 60 second timeout
                $result = Wait-Job $job -Timeout 60
                if ($result) {
                    Receive-Job $job -ErrorAction SilentlyContinue
                    Log "$module installed successfully" "OK"
                } else {
                    Stop-Job $job -ErrorAction SilentlyContinue
                    throw "Installation timeout after 60 seconds"
                }
                Remove-Job $job -Force -ErrorAction SilentlyContinue
            } catch {
                Log "Failed to install $module - $($_.Exception.Message)" "ERROR"
                Log "Continuing with installation..." "WARN"
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
                    # Use timeout for winget installations
                    $job = Start-Job -ScriptBlock {
                        param($ToolId)
                        $process = Start-Process winget -ArgumentList "install", $ToolId, "--silent", "--accept-source-agreements", "--accept-package-agreements" -Wait -PassThru -NoNewWindow
                        return $process.ExitCode
                    } -ArgumentList $tool.id
                    
                    $result = Wait-Job $job -Timeout 120  # 2 minute timeout for winget
                    if ($result) {
                        $exitCode = Receive-Job $job
                        if ($exitCode -eq 0) {
                            Log "$($tool.name) installed successfully" "OK"
                        } elseif ($exitCode -eq -1978335189) {
                            # Common winget exit code for "already installed" or "no upgrade needed"
                            Log "$($tool.name) is already up to date" "OK"
                        } else {
                            Log "$($tool.name) installation completed with exit code: $exitCode" "WARN"
                        }
                    } else {
                        Stop-Job $job -ErrorAction SilentlyContinue
                        Log "$($tool.name) installation timeout after 2 minutes" "WARN"
                    }
                    Remove-Job $job -Force -ErrorAction SilentlyContinue
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
            Log "Target path for ${targetName}: $targetPath" "INFO"
            if (-not (Test-Path $targetPath)) { 
                Log "Creating profile directory for $targetName..." "INFO"
                
                # Ensure parent directory exists first
                $parentDir = Split-Path $targetPath -Parent
                if ($parentDir -and -not (Test-Path $parentDir)) {
                    Log "Creating parent directory: $parentDir" "INFO"
                    New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
                }
                
                # Create the target directory
                $dirResult = New-Item -ItemType Directory -Path $targetPath -Force -ErrorAction Stop
                
                # Small delay to ensure filesystem sync
                Start-Sleep -Milliseconds 100
                
                # Verify directory was created with multiple checks
                $verificationAttempts = 0
                $maxAttempts = 3
                $dirExists = $false
                
                do {
                    $verificationAttempts++
                    $dirExists = (Test-Path $targetPath -PathType Container)
                    if (-not $dirExists) {
                        Start-Sleep -Milliseconds 200
                    }
                } while (-not $dirExists -and $verificationAttempts -lt $maxAttempts)
                
                if ($dirExists) {
                    Log "Profile directory created successfully: $targetPath" "OK"
                } else {
                    throw "Directory creation verification failed after $maxAttempts attempts. Path: $targetPath"
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