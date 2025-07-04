# ═══════════════════════════════════════════════════════════════════════════════
# Simple PowerShell Profile Installer
# Author: Bogdan Ichim
# Minimal installer for fresh systems
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "PowerShell Enhanced Profile - Simple Installer" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor Gray

# Set execution policy
try {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "✓ Execution policy set" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Ensure profile directory exists
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "✓ Created profile directory: $profileDir" -ForegroundColor Green
} else {
    Write-Host "✓ Profile directory exists: $profileDir" -ForegroundColor Green
}

# Copy profile file
$sourceProfile = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"
if (Test-Path $sourceProfile) {
    Copy-Item $sourceProfile $PROFILE -Force
    Write-Host "✓ Copied PowerShell profile" -ForegroundColor Green
} else {
    Write-Host "✗ Source profile not found: $sourceProfile" -ForegroundColor Red
    exit 1
}

# Copy theme file
$sourceTheme = Join-Path $PSScriptRoot "oh-my-posh-default.json"
$targetTheme = Join-Path $profileDir "oh-my-posh-default.json"
if (Test-Path $sourceTheme) {
    Copy-Item $sourceTheme $targetTheme -Force
    Write-Host "✓ Copied Oh My Posh theme" -ForegroundColor Green
} else {
    Write-Host "✗ Source theme not found: $sourceTheme" -ForegroundColor Red
    exit 1
}

# Copy verification script
$sourceVerify = Join-Path $PSScriptRoot "verify-theme.ps1"
$targetVerify = Join-Path $profileDir "verify-theme.ps1"
if (Test-Path $sourceVerify) {
    Copy-Item $sourceVerify $targetVerify -Force
    Write-Host "✓ Copied verification script" -ForegroundColor Green
}

# Check for Oh My Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "✓ Oh My Posh is installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Oh My Posh not found" -ForegroundColor Yellow
    Write-Host "  Install with: winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Gray
    Write-Host "  Or visit: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Gray
}

# Install to both PowerShell versions if they exist
$otherProfileDirs = @()
if ($profileDir -like "*PowerShell*") {
    $winPSDir = $profileDir -replace 'PowerShell$', 'WindowsPowerShell'
    if (Test-Path $winPSDir -PathType Container) {
        $otherProfileDirs += $winPSDir
    }
} elseif ($profileDir -like "*WindowsPowerShell*") {
    $coreDir = $profileDir -replace 'WindowsPowerShell$', 'PowerShell'
    if (Test-Path $coreDir -PathType Container) {
        $otherProfileDirs += $coreDir
    }
}

foreach ($dir in $otherProfileDirs) {
    try {
        Copy-Item $PROFILE "$dir\Microsoft.PowerShell_profile.ps1" -Force
        Copy-Item $targetTheme "$dir\oh-my-posh-default.json" -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Installed to: $dir" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not install to: $dir" -ForegroundColor Yellow
    }
}

Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
Write-Host "✓ Profile: $PROFILE" -ForegroundColor Green
Write-Host "✓ Theme: $targetTheme" -ForegroundColor Green
Write-Host "✓ Verification: $targetVerify" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Restart PowerShell" -ForegroundColor Gray
Write-Host "2. Run verification: .$targetVerify" -ForegroundColor Gray
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "3. Install Oh My Posh: winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Gray
}

Write-Host "`nInstallation completed!" -ForegroundColor Green
