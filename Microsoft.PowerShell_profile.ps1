# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Profile - Enhanced Linux-like Experience
# Author: Bogdan
# Features: Oh My Posh, Zoxide, Linux aliases, Advanced completion, Custom prompt
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Module Imports
# ═══════════════════════════════════════════════════════════════════════════════

# Import required modules
Import-Module PSReadLine -Force
Import-Module posh-git -Force
Import-Module Terminal-Icons -Force

# ═══════════════════════════════════════════════════════════════════════════════
# PSReadLine Configuration (Enhanced History & Autocompletion)
# ═══════════════════════════════════════════════════════════════════════════════

# Enable advanced history search
Set-PSReadLineOption -PredictionSource History
# Use different prediction styles based on environment
if ($env:TERM_PROGRAM -eq "vscode") {
    Set-PSReadLineOption -PredictionViewStyle InlineView  # Less intrusive in VS Code
    Set-PSReadLineOption -CompletionQueryItems 50  # Reduced for better performance
} else {
    Set-PSReadLineOption -PredictionViewStyle ListView  # Full list view in regular PowerShell
    Set-PSReadLineOption -CompletionQueryItems 100
}
Set-PSReadLineOption -EditMode Windows

# Advanced completion behavior
Set-PSReadLineOption -MaximumHistoryCount 4000
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Colors for different types of input
Set-PSReadLineOption -Colors @{
    Command            = 'Cyan'
    Parameter          = 'Gray'
    Operator           = 'White'
    Variable           = 'Green'
    String             = 'Yellow'
    Number             = 'Red'
    Type               = 'DarkCyan'
    Comment            = 'DarkGreen'
    Keyword            = 'Blue'
    Error              = 'DarkRed'
    Selection          = 'DarkBlue'
    InlinePrediction   = 'DarkGray'
    ListPrediction     = 'DarkYellow'
    ListPredictionSelected = 'DarkGreen'
}

# Key bindings for enhanced navigation
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+z -Function Undo
Set-PSReadLineKeyHandler -Key Ctrl+y -Function Redo

# ═══════════════════════════════════════════════════════════════════════════════
# Oh My Posh Configuration
# ═══════════════════════════════════════════════════════════════════════════════

# VS Code optimizations
if ($env:TERM_PROGRAM -eq "vscode") {
    # Disable Oh My Posh animations in VS Code for better performance
    $env:POSH_DISABLE_ANIMATIONS = $true
}

# Initialize Oh My Posh with takuya theme
$ohMyPoshTheme = Join-Path $PSScriptRoot "takuya.omp.json"
if (Test-Path $ohMyPoshTheme) {
    oh-my-posh init pwsh --config $ohMyPoshTheme | Invoke-Expression
} else {
    # Fallback to a built-in theme
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\takuya.omp.json" | Invoke-Expression
}

