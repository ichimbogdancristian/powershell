# Helper: Get-DocumentsPath (returns first available Documents folder)
function Get-DocumentsPath {
    $paths = @()
    try { $paths += [Environment]::GetFolderPath("MyDocuments") } catch {}
    try { if ($env:USERPROFILE) { $paths += Join-Path $env:USERPROFILE 'Documents' } } catch {}
    try { if ($env:OneDrive) { $paths += Join-Path $env:OneDrive 'Documents' } } catch {}
    foreach ($p in $paths | Where-Object { $_ -and (Test-Path $_) }) {
        if ((Test-Path $p) -and (Test-Path $p -PathType Container)) {
            return $p
        }
    }
    return $null
}
# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Optimized Quick Install
# Author: Bogdan Ichim
# Compact, portable installation script for PowerShell enhanced profile
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [switch]$Silent,
    [switch]$TestCompatibility,
    [switch]$VerifyInstallation
)

# Configure output preferences
$ErrorActionPreference = if ($Silent) { "SilentlyContinue" } else { "Continue" }
$WarningPreference = if ($Silent) { "SilentlyContinue" } else { "Continue" }
$ProgressPreference = 'SilentlyContinue'  # Suppress all progress bars

# ═══════════════════════════════════════════════════════════════════════════════
# Core Functions
# ═══════════════════════════════════════════════════════════════════════════════

function Write-Status {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $color = switch ($Level) {
        "OK"    { "Green" }
        "STEP"  { "Cyan" }
        "INFO"  { "White" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "Gray" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
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
    Write-Status "Installing required modules..." "STEP"
    $modules = @("PSReadLine", "posh-git", "oh-my-posh")
    foreach ($module in $modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Status "Installing $module..." "INFO"
            try {
                Install-Module $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Status "$module installed successfully" "OK"
            } catch {
                Write-Status "Failed to install $module" "WARN"
            }
        } else {
            Write-Status "$module already available" "OK"
        }
    }
}

function Install-RequiredTools {
    Write-Status "Installing required tools..." "STEP"
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "winget not available, skipping tool installation" "WARN"
        return
    }
    
    $tools = @(
        @{name="oh-my-posh"; id="JanDeDobbeleer.OhMyPosh"},
        @{name="git"; id="Git.Git"}
    )
    
    foreach ($tool in $tools) {
        if (-not (Get-Command $tool.name -ErrorAction SilentlyContinue)) {
            Write-Status "Installing $($tool.name)..." "INFO"
            try {
                $process = Start-Process winget -ArgumentList "install", $tool.id, "--silent", "--accept-source-agreements", "--accept-package-agreements" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq -1978335189) {
                    Write-Status "$($tool.name) installed successfully" "OK"
                }
            } catch {
                Write-Status "Failed to install $($tool.name)" "WARN"
            }
        } else {
            Write-Status "$($tool.name) already available" "OK"
        }
    }
}

function Test-SystemCompatibility {
    Write-Status "Testing system compatibility..." "STEP"
    
    # Basic compatibility checks
    $issues = @()
    
    if (-not (Get-DocumentsPath)) {
        $issues += "No writable Documents folder found"
    }
    
    if (-not (Get-Command powershell -ErrorAction SilentlyContinue) -and 
        -not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        $issues += "No PowerShell installations found"
    }
    
    if ($issues.Count -eq 0) {
        Write-Status "System compatibility check passed" "OK"
        return $true
    } else {
        Write-Status "Compatibility issues: $($issues -join ', ')" "ERROR"
        return $false
    }
}

function Install-ProfileContent {
    param($ProfileDirs)
    
    Write-Status "Installing profile content..." "STEP"
    
    # Get current script directory for source files
    $scriptDir = $PSScriptRoot
    
    foreach ($profileDir in $ProfileDirs) {
        Write-Status "Configuring $($profileDir.Name)..." "INFO"
        
        # Ensure profile directory exists
        if (-not (Test-Path $profileDir.Path)) {
            New-Item -ItemType Directory -Path $profileDir.Path -Force | Out-Null
        }
        
        # Copy profile file
        $profileSrc = Join-Path $scriptDir "Microsoft.PowerShell_profile.ps1"
        if (Test-Path $profileSrc) {
            Copy-Item $profileSrc $profileDir.ProfileFile -Force | Out-Null
            Write-Status "Profile copied for $($profileDir.Name)" "OK"
        } else {
            Write-Status "Profile source file not found" "ERROR"
        }
        
        # Copy theme file to standard location (user profile directory)
        $themeSrc = Join-Path $scriptDir "oh-my-posh-default.json"
        if (Test-Path $themeSrc) {
            $themeDst = Join-Path $profileDir.Path "oh-my-posh-default.json"
            Copy-Item $themeSrc $themeDst -Force | Out-Null
            Write-Status "Theme copied for $($profileDir.Name)" "OK"
        }
    }
}

function Test-Installation {
    param($ProfileDirs)
    
    Write-Status "Verifying installation..." "STEP"
    
    $success = $true
    foreach ($profileDir in $ProfileDirs) {
        if (Test-Path $profileDir.ProfileFile) {
            Write-Status "$($profileDir.Name): Profile installed" "OK"
        } else {
            Write-Status "$($profileDir.Name): Profile missing" "ERROR"
            $success = $false
        }
    }
    
    return $success
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Installation Logic
# ═══════════════════════════════════════════════════════════════════════════════

try {
    # Handle special modes
    if ($TestCompatibility) {
        $result = Test-SystemCompatibility
        if ($result) {
            exit 0
        } else {
            exit 1
        }
    }
    
    Write-Status "Starting PowerShell profile installation..." "STEP"
    
    # Run compatibility test
    if (-not (Test-SystemCompatibility)) {
        throw "System compatibility test failed"
    }
    
    # Set execution policy
    Write-Status "Setting execution policy..." "INFO"
    try {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Status "Could not set execution policy" "WARN"
    }
    
    # Get PowerShell directories
    $profileDirs = Get-ProfileDirectories
    Write-Status "Found $($profileDirs.Count) PowerShell installation(s)" "INFO"
    
    # Install modules and tools
    Install-RequiredModules
    Install-RequiredTools
    
    # Refresh PATH to pick up new tools
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Install profile content
    Install-ProfileContent -ProfileDirs $profileDirs
    
    # Handle verification mode
    if ($VerifyInstallation) {
        $result = Test-Installation -ProfileDirs $profileDirs
        if ($result) {
            exit 0
        } else {
            exit 1
        }
    }
    
    # Verify installation
    $verificationResult = Test-Installation -ProfileDirs $profileDirs
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "                INSTALLATION COMPLETE" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Installed for:" -ForegroundColor Yellow
        foreach ($profileDir in $profileDirs) {
            $status = if (Test-Path $profileDir.ProfileFile) { "✓" } else { "✗" }
            Write-Host "  $status $($profileDir.Name)" -ForegroundColor $(if ($status -eq "✓") { "Green" } else { "Red" })
        }
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Restart PowerShell" -ForegroundColor White
        Write-Host "2. Try: ll, health, help-profile" -ForegroundColor White
        Write-Host ""
    }
    
    if ($verificationResult) {
        exit 0
    } else {
        exit 1
    }
    
} catch {
    Write-Status "Installation failed: $($_.Exception.Message)" "ERROR"
    if (-not $Silent) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "                INSTALLATION FAILED" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Run as Administrator" -ForegroundColor White
        Write-Host "2. Check internet connection" -ForegroundColor White
        Write-Host "3. Verify PowerShell execution policy" -ForegroundColor White
        Write-Host ""
    }
    exit 1
}