# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Profile - Enhanced Linux-like Experience
# Author: Bogdan
# Features: Oh My Posh, Zoxide, Linux aliases, Advanced completion, Custom prompt
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Module Imports
# ═══════════════════════════════════════════════════════════════════════════════

# Add local modules to path (for bundled modules)
$localModulesPath = Join-Path (Split-Path $PROFILE -Parent) "Modules"
if ((Test-Path $localModulesPath) -and ($env:PSModulePath -notlike "*$localModulesPath*")) {
    $env:PSModulePath = "$localModulesPath;$env:PSModulePath"
}

# Import required modules with error handling
try { Import-Module PSReadLine -Force -ErrorAction SilentlyContinue } catch { }
try { Import-Module posh-git -Force -ErrorAction SilentlyContinue } catch { }
try { Import-Module Terminal-Icons -Force -ErrorAction SilentlyContinue } catch { }

# ═══════════════════════════════════════════════════════════════════════════════
# PSReadLine Configuration (Enhanced History & Autocompletion)
# ═══════════════════════════════════════════════════════════════════════════════

# Check PSReadLine version and configure accordingly
$psReadLineModule = Get-Module PSReadLine
if ($psReadLineModule) {
    $psReadLineVersion = $psReadLineModule.Version
    
    # Advanced prediction features only available in PSReadLine 2.1+
    if ($psReadLineVersion -ge [version]"2.1.0") {
        try {
            Set-PSReadLineOption -PredictionSource History
            # Use different prediction styles based on environment
            if ($env:TERM_PROGRAM -eq "vscode") {
                Set-PSReadLineOption -PredictionViewStyle InlineView  # Less intrusive in VS Code
            } else {
                Set-PSReadLineOption -PredictionViewStyle ListView  # Full list view in regular PowerShell
            }
        } catch {
            Write-Warning "Some PSReadLine prediction features are not available in this version."
        }
    } else {
        # For older PSReadLine versions, just enable basic history search
        try {
            Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
            Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        } catch { }
    }
    
    # These options should be available in most PSReadLine versions
    try {
        if ($env:TERM_PROGRAM -eq "vscode") {
            Set-PSReadLineOption -CompletionQueryItems 50  # Reduced for better performance
        } else {
            Set-PSReadLineOption -CompletionQueryItems 100
        }
    } catch { }
}
Set-PSReadLineOption -EditMode Windows

# Advanced completion behavior (available in most versions)
try {
    Set-PSReadLineOption -MaximumHistoryCount 4000
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
} catch { }

# Colors for different types of input (with error handling)
try {
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
} catch {
    # Fallback for older PSReadLine versions
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
            Keyword   = 'Blue'
            Error     = 'DarkRed'
        }
    } catch { }
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
# Enhanced Tab Completion & Auto-Suggestions
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced Tab Completion Settings
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete

# Custom Argument Completers
Register-ArgumentCompleter -CommandName 'git' -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $gitCommands = @('add', 'branch', 'checkout', 'clone', 'commit', 'diff', 'fetch', 'init', 'log', 'merge', 'pull', 'push', 'rebase', 'reset', 'status', 'tag', 'remote', 'show', 'stash', 'mv', 'rm', 'config')
    $gitCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Docker completion
Register-ArgumentCompleter -CommandName 'docker' -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $dockerCommands = @('build', 'run', 'pull', 'push', 'ps', 'images', 'start', 'stop', 'restart', 'rm', 'rmi', 'exec', 'logs', 'inspect', 'network', 'volume', 'compose')
    $dockerCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# NPM/Node completion
Register-ArgumentCompleter -CommandName 'npm' -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $npmCommands = @('install', 'uninstall', 'update', 'start', 'test', 'run', 'build', 'init', 'publish', 'info', 'search', 'list', 'audit', 'fund')
    $npmCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Custom function parameter completion for profile functions