# ═══════════════════════════════════════════════════════════════════════════════
# Zoxide Configuration
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& {
        $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
        (zoxide init --hook $hook powershell) -join "`n"
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# Linux-like Aliases and Functions
# ═══════════════════════════════════════════════════════════════════════════════

# File and Directory Operations
Set-Alias -Name ll -Value Get-ChildItemColorized
Set-Alias -Name la -Value Get-ChildItemAll
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name ls -Value Get-ChildItem
Set-Alias -Name cat -Value Get-Content
Set-Alias -Name grep -Value Select-String
Set-Alias -Name find -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command
Set-Alias -Name wget -Value Invoke-WebRequest
Set-Alias -Name curl -Value Invoke-RestMethod
Set-Alias -Name sudo -Value Start-Elevated
Set-Alias -Name touch -Value New-Item
Set-Alias -Name rm -Value Remove-Item
Set-Alias -Name mv -Value Move-Item
# Skip cp alias as it has AllScope option that cannot be removed
Set-Alias -Name mkdir -Value New-Directory
Set-Alias -Name pwd -Value Get-Location
# Skip cd alias as it has AllScope option that cannot be removed

# Process Management
Set-Alias -Name ps -Value Get-Process
Set-Alias -Name kill -Value Stop-Process
Set-Alias -Name top -Value Get-ProcessSorted

# Network
Set-Alias -Name ping -Value Test-Connection
Set-Alias -Name nslookup -Value Resolve-DnsName

# Git shortcuts
Set-Alias -Name g -Value git
function gs { git status $args }
function ga { git add $args }
function gc { git commit $args }
function gp { git push $args }
function gl { git log $args }
function gd { git diff $args }
function gb { git branch $args }
function gco { git checkout $args }

# System Information
Set-Alias -Name neofetch -Value Get-SystemInfo
Set-Alias -Name df -Value Get-DiskUsage
Set-Alias -Name free -Value Get-MemoryUsage
Set-Alias -Name uptime -Value Get-Uptime
Set-Alias -Name health -Value Get-SystemHealth

# ═══════════════════════════════════════════════════════════════════════════════
# Enhanced Function Definitions
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced ls with colors and details
function Get-ChildItemDetailed {
    param(
        [string]$Path = "."
    )
    
    # First show the detailed table view
    Get-ChildItem -Path $Path -Force | Format-Table -AutoSize @{
        Name = 'Mode'; Expression = { $_.Mode }
    }, @{
        Name = 'LastWriteTime'; Expression = { $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
    }, @{
        Name = 'Length'; Expression = { 
            if ($_.PSIsContainer) { 
                '<DIR>' 
            } else { 
                Format-FileSize $_.Length 
            }
        }
    }, @{
        Name = 'Name'; Expression = { 
            if ($_.PSIsContainer) { 
                "$($_.Name)/" 
            } else { 
                $_.Name 
            }
        }
    }
}

# Show all files including hidden
function Get-ChildItemAll {
    param(
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path -Force -Hidden
}

# Enhanced cd with history
function Set-LocationWithHistory {
    param(
        [string]$Path = $HOME
    )
    if ($Path -eq "-") {
        if ($global:LastLocation) {
            Set-Location $global:LastLocation
        } else {
            Write-Host "No previous location recorded" -ForegroundColor Yellow
        }
    } else {
        $global:LastLocation = Get-Location
        Set-Location $Path
    }
}

# Copy wrapper function (use 'copyf' instead of 'cp' due to AllScope restriction)
function Copy-ItemAlias {
    param(
        [string]$Source,
        [string]$Destination
    )
    Copy-Item -Path $Source -Destination $Destination -Recurse:$($args -contains "-r")
}

# Create alternative aliases (cp, cd, and copy have AllScope and cannot be overridden)
New-Alias -Name copyf -Value Copy-ItemAlias -Force
New-Alias -Name cdd -Value Set-LocationWithHistory -Force

# Create directory and navigate to it
function New-Directory {
    param(
        [string]$Name
    )
    New-Item -ItemType Directory -Name $Name -Force
    Set-Location $Name
}

# Run as administrator
function Start-Elevated {
    param(
        [string]$Command
    )
    Start-Process powershell -ArgumentList "-Command & {$Command}" -Verb RunAs
}

# Format file size
function Format-FileSize {
    param(
        [long]$Size
    )
    $sizes = @('B', 'KB', 'MB', 'GB', 'TB')
    $order = 0
    while ($Size -ge 1024 -and $order -lt $sizes.Count - 1) {
        $order++
        $Size = $Size / 1024
    }
    return "{0:N2} {1}" -f $Size, $sizes[$order]
}

# System information (optimized with CIM)
function Get-SystemInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $gpu = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object -First 1
    
    Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Blue
    Write-Host "│                    System Information                    │" -ForegroundColor Blue
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Blue
    Write-Host "│ OS: $($os.Caption) $($os.Version)" -ForegroundColor Cyan
    Write-Host "│ CPU: $($cpu.Name)" -ForegroundColor Cyan
    Write-Host "│ RAM: $(Format-FileSize $memory.Sum)" -ForegroundColor Cyan
    if ($gpu) {
        Write-Host "│ GPU: $($gpu.Name)" -ForegroundColor Cyan
    }
    Write-Host "│ User: $env:USERNAME@$env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host "│ Shell: PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "│ Uptime: $(((Get-Date) - $os.LastBootUpTime).Days) days, $(((Get-Date) - $os.LastBootUpTime).Hours) hours" -ForegroundColor Cyan
    Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Blue
}

# Disk usage
function Get-DiskUsage {
    Get-WmiObject -Class Win32_LogicalDisk | 
    Where-Object { $_.DriveType -eq 3 } |
    Select-Object @{
        Name = 'Drive'; Expression = { $_.DeviceID }
    }, @{
        Name = 'Size'; Expression = { Format-FileSize $_.Size }
    }, @{
        Name = 'Used'; Expression = { Format-FileSize ($_.Size - $_.FreeSpace) }
    }, @{
        Name = 'Free'; Expression = { Format-FileSize $_.FreeSpace }
    }, @{
        Name = 'Use%'; Expression = { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) }
    } | Format-Table -AutoSize
}

# Memory usage
function Get-MemoryUsage {
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemory = $memory.TotalVisibleMemorySize * 1024
    $freeMemory = $memory.FreePhysicalMemory * 1024
    $usedMemory = $totalMemory - $freeMemory
    
    Write-Host "Memory Usage:" -ForegroundColor Green
    Write-Host "  Total: $(Format-FileSize $totalMemory)" -ForegroundColor Cyan
    Write-Host "  Used:  $(Format-FileSize $usedMemory)" -ForegroundColor Yellow
    Write-Host "  Free:  $(Format-FileSize $freeMemory)" -ForegroundColor Green
    Write-Host "  Usage: $([math]::Round(($usedMemory / $totalMemory) * 100, 2))%" -ForegroundColor Magenta
}

# System uptime
function Get-Uptime {
    $uptime = (Get-Date) - (Get-WmiObject -Class Win32_OperatingSystem).ConvertToDateTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)
    Write-Host "System Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor Green
}

