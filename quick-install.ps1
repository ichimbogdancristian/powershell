# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Ultra Quick Install
# Author: Bogdan Ichim
# One-liner installer for PowerShell enhanced profile
# ═══════════════════════════════════════════════════════════════════════════════

param([switch]$Silent)

# Suppress all errors and warnings for silent operation
if ($Silent) { $ErrorActionPreference = "SilentlyContinue"; $WarningPreference = "SilentlyContinue" }

function Log($msg, $type="INFO") {
    if (-not $Silent) { Write-Host "[$type] $msg" -ForegroundColor $(if($type -eq "OK"){"Green"}elseif($type -eq "WARN"){"Yellow"}else{"Cyan"}) }
}

try {
    # Set execution policy
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force 2>$null

    # Install essential modules
    "PSReadLine","posh-git","Terminal-Icons" | ForEach-Object {
        if (-not (Get-Module $_ -ListAvailable -ErrorAction SilentlyContinue)) {
            Log "Installing $_..."
            Install-Module $_ -Force -AllowClobber -Scope CurrentUser -ErrorAction SilentlyContinue
        }
        Log "$_ ready" "OK"
    }

    # Install tools via winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        @(@{n="oh-my-posh";i="JanDeDobbeleer.OhMyPosh"},@{n="git";i="Git.Git"}) | ForEach-Object {
            if (-not (Get-Command $_.n -ErrorAction SilentlyContinue)) {
                Log "Installing $($_.n)..."
                winget install $_.i --silent --accept-source-agreements --accept-package-agreements 2>$null | Out-Null
            }
            Log "$($_.n) ready" "OK"
        }
    }

    # Setup profile
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    
    # Backup existing
    if (Test-Path $PROFILE) { Copy-Item $PROFILE "$PROFILE.bak" -ErrorAction SilentlyContinue }
    
    # Copy files
    @("Microsoft.PowerShell_profile.ps1","oh-my-posh-default.json") | ForEach-Object {
        $src = "$PSScriptRoot\$_"
        $dst = if($_ -like "*.ps1"){$PROFILE}else{"$profileDir\$_"}
        if (Test-Path $src) { Copy-Item $src $dst -Force -ErrorAction SilentlyContinue }
    }
    
    # Copy modules
    $srcMod = "$PSScriptRoot\Modules"
    if (Test-Path $srcMod) {
        $dstMod = "$profileDir\Modules"
        if (Test-Path $dstMod) { Remove-Item $dstMod -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $srcMod $dstMod -Recurse -Force -ErrorAction SilentlyContinue
    }

    Log "Profile installed successfully!" "OK"
    if (-not $Silent) { Write-Host "Restart PowerShell to activate. Try: neofetch, ll, health" -ForegroundColor Green }
    
} catch {
    Log "Installation failed: $($_.Exception.Message)" "WARN"
    exit 1
}