Register-ArgumentCompleter -CommandName 'z' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Get recently used directories
    $recentDirs = @()
    if (Test-Path "$env:USERPROFILE\.zoxide\db.json") {
        try {
            $zoxideData = Get-Content "$env:USERPROFILE\.zoxide\db.json" | ConvertFrom-Json
            $recentDirs = $zoxideData.paths | Select-Object -First 20
        } catch { }
    }
    
    # Also include subdirectories of current location
    $currentDirs = Get-ChildItem -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    
    ($recentDirs + $currentDirs) | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Enhanced path completion with smart suggestions
Register-ArgumentCompleter -CommandName @('cd', 'Set-Location', 'sl') -ParameterName 'Path' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Get directories that match the partial input
    $directories = @()
    
    if ($wordToComplete) {
        # Try to resolve relative paths
        $basePath = if ($wordToComplete -match '^[a-zA-Z]:' -or $wordToComplete.StartsWith('\\')) {
            Split-Path $wordToComplete -Parent
        } else {
            Get-Location
        }
        
        try {
            $pattern = Split-Path $wordToComplete -Leaf
            $searchPath = if ($basePath) { $basePath } else { Get-Location }
            
            $directories = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -like "$pattern*" } |
                ForEach-Object { 
                    $fullPath = $_.FullName
                    $displayName = if ($wordToComplete -match '^[a-zA-Z]:' -or $wordToComplete.StartsWith('\\')) {
                        $fullPath
                    } else {
                        $_.Name
                    }
                    [System.Management.Automation.CompletionResult]::new($displayName, $displayName, 'ParameterValue', $fullPath)
                }
        } catch { }
    } else {
        # Show current directory contents
        try {
            $directories = Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.FullName)
            }
        } catch { }
    }
    
    return $directories
}

# File extension based completion
Register-ArgumentCompleter -CommandName @('code', 'notepad', 'Get-Content', 'gc', 'cat') -ParameterName 'Path' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $fileExtensions = @('.ps1', '.txt', '.json', '.xml', '.csv', '.md', '.yml', '.yaml', '.config', '.log')
    
    try {
        Get-ChildItem -File -ErrorAction SilentlyContinue |
            Where-Object { 
                $_.Name -like "$wordToComplete*" -and 
                ($fileExtensions -contains $_.Extension -or $_.Extension -eq '')
            } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.FullName)
            }
    } catch { }
}

