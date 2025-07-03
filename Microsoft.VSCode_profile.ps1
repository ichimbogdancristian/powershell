# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Profile for VS Code - Enhanced Linux-like Experience
# Author: Bogdan
# This profile is specifically for PowerShell running in VS Code's integrated terminal
# ═══════════════════════════════════════════════════════════════════════════════

# Source the main profile if it exists
$mainProfile = Join-Path (Split-Path $PROFILE -Parent) "Microsoft.PowerShell_profile.ps1"
if (Test-Path $mainProfile) {
    Write-Host "Loading main PowerShell profile..." -ForegroundColor Green
    . $mainProfile
} else {
    Write-Host "Main profile not found at: $mainProfile" -ForegroundColor Yellow
    Write-Host "Please ensure Microsoft.PowerShell_profile.ps1 exists in the same directory." -ForegroundColor Yellow
}

# VS Code specific customizations
if ($env:TERM_PROGRAM -eq "vscode") {
    # Disable Oh My Posh animations in VS Code for better performance
    $env:POSH_DISABLE_ANIMATIONS = $true
    
    # VS Code specific functions
    function Open-InCode {
        param([string]$Path = ".")
        code $Path
    }
    
    function Open-Settings {
        code $env:APPDATA\Code\User\settings.json
    }
    
    function Open-Keybindings {
        code $env:APPDATA\Code\User\keybindings.json
    }
    
    # Set aliases for VS Code functions
    Set-Alias -Name c -Value Open-InCode
    Set-Alias -Name settings -Value Open-Settings
    Set-Alias -Name keybindings -Value Open-Keybindings
    
    # VS Code terminal optimizations
    $PSReadLineOptions = @{
        PredictionSource = "History"
        PredictionViewStyle = "InlineView"  # Less intrusive in VS Code
        ShowToolTips = $true
        CompletionQueryItems = 50  # Reduced for better performance
    }
    Set-PSReadLineOption @PSReadLineOptions
    
    Write-Host "VS Code PowerShell Profile loaded successfully!" -ForegroundColor Green
    Write-Host "Additional commands: c (open in code), settings, keybindings" -ForegroundColor DarkGray
}

# Override the welcome message for VS Code to be more compact
function Show-VSCodeWelcomeMessage {
    Write-Host "┌─── PowerShell Enhanced Profile (VS Code) ───┐" -ForegroundColor Blue
    Write-Host "│ Welcome, $env:USERNAME! $(Get-Date -Format 'HH:mm')" -ForegroundColor Cyan
    Write-Host "│ Location: $(Split-Path (Get-Location) -Leaf)" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Blue
    Write-Host ""
}

# Replace the main welcome message with VS Code version if in VS Code
if ($env:TERM_PROGRAM -eq "vscode") {
    # Override the main welcome message
    function Show-WelcomeMessage {
        Show-VSCodeWelcomeMessage
    }
}
