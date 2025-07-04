# ═══════════════════════════════════════════════════════════════════════════════
# Oh My Posh Theme Verification Script
# Author: Bogdan Ichim
# Verifies that the custom theme is properly installed and working
# ═══════════════════════════════════════════════════════════════════════════════

function Test-OhMyPoshTheme {
    Write-Host "Verifying Oh My Posh Theme Installation..." -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Gray
    
    # Check if Oh My Posh is installed
    $ohMyPoshPath = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if (-not $ohMyPoshPath) {
        Write-Host "❌ Oh My Posh is not installed or not in PATH" -ForegroundColor Red
        Write-Host "   Install with: winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "✅ Oh My Posh found at: $($ohMyPoshPath.Source)" -ForegroundColor Green
    
    # Check Oh My Posh version
    try {
        $version = & oh-my-posh version 2>$null
        Write-Host "✅ Oh My Posh version: $version" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not determine Oh My Posh version" -ForegroundColor Yellow
    }
    
    # Check for theme file in multiple locations
    $themeLocations = @(
        (Join-Path $PSScriptRoot "oh-my-posh-default.json"),
        (Join-Path (Split-Path $PROFILE -Parent) "oh-my-posh-default.json"),
        (Join-Path $env:USERPROFILE "Documents\PowerShell\oh-my-posh-default.json"),
        (Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\oh-my-posh-default.json")
    )
    
    $foundTheme = $null
    foreach ($location in $themeLocations) {
        if (Test-Path $location) {
            $foundTheme = $location
            Write-Host "✅ Theme found at: $location" -ForegroundColor Green
            break
        }
    }
    
    if (-not $foundTheme) {
        Write-Host "❌ oh-my-posh-default.json theme file not found in any expected location" -ForegroundColor Red
        Write-Host "   Expected locations:" -ForegroundColor Yellow
        foreach ($location in $themeLocations) {
            Write-Host "   - $location" -ForegroundColor Gray
        }
        return $false
    }
    
    # Validate theme file content
    try {
        $themeContent = Get-Content $foundTheme | ConvertFrom-Json
        if ($themeContent.blocks -and $themeContent.version) {
            Write-Host "✅ Theme file is valid JSON with proper structure" -ForegroundColor Green
            Write-Host "   - Version: $($themeContent.version)" -ForegroundColor Gray
            Write-Host "   - Blocks: $($themeContent.blocks.Count)" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Theme file exists but may have structural issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Theme file is corrupted or invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test theme initialization
    Write-Host "`nTesting theme initialization..." -ForegroundColor Cyan
    try {
        $initScript = & oh-my-posh init pwsh --config $foundTheme 2>$null
        if ($initScript) {
            Write-Host "✅ Theme initialization script generated successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Theme initialization returned empty script" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Theme initialization failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Check if fonts support icons
    Write-Host "`nFont and Icon Support:" -ForegroundColor Cyan
    $testIcons = @("", "", "", "", "")
    $iconsSupported = $true
    
    foreach ($icon in $testIcons) {
        try {
            # This is a basic test - actual rendering depends on terminal and font
            $iconBytes = [System.Text.Encoding]::UTF8.GetBytes($icon)
            if ($iconBytes.Length -lt 3) {
                $iconsSupported = $false
                break
            }
        } catch {
            $iconsSupported = $false
            break
        }
    }
    
    if ($iconsSupported) {
        Write-Host "✅ Font appears to support Unicode icons" -ForegroundColor Green
        Write-Host "   Test icons: $($testIcons -join ' ')" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Font may not fully support Nerd Font icons" -ForegroundColor Yellow
        Write-Host "   Consider installing FiraCode Nerd Font or similar" -ForegroundColor Gray
    }
    
    # Final summary
    Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
    Write-Host "Theme Verification Complete!" -ForegroundColor Green
    Write-Host "To see the theme in action, restart PowerShell or run:" -ForegroundColor Yellow
    Write-Host "  oh-my-posh init pwsh --config '$foundTheme' | Invoke-Expression" -ForegroundColor Cyan
    
    return $true
}

# Run verification if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-OhMyPoshTheme
}