# Enhanced history-based intelligent suggestions
if (Get-Module PSReadLine) {
    try {
        # Enable predictive IntelliSense if available (PSReadLine 2.2.2+)
        if ((Get-Module PSReadLine).Version -ge [version]"2.2.2") {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
        }
        
        # Smart completion based on command context
        Set-PSReadLineOption -CompletionQueryItems 50
        Set-PSReadLineOption -MaximumHistoryCount 10000
        
        # Enable F1 for command help
        Set-PSReadLineKeyHandler -Key F1 -Function WhatIsKey
        
        # Ctrl+R for reverse history search
        Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
        
    } catch {
        Write-Verbose "Advanced PSReadLine features not available in this version"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Oh My Posh Configuration
# ═══════════════════════════════════════════════════════════════════════════════

# VS Code optimizations
if ($env:TERM_PROGRAM -eq "vscode") {
    # Disable Oh My Posh animations in VS Code for better performance
    $env:POSH_DISABLE_ANIMATIONS = $true
}


# Force Oh My Posh to use the theme from the project folder
$projectTheme = Join-Path "$PSScriptRoot" "oh-my-posh-default.json"
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Warning "Oh My Posh is not installed. Install it with: winget install JanDeDobbeleer.OhMyPosh"
    Write-Host "Or visit: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
} elseif (Test-Path $projectTheme) {
    try {
        oh-my-posh init pwsh --config $projectTheme | Invoke-Expression
        Write-Verbose "Oh My Posh initialized with project theme: $projectTheme"
    } catch {
        Write-Warning "Failed to load project Oh My Posh theme: $($_.Exception.Message)"
        # Fallback to built-in theme
        try {
            if ($env:POSH_THEMES_PATH -and (Test-Path "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json")) {
                oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
                Write-Host "Using fallback Oh My Posh theme" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Could not initialize any Oh My Posh theme"
        }
    }
} else {
    Write-Warning "Project theme not found at: $projectTheme"
    # Try to use a built-in theme if available
    try {
        if ($env:POSH_THEMES_PATH -and (Test-Path "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json")) {
            oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
            Write-Host "Oh My Posh initialized with built-in theme (project theme not found)" -ForegroundColor Yellow
        } else {
            Write-Warning "No Oh My Posh themes found. Theme file should be at: $projectTheme"
        }
    } catch {
        Write-Warning "Could not initialize Oh My Posh. Please check installation."
    }
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
Set-Alias -Name lld -Value Get-ChildItemDetailed  # Detailed view without colors
Set-Alias -Name la -Value Get-ChildItemColorizedAll  # Show hidden files with colors
Set-Alias -Name l -Value Get-ChildItemColorized

# Handle potentially protected aliases with try-catch (these may fail in some PowerShell versions)
try { Set-Alias -Name ls -Value Get-ChildItemColorized -Force -ErrorAction SilentlyContinue } catch { }
try { Set-Alias -Name dir -Value Get-ChildItemColorized -Force -ErrorAction SilentlyContinue } catch { }
try { Set-Alias -Name cat -Value Get-Content -Force -ErrorAction SilentlyContinue } catch { }

Set-Alias -Name grep -Value Select-String
Set-Alias -Name find -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

try { Set-Alias -Name wget -Value Invoke-WebRequest -Force -ErrorAction SilentlyContinue } catch { }
try { Set-Alias -Name curl -Value Invoke-RestMethod -Force -ErrorAction SilentlyContinue } catch { }

Set-Alias -Name sudo -Value Start-Elevated
Set-Alias -Name touch -Value New-Item

# Handle potentially protected aliases with try-catch
try { Set-Alias -Name rm -Value Remove-Item -Force -ErrorAction SilentlyContinue } catch { }
try { Set-Alias -Name mv -Value Move-Item -Force -ErrorAction SilentlyContinue } catch { }

# Skip cp and cd aliases as they have AllScope protection that cannot be overridden
Set-Alias -Name mkdir -Value New-Directory
try { Set-Alias -Name pwd -Value Get-Location -Force -ErrorAction SilentlyContinue } catch { }

# Process Management
try { Set-Alias -Name ps -Value Get-Process -Force -ErrorAction SilentlyContinue } catch { }
try { Set-Alias -Name kill -Value Stop-Process -Force -ErrorAction SilentlyContinue } catch { }
Set-Alias -Name top -Value Get-ProcessSorted

# Network
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

# Show all files including hidden with colors
function Get-ChildItemColorizedAll {
    param(
        [string]$Path = "."
    )
    Get-ChildItemColorized -Path $Path -ShowHidden
}

# Show all files including hidden (simple view)
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
function Invoke-ProfileReload {
    . $PROFILE
    Write-Host "Profile reloaded!" -ForegroundColor Green
}

# Create alias for backward compatibility
Set-Alias -Name reload-profile -Value Invoke-ProfileReload

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

# Clipboard Utilities (Enhancement 2)
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    function Copy-ToClipboard {
        param(
            [Parameter(ValueFromPipeline)]
            [string]$Text
        )
        process {
            $Text | Set-Clipboard
            Write-Host "Copied to clipboard!" -ForegroundColor Green
        }
    }
} else {
    function Copy-ToClipboard {
        Write-Host "Set-Clipboard is not available. Please update PowerShell or install the required module." -ForegroundColor Yellow
    }
}

if (Get-Command Get-Clipboard -ErrorAction SilentlyContinue) {
    function Get-FromClipboard {
        $clip = Get-Clipboard
        Write-Host $clip
        return $clip
    }
} else {
    function Get-FromClipboard {
        Write-Host "Get-Clipboard is not available. Please update PowerShell or install the required module." -ForegroundColor Yellow
        return $null
    }
}

New-Alias -Name copyclip -Value Copy-ToClipboard -Force
New-Alias -Name pasteclip -Value Get-FromClipboard -Force

# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced History Search (Enhancement 3)
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
    function Search-History {
        $selected = Get-History | Sort-Object Id -Descending | Select-Object -ExpandProperty CommandLine | Out-GridView -Title "Select command to run" -PassThru
        if ($selected) {
            Write-Host "Running: $selected" -ForegroundColor Cyan
            Invoke-Expression $selected
        }
    }
} elseif (Get-Command fzf -ErrorAction SilentlyContinue) {
    function Search-History {
        $selected = Get-History | Sort-Object Id -Descending | Select-Object -ExpandProperty CommandLine | fzf --prompt="History> "
        if ($selected) {
            Write-Host "Running: $selected" -ForegroundColor Cyan
            Invoke-Expression $selected
        }
    }
} else {
    function Search-History {
        Get-History | Sort-Object Id -Descending | Select-Object -First 20 | Format-Table Id, CommandLine
        Write-Host "Install 'Out-GridView' (Windows) or 'fzf' (cross-platform) for interactive history search." -ForegroundColor Yellow
    }
}

Set-Alias -Name hist -Value Search-History

# ═══════════════════════════════════════════════════════════════════════════════

# Git Enhancements (Enhancement 4)
# ═══════════════════════════════════════════════════════════════════════════════

if (Get-Command git -ErrorAction SilentlyContinue) {
    function gitlg {
        git log --oneline --graph --all --decorate
    }
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        function gcof {
            $branch = git branch --all --color=never | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | fzf --prompt="Checkout branch: "
            if ($branch) {
                $branchName = $branch -replace '^\* ', '' -replace 'remotes/', ''
                git checkout $branchName
            }
        }
        function gstashf {
            $stash = git stash list | fzf --prompt="Apply stash: "
            if ($stash) {
                $stashId = $stash -split ':' | Select-Object -First 1
                git stash apply $stashId
            }
        }
    } else {
        function gcof {
            Write-Host "fzf not found. Please install fzf for interactive branch checkout." -ForegroundColor Yellow
        }
        function gstashf {
            Write-Host "fzf not found. Please install fzf for interactive stash apply." -ForegroundColor Yellow
        }
    }
} else {
    function gitlg {
        Write-Host "Git is not installed or not in PATH." -ForegroundColor Yellow
    }
    function gcof {
        Write-Host "Git is not installed or not in PATH." -ForegroundColor Yellow
    }
    function gstashf {
        Write-Host "Git is not installed or not in PATH." -ForegroundColor Yellow
    }
}