# Process list sorted by CPU usage
function Get-ProcessSorted {
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 | Format-Table -AutoSize
}

# Health check function (optimized with CIM instead of WMI)
function Test-SystemHealth {
    # Cache system info to avoid multiple calls
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    $health = @{
        CPU = $cpu.LoadPercentage
        Memory = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        Disk = [math]::Round((($disks | Measure-Object -Property Size -Sum).Sum - ($disks | Measure-Object -Property FreeSpace -Sum).Sum) / ($disks | Measure-Object -Property Size -Sum).Sum * 100, 2)
    }
    
    # Return health status with colors
    $cpuColor = if ($health.CPU -gt 80) { 'Red' } elseif ($health.CPU -gt 60) { 'Yellow' } else { 'Green' }
    $memColor = if ($health.Memory -gt 80) { 'Red' } elseif ($health.Memory -gt 60) { 'Yellow' } else { 'Green' }
    $diskColor = if ($health.Disk -gt 80) { 'Red' } elseif ($health.Disk -gt 60) { 'Yellow' } else { 'Green' }
    
    return @{
        CPU = @{ Value = $health.CPU; Color = $cpuColor }
        Memory = @{ Value = $health.Memory; Color = $memColor }
        Disk = @{ Value = $health.Disk; Color = $diskColor }
    }
}

