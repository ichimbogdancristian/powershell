# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Profile Installation Test Script
# Author: Bogdan Ichim
# Tests fresh installation without existing profile
# ═══════════════════════════════════════════════════════════════════════════════

param([switch]$Clean)

Write-Host "PowerShell Profile Installation Test" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor Gray

# If -Clean flag is used, remove existing profile for testing
if ($Clean) {
    Write-Host "Cleaning existing profile for fresh test..." -ForegroundColor Yellow
    
    # Backup existing profile if it exists
    if (Test-Path $PROFILE) {
        $backupName = "$PROFILE.backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
        Copy-Item $PROFILE $backupName
        Write-Host "Existing profile backed up to: $backupName" -ForegroundColor Green
        Remove-Item $PROFILE -Force
    }
    
    # Remove theme file if it exists
    $profileDir = Split-Path $PROFILE -Parent
    $themeFile = Join-Path $profileDir "oh-my-posh-default.json"
    if (Test-Path $themeFile) {
        Remove-Item $themeFile -Force
        Write-Host "Removed existing theme file" -ForegroundColor Yellow
    }
}

# Check current state
Write-Host "`nCurrent State:" -ForegroundColor Cyan
Write-Host "Profile path: $PROFILE" -ForegroundColor Gray
Write-Host "Profile exists: $(Test-Path $PROFILE)" -ForegroundColor Gray
Write-Host "Profile directory: $(Split-Path $PROFILE -Parent)" -ForegroundColor Gray
Write-Host "Directory exists: $(Test-Path (Split-Path $PROFILE -Parent))" -ForegroundColor Gray

# Test installation
Write-Host "`nRunning installation..." -ForegroundColor Cyan
try {
    & "$PSScriptRoot\quick-install.ps1" -Verbose
    Write-Host "Installation completed!" -ForegroundColor Green
} catch {
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host "`nVerifying installation..." -ForegroundColor Cyan
$profileDir = Split-Path $PROFILE -Parent
$themeFile = Join-Path $profileDir "oh-my-posh-default.json"

Write-Host "✓ Profile exists: $(Test-Path $PROFILE)" -ForegroundColor $(if (Test-Path $PROFILE) {'Green'} else {'Red'})
Write-Host "✓ Theme file exists: $(Test-Path $themeFile)" -ForegroundColor $(if (Test-Path $themeFile) {'Green'} else {'Red'})
Write-Host "✓ Verify script exists: $(Test-Path (Join-Path $profileDir 'verify-theme.ps1'))" -ForegroundColor $(if (Test-Path (Join-Path $profileDir 'verify-theme.ps1')) {'Green'} else {'Red'})

# Test profile loading
Write-Host "`nTesting profile loading..." -ForegroundColor Cyan
try {
    # Create a new PowerShell process to test the profile
    $testScript = @"
try {
    . '$PROFILE'
    Write-Host 'Profile loaded successfully!' -ForegroundColor Green
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host 'Oh My Posh is available' -ForegroundColor Green
    } else {
        Write-Host 'Oh My Posh is not installed' -ForegroundColor Yellow
    }
} catch {
    Write-Host "Profile loading failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}
"@
    
    $result = powershell -NoProfile -Command $testScript
    Write-Host $result
} catch {
    Write-Host "Profile test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart PowerShell" -ForegroundColor Gray
Write-Host "2. Run: .\verify-theme.ps1" -ForegroundColor Gray
Write-Host "3. Install Oh My Posh if needed: winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Gray
