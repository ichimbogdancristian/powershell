# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - Optimized Version
# Author: Bogdan Ichim
# Features: Oh My Posh, Linux aliases, Enhanced completion, System monitoring
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Module Imports
# ═══════════════════════════════════════════════════════════════════════════════

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
                }
                else {
                    Set-PSReadLineOption -PredictionViewStyle ListView  # Full list view in regular PowerShell
                }
            }
            catch {
                Write-Warning "Some PSReadLine prediction features are not available in this version."
            }
        }
        else {
            # For older PSReadLine versions, just enable basic history search
            try {
                Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
                Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
            }
            catch { }
        }
    
        # These options should be available in most PSReadLine versions
        try {
            if ($env:TERM_PROGRAM -eq "vscode") {
                Set-PSReadLineOption -CompletionQueryItems 50  # Reduced for better performance
            }
            else {
                Set-PSReadLineOption -CompletionQueryItems 100
            }
        }
        catch { }
    }
    Set-PSReadLineOption -EditMode Windows

    # Advanced completion behavior (available in most versions)
    try {
        Set-PSReadLineOption -MaximumHistoryCount 4000
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    }
    catch { }

    # Enhanced key handlers for better suggestions
    try {
        # Ctrl+Space for menu complete (alternative to Tab)
        Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete
        # Ctrl+Shift+Space for inline suggestions
        Set-PSReadLineKeyHandler -Key Ctrl+Shift+Spacebar -Function InlineSuggestion
        # F1 for help on current command
        Set-PSReadLineKeyHandler -Key F1 -Function ShowCommandHelp
        # Ctrl+RightArrow for forward word
        Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
        # Ctrl+LeftArrow for backward word
        Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
    }
    catch { }

    # Colors for different types of input (with error handling)
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
            Keyword   = 'Magenta'
            Error     = 'Red'
            Selection = 'DarkGray'
        }
    }
    catch { }

    # ═══════════════════════════════════════════════════════════════════════════════
    # Oh My Posh Configuration
    # ═══════════════════════════════════════════════════════════════════════════════

    # VS Code optimizations
    if ($env:TERM_PROGRAM -eq "vscode") {
        # Disable Oh My Posh animations in VS Code for better performance
        $env:POSH_DISABLE_ANIMATIONS = $true
    }

    # Initialize Oh My Posh with default theme
    # Try multiple locations for the theme file, ensuring robust path detection
    $profileDir = Split-Path $PROFILE -Parent
    $themeLocations = @(
        # First try in the same directory as the profile
        (Join-Path $profileDir "oh-my-posh-default.json"),
        # Try in PowerShell directory
        (Join-Path $env:USERPROFILE "Documents\PowerShell\oh-my-posh-default.json"),
        # Try in WindowsPowerShell directory
        (Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\oh-my-posh-default.json"),
        # Try using PSScriptRoot if it exists
        $(if ($PSScriptRoot) { Join-Path $PSScriptRoot "oh-my-posh-default.json" }),
        # Try current working directory as last resort
        ".\oh-my-posh-default.json"
    )

    # Filter out null/empty paths
    $themeLocations = $themeLocations | Where-Object { $_ -and (Test-Path $_ -IsValid) }

    $ohMyPoshTheme = $null
    foreach ($location in $themeLocations) {
        if (Test-Path $location) {
                        $ohMyPoshTheme = $location
                        Write-Verbose "Found Oh My Posh theme at: $ohMyPoshTheme"
                        break
                    }
                }

                # Check if Oh My Posh is installed
                if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
                    Write-Warning "Oh My Posh is not installed. Install it with: winget install JanDeDobbeleer.OhMyPosh"
                    Write-Host "Or visit: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
                }
                elseif ($ohMyPoshTheme) {
                    try {
                        oh-my-posh init pwsh --config $ohMyPoshTheme | Invoke-Expression
                        Write-Verbose "Oh My Posh initialized with custom theme: $ohMyPoshTheme"
                    }
                    catch {
                        Write-Warning "Failed to load custom Oh My Posh theme: $($_.Exception.Message)"
                        # Fallback to built-in theme
                        try {
                            if ($env:POSH_THEMES_PATH -and (Test-Path "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json")) {
                                oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
                                Write-Host "Using fallback Oh My Posh theme" -ForegroundColor Yellow
                            }
                        }
                        catch {
                            Write-Warning "Could not initialize any Oh My Posh theme"
                        }
                    }
                }
                else {
                    # Try to use a built-in theme if available
                    try {
                        if ($env:POSH_THEMES_PATH -and (Test-Path "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json")) {
                            oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
                            Write-Host "Oh My Posh initialized with built-in theme (custom theme not found)" -ForegroundColor Yellow
                        }
                        else {
                            Write-Warning "No Oh My Posh themes found. Theme file should be at: $profileDir\oh-my-posh-default.json"
                        }
                    }
                    catch {
                        Write-Warning "Could not initialize Oh My Posh. Please check installation."
                    }
                }

                # ═══════════════════════════════════════════════════════════════════════════════
                # Zoxide Integration (Smart Directory Navigation)
                # ═══════════════════════════════════════════════════════════════════════════════

                if (Get-Command zoxide -ErrorAction SilentlyContinue) {
                    Invoke-Expression (& {
                            $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
                            (zoxide init --hook $hook powershell) -join "`n"
                        })

                    # Enhanced zoxide functions
                    function zz { z $args; Get-ChildItemColorized }  # Jump and list contents
                    function zh { zoxide query --list | Select-Object -First 10 }  # Show recent directories
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
                    }
                    catch {
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
                    Write-Host "System Info: neofetch, sysinfo, health" -ForegroundColor White
                    Write-Host "Navigation: zz (jump + list), zh (recent dirs)" -ForegroundColor White
                    Write-Host "Git: gs (status), gl (log)" -ForegroundColor White
                    Write-Host "Network: Get-PublicIP, Test-InternetConnection" -ForegroundColor White
                }

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
                                }
                                else { 
                                    Format-FileSize $_.Length 
                                }
                            }
                        }, @{
                            Name = 'Name'; Expression = { 
                                if ($_.PSIsContainer) { 
                                    "$($_.Name)/" 
                                }
                                else { 
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
                            }
                            else {
                                Write-Host "No previous location recorded" -ForegroundColor Yellow
                            }
                        }
                        else {
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
                            CPU    = $cpu.LoadPercentage
                            Memory = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
                            Disk   = [math]::Round((($disks | Measure-Object -Property Size -Sum).Sum - ($disks | Measure-Object -Property FreeSpace -Sum).Sum) / ($disks | Measure-Object -Property Size -Sum).Sum * 100, 2)
                        }
    
                        # Return health status with colors
                        $cpuColor = if ($health.CPU -gt 80) { 'Red' } elseif ($health.CPU -gt 60) { 'Yellow' } else { 'Green' }
                        $memColor = if ($health.Memory -gt 80) { 'Red' } elseif ($health.Memory -gt 60) { 'Yellow' } else { 'Green' }
                        $diskColor = if ($health.Disk -gt 80) { 'Red' } elseif ($health.Disk -gt 60) { 'Yellow' } else { 'Green' }
    
                        return @{
                            CPU    = @{ Value = $health.CPU; Color = $cpuColor }
                            Memory = @{ Value = $health.Memory; Color = $memColor }
                            Disk   = @{ Value = $health.Disk; Color = $diskColor }
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
                        }
                        elseif ($overallHealth -lt 80) {
                            Write-Host "Good ⚠" -ForegroundColor Yellow
                        }
                        else {
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
                    }
                    else {
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
                    }
                    else {
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
                    }
                    elseif (Get-Command fzf -ErrorAction SilentlyContinue) {
                        function Search-History {
                            $selected = Get-History | Sort-Object Id -Descending | Select-Object -ExpandProperty CommandLine | fzf --prompt="History> "
                            if ($selected) {
                                Write-Host "Running: $selected" -ForegroundColor Cyan
                                Invoke-Expression $selected
                            }
                        }
                    }
                    else {
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
                        }
                        else {
                            function gcof {
                                Write-Host "fzf not found. Please install fzf for interactive branch checkout." -ForegroundColor Yellow
                            }
                            function gstashf {
                                Write-Host "fzf not found. Please install fzf for interactive stash apply." -ForegroundColor Yellow
                            }
                        }
                    }
                    else {
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
                            Write-Host "Commands: ll, neofetch, health, c (code), settings | help-profile for more" -ForegroundColor DarkGray
                            Write-Host ""
                        }
                        else {
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
                            Write-Host "Use 'z `<directory`>' for smart navigation | Git shortcuts: g, gs, ga, gc, gp, gst" -ForegroundColor DarkGray
                            Write-Host "Enhanced: copyf, cdd, size, extract, serve, weather, ff, search, bookmarks" -ForegroundColor DarkGray
                            Write-Host 'Bookmarks: bookmark <name>, go <name>, bookmarks, unbookmark <name>' -ForegroundColor DarkGray
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
                            Path    = $Path
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
                        }
                        else {
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
                        }
                        catch {
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
                        }
                        else {
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
                        }
                        catch {
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
                            }
                            else {
                                Write-Host "Not in a git repository" -ForegroundColor Red
                            }
                        }
                        else {
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
                        }
                        else {
                            Write-Host "Bookmark '$Name' not found" -ForegroundColor Red
                        }
                    }

                    # List all bookmarks
                    function Get-Bookmarks {
                        if ($global:DirectoryBookmarks.Count -eq 0) {
                            Write-Host "No bookmarks saved" -ForegroundColor Yellow
                        }
                        else {
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
                        }
                        else {
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
                            Path    = $Path
                            Recurse = $true
                            File    = $true
                        }
    
                        if ($CaseSensitive) {
                            $filter = "*$Name*"
                        }
                        else {
                            $filter = "*$Name*"
                        }
    
                        Get-ChildItem @searchParams | Where-Object { 
                            if ($CaseSensitive) {
                                $_.Name -like $filter
                            }
                            else {
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
                        }
                        else {
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
                                { $_ -in '.exe', '.msi', '.bat', '.cmd', '.ps1', '.sh' } { return "Green" }
                                { $_ -in '.txt', '.md', '.readme', '.log' } { return "White" }
                                { $_ -in '.json', '.xml', '.yaml', '.yml', '.config' } { return "Yellow" }
                                { $_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico' } { return "Magenta" }
                                { $_ -in '.mp3', '.wav', '.mp4', '.avi', '.mkv', '.mov' } { return "DarkMagenta" }
                                { $_ -in '.zip', '.rar', '.7z', '.tar', '.gz' } { return "Red" }
                                { $_ -in '.cs', '.js', '.ts', '.py', '.cpp', '.h', '.css', '.html' } { return "Cyan" }
                                { $_ -in '.dll', '.lib', '.so' } { return "DarkRed" }
                                { $_ -in '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx' } { return "DarkYellow" }
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
                                { $_ -in '.exe', '.msi' } { return "⚙️" }
                                { $_ -in '.bat', '.cmd', '.ps1', '.sh' } { return "📜" }
                                { $_ -in '.txt', '.md', '.readme', '.log' } { return "📄" }
                                { $_ -in '.json', '.xml', '.yaml', '.yml', '.config' } { return "🔧" }
                                { $_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico' } { return "🖼️" }
                                { $_ -in '.mp3', '.wav', '.mp4', '.avi', '.mkv', '.mov' } { return "🎵" }
                                { $_ -in '.zip', '.rar', '.7z', '.tar', '.gz' } { return "📦" }
                                { $_ -in '.cs', '.js', '.ts', '.py', '.cpp', '.h', '.css', '.html' } { return "💻" }
                                { $_ -in '.dll', '.lib', '.so' } { return "🔗" }
                                { $_ -in '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx' } { return "📋" }
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
                        Write-Host "Directory Navigation:" -ForegroundColor Yellow
                        Write-Host "  ll [path]     - Enhanced directory listing" -ForegroundColor White
                        Write-Host "  la [path]     - Show all files (including hidden)" -ForegroundColor White
                        Write-Host "  lsl [path]    - Long format listing" -ForegroundColor White
                        Write-Host "  z [dir]       - Smart directory jump (zoxide)" -ForegroundColor White
                        Write-Host "  zz [dir]      - Jump and list contents" -ForegroundColor White
                        Write-Host "  zh            - Show recent directories" -ForegroundColor White
                        Write-Host ""
                        Write-Host "System Information:" -ForegroundColor Yellow
                        Write-Host "  neofetch      - System information display" -ForegroundColor White
                        Write-Host "  health        - System health check" -ForegroundColor White
                        Write-Host "  myip          - Show public IP address" -ForegroundColor White
                        Write-Host "  testnet       - Test internet connection" -ForegroundColor White
    
                        # Create structured table output
                        $tableData = @()
    
                        # Add directories first
                        foreach ($dir in $directories) {
                            $color = Get-FileColor -Extension "" -IsDirectory $true
                            $symbol = Get-FileSymbol -Extension "" -IsDirectory $true
        
                            $tableData += [PSCustomObject]@{
                                Symbol      = $symbol
                                Type        = "DIR"
                                Name        = $dir.Name
                                Size        = "<DIR>"
                                Modified    = $dir.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                                Color       = $color
                                IsDirectory = $true
                            }
                        }
    
                        # Add files
                        foreach ($file in $files) {
                            $color = Get-FileColor -Extension $file.Extension -IsDirectory $false
                            $symbol = Get-FileSymbol -Extension $file.Extension -IsDirectory $false
        
                            $tableData += [PSCustomObject]@{
                                Symbol      = $symbol
                                Type        = $file.Extension.ToUpper().TrimStart('.')
                                Name        = $file.Name
                                Size        = Format-FileSize $file.Length
                                Modified    = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                                Color       = $color
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
                            }
                            else {
                                Write-Host (" " + $item.Type).PadRight(5).Substring(0, 5) -NoNewline -ForegroundColor Black -BackgroundColor Gray
                            }
                            Write-Host " " -NoNewline
        
                            # Name column (35 chars) with color coding
                            $displayName = if ($item.Name.Length -gt 34) { $item.Name.Substring(0, 31) + "..." } else { $item.Name }
                            Write-Host $displayName.PadRight(35) -NoNewline -ForegroundColor $item.Color
        
                            # Size column (12 chars)
                            Write-Host $item.Size.PadRight(12) -NoNewline -ForegroundColor DarkYellow
        
                            # Modified column (18 chars)
                            Write-Host $item.Modified -ForegroundColor DarkGray
                        }
    
                        # Display summary
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
                    Set-Alias -Name gl -Value Get-GitLog -Force -ErrorAction SilentlyContinue
                    Set-Alias -Name ps-name -Value Get-ProcessesByName -Force
                    Set-Alias -Name help-profile -Value Get-ProfileHelp -Force

                    # ═══════════════════════════════════════════════════════════════════════════════
                    # Welcome Message
                    # ═══════════════════════════════════════════════════════════════════════════════