# Detailed system health check
function Get-SystemHealth {
    $health = Test-SystemHealth
    
    Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Blue
    Write-Host "│                    System Health Check                   │" -ForegroundColor Blue
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Blue
    Write-Host "│ CPU Usage: " -ForegroundColor Cyan -NoNewline
    Write-Host "$($health.CPU.Value)%" -ForegroundColor $health.CPU.Color
    Write-Host "│ Memory Usage: " -ForegroundColor Cyan -NoNewline
    Write-Host "$($health.Memory.Value)%" -ForegroundColor $health.Memory.Color
    Write-Host "│ Disk Usage: " -ForegroundColor Cyan -NoNewline
    Write-Host "$($health.Disk.Value)%" -ForegroundColor $health.Disk.Color
    Write-Host "│ Status: " -ForegroundColor Cyan -NoNewline
    
    $overallHealth = ($health.CPU.Value + $health.Memory.Value + $health.Disk.Value) / 3
    if ($overallHealth -lt 60) {
        Write-Host "Excellent ✓" -ForegroundColor Green
    } elseif ($overallHealth -lt 80) {
        Write-Host "Good ⚠" -ForegroundColor Yellow
    } else {
        Write-Host "Critical ✗" -ForegroundColor Red
    }
    
    Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Blue
    
    # Show top processes if high CPU usage
    if ($health.CPU.Value -gt 80) {
        Write-Host "`nTop CPU-consuming processes:" -ForegroundColor Yellow
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table ProcessName, CPU, WorkingSet -AutoSize
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Custom Functions for Quality of Life
# ═══════════════════════════════════════════════════════════════════════════════

# Quick edit profile
function Edit-Profile {
    code $PROFILE
}

# Reload profile
function Reload-Profile {
    . $PROFILE
    Write-Host "Profile reloaded!" -ForegroundColor Green
}

# Show path in a readable format
function Show-Path {
    $env:PATH -split ';' | ForEach-Object { Write-Host $_ }
}

# Find process by name
function Find-Process {
    param(
        [string]$Name
    )
    Get-Process | Where-Object { $_.ProcessName -like "*$Name*" } | Format-Table -AutoSize
}

# Network connections
function Get-NetworkConnections {
    Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' } | 
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State |
    Format-Table -AutoSize
}

# ═══════════════════════════════════════════════════════════════════════════════
# Auto-completion Enhancements
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced tab completion for git
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $gitCommands = @(
        'add', 'bisect', 'branch', 'checkout', 'clone', 'commit', 'diff', 'fetch', 'grep',
        'init', 'log', 'merge', 'mv', 'pull', 'push', 'rebase', 'reset', 'rm', 'show',
        'status', 'tag', 'config', 'remote', 'stash', 'cherry-pick', 'revert'
    )
    
    $gitCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { $_ }
}

# Enhanced tab completion for directories
Register-ArgumentCompleter -CommandName Set-Location -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    
    Get-ChildItem -Path "$wordToComplete*" -Directory | ForEach-Object { $_.Name }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Startup Message
# ═══════════════════════════════════════════════════════════════════════════════

function Show-WelcomeMessage {
    $health = Test-SystemHealth
    
    # Show compact welcome message if in VS Code
    if ($env:TERM_PROGRAM -eq "vscode") {
        Write-Host ""
        Write-Host "┌─── PowerShell Enhanced Profile (VS Code) ───┐" -ForegroundColor Blue
        Write-Host "│ Welcome, $env:USERNAME! $(Get-Date -Format 'HH:mm')" -ForegroundColor Cyan
        Write-Host "│ Location: $(Split-Path (Get-Location) -Leaf)" -ForegroundColor Cyan
        Write-Host "│ Health: CPU $($health.CPU.Value)% | Memory $($health.Memory.Value)% | Disk $($health.Disk.Value)%" -ForegroundColor Cyan
        Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Blue
        Write-Host ""
        Write-Host "Commands: ll, neofetch, health, c (code), settings | help-profile for more" -ForegroundColor DarkGray
        Write-Host ""
    } else {
        # Show full welcome message for regular PowerShell
        Write-Host ""
        Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Magenta
        Write-Host "│             PowerShell Enhanced Profile                 │" -ForegroundColor Magenta
        Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Magenta
        Write-Host "│ Welcome back, $env:USERNAME! " -ForegroundColor Cyan -NoNewline
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Yellow
        Write-Host "│ Current Location: $(Get-Location)" -ForegroundColor Cyan
        Write-Host "│ System Health:" -ForegroundColor Cyan
        Write-Host "│   CPU: " -ForegroundColor Cyan -NoNewline
        Write-Host "$($health.CPU.Value)%" -ForegroundColor $health.CPU.Color -NoNewline
        Write-Host " │ Memory: " -ForegroundColor Cyan -NoNewline
        Write-Host "$($health.Memory.Value)%" -ForegroundColor $health.Memory.Color -NoNewline
        Write-Host " │ Disk: " -ForegroundColor Cyan -NoNewline
        Write-Host "$($health.Disk.Value)%" -ForegroundColor $health.Disk.Color
        Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Available commands: ll, la, neofetch, df, free, uptime, health, reload-profile" -ForegroundColor DarkGray
        Write-Host "Use 'z <directory>' for smart navigation | Git shortcuts: g, gs, ga, gc, gp, gst" -ForegroundColor DarkGray
        Write-Host "Enhanced: copyf, cdd, size, extract, serve, weather, ff, search, bookmarks" -ForegroundColor DarkGray
        Write-Host "Bookmarks: bookmark <name>, go <name>, bookmarks, unbookmark <name>" -ForegroundColor DarkGray
        Write-Host ""
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Error Handling
# ═══════════════════════════════════════════════════════════════════════════════

# Custom error handling
$ErrorActionPreference = 'Continue'

# Override default error formatting
$PSDefaultParameterValues['Out-Default:OutVariable'] = 'LastResult'

# ═══════════════════════════════════════════════════════════════════════════════
# Final Setup
# ═══════════════════════════════════════════════════════════════════════════════

# Show welcome message on startup
Show-WelcomeMessage

# Set window title
$Host.UI.RawUI.WindowTitle = "PowerShell Enhanced - $env:USERNAME@$env:COMPUTERNAME"

# Custom prompt function (secondary prompt)
function prompt {
    # Get current path
    $currentPath = $ExecutionContext.SessionState.Path.CurrentLocation
    $pathDisplay = $currentPath.Path
    
    # Shorten path if too long
    if ($pathDisplay.Length -gt 50) {
        $pathParts = $pathDisplay.Split([IO.Path]::DirectorySeparatorChar)
        if ($pathParts.Length -gt 3) {
            $pathDisplay = "$($pathParts[0])\...\$($pathParts[-2])\$($pathParts[-1])"
        }
    }
    
    # Get git status if in git repo
    $gitStatus = ""
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitBranch = git branch --show-current 2>$null
        if ($gitBranch) {
            $gitStatus = " ($gitBranch)"
        }
    }
    
    # Build prompt
    Write-Host "┌─[" -NoNewline -ForegroundColor DarkGray
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor Green
    Write-Host "@" -NoNewline -ForegroundColor DarkGray
    Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
    Write-Host "]─[" -NoNewline -ForegroundColor DarkGray
    Write-Host "$pathDisplay" -NoNewline -ForegroundColor Cyan
    Write-Host "$gitStatus" -NoNewline -ForegroundColor Magenta
    Write-Host "]" -ForegroundColor DarkGray
    Write-Host "└─$ " -NoNewline -ForegroundColor DarkGray
    
    return " "
}

# ═══════════════════════════════════════════════════════════════════════════════
# Profile Load Complete
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "Profile loaded successfully! Type 'neofetch' to see system info." -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════════
# Additional Useful Functions
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced grep with color highlighting
function Search-Content {
    param(
        [string]$Pattern,
        [string]$Path = ".",
        [switch]$Recursive
    )
    
    $params = @{
        Pattern = $Pattern
        Path = $Path
    }
    
    if ($Recursive) {
        $params.Add('Recurse', $true)
    }
    
    Select-String @params | ForEach-Object {
        $line = $_.Line
        $highlighted = $line -replace $Pattern, "`e[93m$Pattern`e[0m"
        Write-Host "$($_.Filename):$($_.LineNumber): $highlighted"
    }
}

# Quick file/folder size
function Get-Size {
    param(
        [string]$Path = "."
    )
    
    $item = Get-Item $Path
    if ($item.PSIsContainer) {
        $size = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum).Sum
        Write-Host "Directory: $Path" -ForegroundColor Cyan
        Write-Host "Size: $(Format-FileSize $size)" -ForegroundColor Green
    } else {
        Write-Host "File: $Path" -ForegroundColor Cyan  
        Write-Host "Size: $(Format-FileSize $item.Length)" -ForegroundColor Green
    }
}

# Extract archives
function Expand-ArchiveFile {
    param(
        [string]$Path,
        [string]$Destination = "."
    )
    
    try {
        Expand-Archive -Path $Path -DestinationPath $Destination -Force
        Write-Host "Extracted $Path to $Destination" -ForegroundColor Green
    } catch {
        Write-Host "Failed to extract: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Quick HTTP server for current directory
function Start-HttpServer {
    param(
        [int]$Port = 8080
    )
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Starting HTTP server on port $Port..." -ForegroundColor Green
        Write-Host "Access at: http://localhost:$Port" -ForegroundColor Cyan
        python -m http.server $Port
    } else {
        Write-Host "Python not found. Install Python to use this feature." -ForegroundColor Red
    }
}

# Weather function
function Get-Weather {
    param(
        [string]$City = "auto"
    )
    
    try {
        $response = Invoke-RestMethod -Uri "https://wttr.in/$City?format=3"
        Write-Host $response -ForegroundColor Cyan
    } catch {
        Write-Host "Unable to fetch weather data" -ForegroundColor Red
    }
}

# Quick encode/decode base64
function ConvertTo-Base64 {
    param([string]$Text)
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
}

function ConvertFrom-Base64 {
    param([string]$Base64)
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64))
}