Set-Alias -Name gitlog -Value gitlg
Set-Alias -Name gcof -Value gcof
Set-Alias -Name gstashf -Value gstashf

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
    Write-Host "Commands: ll, health, c (code), settings | help-profile for more" -ForegroundColor DarkGray
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

Write-Host "Profile loaded successfully!" -ForegroundColor Green

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
function Invoke-BookmarkNavigation {
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
Set-Alias -Name go -Value Invoke-BookmarkNavigation
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
    Write-Host "│  ll, la, ls, dir - Colorized file listing with table format" -ForegroundColor White
    Write-Host "│  lld             - Detailed view without colors" -ForegroundColor White
    Write-Host "│  colors/legend   - Show file type color legend" -ForegroundColor White
    Write-Host "│  copyf           - Enhanced copy with -r for recursive" -ForegroundColor White
    Write-Host "│  cdd             - Enhanced cd with history (cdd -)" -ForegroundColor White
    Write-Host "│  size            - Get file/directory size" -ForegroundColor White
    Write-Host "│  extract         - Extract archives" -ForegroundColor White
    Write-Host "│  ff              - Fast file finder" -ForegroundColor White
    Write-Host "│  fext            - Find files by extension" -ForegroundColor White
    Write-Host "│  search          - Enhanced grep with highlighting" -ForegroundColor White
    Write-Host "│" -ForegroundColor Blue
    Write-Host "│ System Info:" -ForegroundColor Yellow

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
Set-Alias -Name colors -Value Show-FileColorLegend
Set-Alias -Name legend -Value Show-FileColorLegend

# Enhanced ls with colors and structured table format
function Get-ChildItemColorized {
    param(
        [string]$Path = ".",
        [switch]$ShowHidden
    )
    
    # Get items with optional hidden files
    if ($ShowHidden) {
        $items = Get-ChildItem -Path $Path -Force
    } else {
        $items = Get-ChildItem -Path $Path
    }
    
    if ($items.Count -eq 0) {
        Write-Host "No items found in directory: $Path" -ForegroundColor Yellow
        return
    }
    
    # Separate directories and files
    $directories = $items | Where-Object { $_.PSIsContainer } | Sort-Object Name
    $files = $items | Where-Object { -not $_.PSIsContainer } | Sort-Object Name
    
    # Function to get file color based on extension
    function Get-FileColor {
        param([string]$Extension, [bool]$IsDirectory)
        
        if ($IsDirectory) {
            return "Blue"
        }
        
        switch ($Extension.ToLower()) {
            {$_ -in '.exe', '.msi', '.bat', '.cmd', '.ps1', '.sh'} { return "Green" }
            {$_ -in '.txt', '.md', '.readme', '.log'} { return "White" }
            {$_ -in '.json', '.xml', '.yaml', '.yml', '.config'} { return "Yellow" }
            {$_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico'} { return "Magenta" }
            {$_ -in '.mp3', '.wav', '.mp4', '.avi', '.mkv', '.mov'} { return "DarkMagenta" }
            {$_ -in '.zip', '.rar', '.7z', '.tar', '.gz'} { return "Red" }
            {$_ -in '.cs', '.js', '.ts', '.py', '.cpp', '.h', '.css', '.html'} { return "Cyan" }
            {$_ -in '.dll', '.lib', '.so'} { return "DarkRed" }
            {$_ -in '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'} { return "DarkYellow" }
            default { return "Gray" }
        }
    }
    
    # Function to get file type icon/symbol
    function Get-FileSymbol {
        param([string]$Extension, [bool]$IsDirectory)
        
        if ($IsDirectory) {
            return "📁"
        }
        
        switch ($Extension.ToLower()) {
            {$_ -in '.exe', '.msi'} { return "⚙️" }
            {$_ -in '.bat', '.cmd', '.ps1', '.sh'} { return "📜" }
            {$_ -in '.txt', '.md', '.readme', '.log'} { return "📄" }
            {$_ -in '.json', '.xml', '.yaml', '.yml', '.config'} { return "🔧" }
            {$_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico'} { return "🖼️" }
            {$_ -in '.mp3', '.wav', '.mp4', '.avi', '.mkv', '.mov'} { return "🎵" }
            {$_ -in '.zip', '.rar', '.7z', '.tar', '.gz'} { return "📦" }
            {$_ -in '.cs', '.js', '.ts', '.py', '.cpp', '.h', '.css', '.html'} { return "💻" }
            {$_ -in '.dll', '.lib', '.so'} { return "🔗" }
            {$_ -in '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'} { return "📋" }
            default { return "📄" }
        }
    }
    
    # Function to format file size
    function Format-FileSize {
        param([long]$Size)
        if ($Size -eq 0) { return "0 B" }
        $sizes = @('B', 'KB', 'MB', 'GB', 'TB')
        $order = 0
        while ($Size -ge 1024 -and $order -lt $sizes.Count - 1) {
            $order++
            $Size = $Size / 1024
        }
        return "{0:N1} {1}" -f $Size, $sizes[$order]
    }
    
    # Display header
    Write-Host ""
    Write-Host "Directory: " -NoNewline -ForegroundColor DarkGray
    Write-Host (Resolve-Path $Path).Path -ForegroundColor Cyan
    Write-Host ""
    
    # Create structured table output
    $tableData = @()
    
    # Add directories first
    foreach ($dir in $directories) {
        $color = Get-FileColor -Extension "" -IsDirectory $true
        $symbol = Get-FileSymbol -Extension "" -IsDirectory $true
        
        $tableData += [PSCustomObject]@{
            Symbol = $symbol
            Type = "DIR"
            Name = $dir.Name
            Size = "<DIR>"
            Modified = $dir.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Color = $color
            IsDirectory = $true
        }
    }
    
    # Add files
    foreach ($file in $files) {
        $color = Get-FileColor -Extension $file.Extension -IsDirectory $false
        $symbol = Get-FileSymbol -Extension $file.Extension -IsDirectory $false
        
        $tableData += [PSCustomObject]@{
            Symbol = $symbol
            Type = $file.Extension.ToUpper().TrimStart('.')
            Name = $file.Name
            Size = Format-FileSize $file.Length
            Modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Color = $color
            IsDirectory = $false
        }
    }
    
    # Display table header
    Write-Host "  Type  " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host " Name".PadRight(35) -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host " Size".PadRight(12) -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host " Modified".PadRight(18) -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "─" * 75 -ForegroundColor DarkGray
    
    # Display each item with colors
    foreach ($item in $tableData) {
        # Type column (6 chars)
        if ($item.IsDirectory) {
            Write-Host " DIR " -NoNewline -ForegroundColor White -BackgroundColor Blue
        } else {
            Write-Host (" " + $item.Type).PadRight(5).Substring(0,5) -NoNewline -ForegroundColor Black -BackgroundColor Gray
        }
        Write-Host " " -NoNewline
        
        # Name column (35 chars) with color coding
        $displayName = if ($item.Name.Length -gt 34) { $item.Name.Substring(0,31) + "..." } else { $item.Name }
        Write-Host $displayName.PadRight(35) -NoNewline -ForegroundColor $item.Color
        
        # Size column (12 chars)
        Write-Host $item.Size.PadRight(12) -NoNewline -ForegroundColor DarkYellow
        
        # Modified column (18 chars)
        Write-Host $item.Modified -ForegroundColor DarkGray
    }
    
    # Display summary
    Write-Host ""
    Write-Host "─" * 75 -ForegroundColor DarkGray
    Write-Host "Summary: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($directories.Count) directories" -ForegroundColor Blue -NoNewline
    Write-Host ", " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($files.Count) files" -ForegroundColor Cyan
    
    if ($files.Count -gt 0) {
        $totalSize = ($files | Measure-Object Length -Sum).Sum
        Write-Host "Total size: " -ForegroundColor DarkGray -NoNewline
        Write-Host (Format-FileSize $totalSize) -ForegroundColor Yellow
    }
    Write-Host ""
}

# Function to show file type color legend
function Show-FileColorLegend {
    Write-Host ""
    Write-Host "File Type Color Legend:" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "─" * 50 -ForegroundColor DarkGray
    
    Write-Host "📁 Directories" -ForegroundColor Blue
    Write-Host "⚙️ Executables (.exe, .msi)" -ForegroundColor Green
    Write-Host "📜 Scripts (.bat, .cmd, .ps1, .sh)" -ForegroundColor Green
    Write-Host "📄 Text files (.txt, .md, .log)" -ForegroundColor White
    Write-Host "🔧 Config files (.json, .xml, .yaml)" -ForegroundColor Yellow
    Write-Host "🖼️ Images (.jpg, .png, .gif)" -ForegroundColor Magenta
    Write-Host "🎵 Media (.mp3, .mp4, .avi)" -ForegroundColor DarkMagenta
    Write-Host "📦 Archives (.zip, .rar, .7z)" -ForegroundColor Red
    Write-Host "💻 Source code (.cs, .js, .py, .cpp)" -ForegroundColor Cyan
    Write-Host "🔗 Libraries (.dll, .lib, .so)" -ForegroundColor DarkRed
    Write-Host "📋 Documents (.pdf, .doc, .xls)" -ForegroundColor DarkYellow
    Write-Host "📄 Other files" -ForegroundColor Gray
    Write-Host ""
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