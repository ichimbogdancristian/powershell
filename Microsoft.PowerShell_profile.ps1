# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Optimized Version
# Author: Bogdan Ichim
# Features: Oh My Posh, Linux aliases, Enhanced completion, System monitoring
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Module Imports
# ═══════════════════════════════════════════════════════════════════════════════

# Import essential modules with error handling
$modules = @("PSReadLine", "posh-git", "Terminal-Icons")
foreach ($module in $modules) {
    try {
        Import-Module $module -Force -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if module not available
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PSReadLine Configuration
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -MaximumHistoryCount 4000
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
    
    # Enable prediction for PSReadLine 2.1+
    $psReadLineVersion = (Get-Module PSReadLine).Version
    if ($psReadLineVersion -ge [version]"2.1.0") {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    }
    
    # Colors
    try {
        Set-PSReadLineOption -Colors @{
            Command   = 'Cyan'
            Parameter = 'Gray'
            Operator  = 'White'
            Variable  = 'Green'
            String    = 'Yellow'
            Number    = 'Red'
            Type      = 'DarkCyan'
            Comment   = 'DarkGreen'
        }
    } catch {
        # Ignore color errors for older versions
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Oh My Posh Configuration
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themeFile = Join-Path (Split-Path $PROFILE -Parent) "oh-my-posh-default.json"
    if (Test-Path $themeFile) {
        oh-my-posh init pwsh --config $themeFile | Invoke-Expression
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Zoxide Integration (Smart Directory Navigation)
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ═══════════════════════════════════════════════════════════════════════════════
# Linux-like Aliases and Functions
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced directory listing
function Get-ChildItemColorized {
    param([string]$Path = ".")
    Get-ChildItem $Path @args | Format-Table -AutoSize
}

function Get-ChildItemAll {
    param([string]$Path = ".")
    Get-ChildItem $Path -Force @args | Format-Table -AutoSize
}

function Get-ChildItemLong {
    param([string]$Path = ".")
    Get-ChildItem $Path @args | Format-Table Name, Mode, Length, LastWriteTime -AutoSize
}

# System information
function Get-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
    
    Write-Host "System Information" -ForegroundColor Cyan
    Write-Host "OS: $($os.Caption) $($os.Version)" -ForegroundColor White
    Write-Host "CPU: $($cpu.Name)" -ForegroundColor White
    Write-Host "RAM: $([math]::Round($memory.Sum / 1GB, 2)) GB" -ForegroundColor White
    Write-Host "Uptime: $((Get-Date) - $os.LastBootUpTime)" -ForegroundColor White
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
}

function Get-SystemHealth {
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
    $memory = Get-CimInstance Win32_OperatingSystem
    $disk = Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3
    
    Write-Host "System Health" -ForegroundColor Cyan
    Write-Host "CPU Usage: $([math]::Round($cpu.CounterSamples.CookedValue, 1))%" -ForegroundColor White
    Write-Host "Memory Usage: $([math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 1))%" -ForegroundColor White
    
    foreach ($drive in $disk) {
        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
        Write-Host "Drive $($drive.DeviceID) Free: $freePercent%" -ForegroundColor White
    }
}

# Network utilities
function Get-PublicIP {
    try {
        $oldProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5
        $ProgressPreference = $oldProgress
        Write-Host "Public IP: $ip" -ForegroundColor Green
    } catch {
        Write-Host "Could not retrieve public IP" -ForegroundColor Red
    }
}

function Test-InternetConnection {
    Test-NetConnection google.com -Port 80 -InformationLevel Quiet
}

# Git shortcuts
function Get-GitStatus { git status @args }
function Get-GitLog { git log --oneline -10 @args }

# Process management
function Get-ProcessesByName {
    param([string]$Name)
    Get-Process | Where-Object ProcessName -like "*$Name*" | Format-Table -AutoSize
}

# Help function
function Get-ProfileHelp {
    Write-Host "PowerShell Enhanced Profile - Available Commands" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Directory Navigation:" -ForegroundColor Yellow
    Write-Host "  ll [path]     - Enhanced directory listing" -ForegroundColor White
    Write-Host "  la [path]     - Show all files (including hidden)" -ForegroundColor White
    Write-Host "  lsl [path]    - Long format listing" -ForegroundColor White
    Write-Host "  z [dir]       - Smart directory jump (if zoxide installed)" -ForegroundColor White
    Write-Host ""
    Write-Host "System Information:" -ForegroundColor Yellow
    Write-Host "  neofetch      - System information display" -ForegroundColor White
    Write-Host "  health        - System health check" -ForegroundColor White
    Write-Host "  myip          - Show public IP address" -ForegroundColor White
    Write-Host "  testnet       - Test internet connection" -ForegroundColor White
    Write-Host ""
    Write-Host "Git Shortcuts:" -ForegroundColor Yellow
    Write-Host "  gs            - Git status" -ForegroundColor White
    Write-Host "  gl            - Git log (last 10 commits)" -ForegroundColor White
    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Yellow
    Write-Host "  grep          - Search text (Select-String)" -ForegroundColor White
    Write-Host "  which         - Find command location" -ForegroundColor White
    Write-Host "  ps-name       - Find processes by name" -ForegroundColor White
    Write-Host "  help-profile  - Show this help" -ForegroundColor White
}

# ═══════════════════════════════════════════════════════════════════════════════
# Aliases
# ═══════════════════════════════════════════════════════════════════════════════

Set-Alias -Name ll -Value Get-ChildItemColorized -Force
Set-Alias -Name la -Value Get-ChildItemAll -Force
Set-Alias -Name lsl -Value Get-ChildItemLong -Force
Set-Alias -Name grep -Value Select-String -Force
Set-Alias -Name which -Value Get-Command -Force
Set-Alias -Name neofetch -Value Get-SystemInfo -Force
Set-Alias -Name health -Value Get-SystemHealth -Force
Set-Alias -Name myip -Value Get-PublicIP -Force
Set-Alias -Name testnet -Value Test-InternetConnection -Force
Set-Alias -Name gs -Value Get-GitStatus -Force
Set-Alias -Name gl -Value Get-GitLog -Force
Set-Alias -Name ps-name -Value Get-ProcessesByName -Force
Set-Alias -Name help-profile -Value Get-ProfileHelp -Force

# ═══════════════════════════════════════════════════════════════════════════════
# Welcome Message
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "PowerShell Enhanced Profile Loaded" -ForegroundColor Green
Write-Host "Run 'help-profile' for available commands" -ForegroundColor DarkGray