# Git status with branch info
function Get-GitStatus {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            Write-Host "📂 Branch: " -NoNewline -ForegroundColor Cyan
            Write-Host "$branch" -ForegroundColor Yellow
            Write-Host ""
            git status --short
        } else {
            Write-Host "Not in a git repository" -ForegroundColor Red
        }
    } else {
        Write-Host "Git not found" -ForegroundColor Red
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Directory Bookmarks System
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize bookmarks hashtable
if (-not $global:DirectoryBookmarks) {
    $global:DirectoryBookmarks = @{
    }
}

# Save a bookmark
function Set-Bookmark {
    param(
        [string]$Name,
        [string]$Path = (Get-Location).Path
    )
    
    $global:DirectoryBookmarks[$Name] = $Path
    Write-Host "Bookmark '$Name' saved: $Path" -ForegroundColor Green
}

# Go to bookmark
function Go-Bookmark {
    param(
        [string]$Name
    )
    
    if ($global:DirectoryBookmarks.ContainsKey($Name)) {
        Set-Location $global:DirectoryBookmarks[$Name]
        Write-Host "Navigated to bookmark '$Name'" -ForegroundColor Green
    } else {
        Write-Host "Bookmark '$Name' not found" -ForegroundColor Red
    }
}

# List all bookmarks
function Get-Bookmarks {
    if ($global:DirectoryBookmarks.Count -eq 0) {
        Write-Host "No bookmarks saved" -ForegroundColor Yellow
    } else {
        Write-Host "Saved Bookmarks:" -ForegroundColor Cyan
        $global:DirectoryBookmarks.GetEnumerator() | ForEach-Object {
            Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
        }
    }
}

# Remove bookmark
function Remove-Bookmark {
    param(
        [string]$Name
    )
    
    if ($global:DirectoryBookmarks.ContainsKey($Name)) {
        $global:DirectoryBookmarks.Remove($Name)
        Write-Host "Bookmark '$Name' removed" -ForegroundColor Green
    } else {
        Write-Host "Bookmark '$Name' not found" -ForegroundColor Red
    }
}

# Set aliases for bookmark functions
Set-Alias -Name bookmark -Value Set-Bookmark
Set-Alias -Name go -Value Go-Bookmark
Set-Alias -Name bookmarks -Value Get-Bookmarks
Set-Alias -Name unbookmark -Value Remove-Bookmark

# Set aliases for new functions
Set-Alias -Name size -Value Get-Size
Set-Alias -Name extract -Value Expand-ArchiveFile
Set-Alias -Name serve -Value Start-HttpServer
Set-Alias -Name weather -Value Get-Weather
Set-Alias -Name b64encode -Value ConvertTo-Base64
Set-Alias -Name b64decode -Value ConvertFrom-Base64
Set-Alias -Name gst -Value Get-GitStatus
Set-Alias -Name search -Value Search-Content

# Fast file finder (like Linux 'find' command)
function Find-File {
    param(
        [string]$Name,
        [string]$Path = ".",
        [switch]$CaseSensitive
    )
    
    $searchParams = @{
        Path = $Path
        Recurse = $true
        File = $true
    }
    
    if ($CaseSensitive) {
        $filter = "*$Name*"
    } else {
        $filter = "*$Name*"
    }
    
    Get-ChildItem @searchParams | Where-Object { 
        if ($CaseSensitive) {
            $_.Name -like $filter
        } else {
            $_.Name -ilike $filter
        }
    } | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
}

# Find files by extension
function Find-FilesByExtension {
    param(
        [string]$Extension,
        [string]$Path = "."
    )
    
    Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Extension -eq ".$Extension" } | 
    Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
}

Set-Alias -Name ff -Value Find-File
Set-Alias -Name fext -Value Find-FilesByExtension

# Help function for custom commands
function Get-ProfileHelp {
    Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Blue
    Write-Host "│                  Custom Commands Help                    │" -ForegroundColor Blue
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Blue
    Write-Host "│ File Operations:" -ForegroundColor Yellow
    Write-Host "│  ll, la, ls      - List files (detailed, all, simple)" -ForegroundColor White
    Write-Host "│  copyf           - Enhanced copy with -r for recursive" -ForegroundColor White
    Write-Host "│  cdd             - Enhanced cd with history (cdd -)" -ForegroundColor White
    Write-Host "│  size            - Get file/directory size" -ForegroundColor White
    Write-Host "│  extract         - Extract archives" -ForegroundColor White
    Write-Host "│  ff              - Fast file finder" -ForegroundColor White
    Write-Host "│  fext            - Find files by extension" -ForegroundColor White
    Write-Host "│  search          - Enhanced grep with highlighting" -ForegroundColor White
    Write-Host "│" -ForegroundColor Blue
    Write-Host "│ System Info:" -ForegroundColor Yellow
    Write-Host "│  neofetch        - System information" -ForegroundColor White
    Write-Host "│  health          - System health check" -ForegroundColor White
    Write-Host "│  df              - Disk usage" -ForegroundColor White
    Write-Host "│  free            - Memory usage" -ForegroundColor White
    Write-Host "│  uptime          - System uptime" -ForegroundColor White
    Write-Host "│  top             - Top processes" -ForegroundColor White
    Write-Host "│" -ForegroundColor Blue
    Write-Host "│ Git Shortcuts:" -ForegroundColor Yellow
    Write-Host "│  g, gs, ga, gc, gp, gl, gd, gb, gco, gst" -ForegroundColor White
    Write-Host "│" -ForegroundColor Blue
    Write-Host "│ Navigation:" -ForegroundColor Yellow
    Write-Host "│  z               - Smart directory navigation" -ForegroundColor White
    Write-Host "│  bookmark <name> - Save current directory" -ForegroundColor White
    Write-Host "│  go <name>       - Navigate to bookmark" -ForegroundColor White
    Write-Host "│  bookmarks       - List all bookmarks" -ForegroundColor White
    Write-Host "│" -ForegroundColor Blue
    Write-Host "│ Utilities:" -ForegroundColor Yellow
    Write-Host "│  serve           - Start HTTP server" -ForegroundColor White
    Write-Host "│  weather         - Get weather info" -ForegroundColor White
    Write-Host "│  b64encode/decode- Base64 operations" -ForegroundColor White
    Write-Host "│  reload-profile  - Reload PowerShell profile" -ForegroundColor White
    Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Blue
}

Set-Alias -Name help-profile -Value Get-ProfileHelp
Set-Alias -Name commands -Value Get-ProfileHelp

# Enhanced ls with colors and details (preserves Terminal-Icons colors)
function Get-ChildItemColorized {
    param(
        [string]$Path = "."
    )
    
    # Show detailed info first
    Write-Host "`nDetailed view:" -ForegroundColor DarkGray
    Get-ChildItem -Path $Path -Force | Format-Table -AutoSize @{
        Name = 'Mode'; Expression = { $_.Mode }
    }, @{
        Name = 'LastWriteTime'; Expression = { $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
    }, @{
        Name = 'Length'; Expression = { 
            if ($_.PSIsContainer) { 
                '<DIR>' 
            } else { 
                Format-FileSize $_.Length 
            }
        }
    }, @{
        Name = 'Name'; Expression = { 
            if ($_.PSIsContainer) { 
                "$($_.Name)/" 
            } else { 
                $_.Name 
            }
        }
    }
    
    # Then show colorized view
    Write-Host "Colorized view:" -ForegroundColor DarkGray
    Get-ChildItem -Path $Path -Force
}

# ═══════════════════════════════════════════════════════════════════════════════
# VS Code Specific Functions (only loaded when in VS Code)
# ═══════════════════════════════════════════════════════════════════════════════

if ($env:TERM_PROGRAM -eq "vscode") {
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
    
    Write-Host "VS Code optimizations loaded!" -ForegroundColor Green
    Write-Host "Additional commands: c (open in code), settings, keybindings" -ForegroundColor DarkGray
}