# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile Setup Script
# Author: Bogdan Ichim
# Repository: https://github.com/ichimbogdancristian/powershell
# Description: Automated setup script for enhanced PowerShell profile with one-line install
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [switch]$Force,
    [switch]$SkipModules,
    [switch]$SkipTools
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Color functions for better output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

# Header
Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Blue
Write-Host "│          PowerShell Enhanced Profile Setup              │" -ForegroundColor Blue
Write-Host "│                  by Bogdan Ichim                        │" -ForegroundColor Blue
Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Blue
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.0 or higher is required. Please upgrade PowerShell."
    exit 1
}

Write-Info "✓ PowerShell version: $($PSVersionTable.PSVersion)"

# Check if running as administrator for certain operations
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Write-Info "✓ Running as Administrator"
} else {
    Write-Warning "⚠ Not running as Administrator - some features may be limited"
}

# Function to install required modules
function Install-RequiredModules {
    Write-Info "📦 Installing required PowerShell modules..."
    
    $modules = @(
        @{ Name = "PSReadLine"; MinVersion = "2.0.0" },
        @{ Name = "posh-git"; MinVersion = "1.0.0" },
        @{ Name = "Terminal-Icons"; MinVersion = "0.5.0" }
    )
    
    foreach ($module in $modules) {
        try {
            $installed = Get-Module -Name $module.Name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            
            if ($installed -and $installed.Version -ge [version]$module.MinVersion) {
                Write-Success "✓ $($module.Name) is already installed (v$($installed.Version))"
            } else {
                Write-Info "Installing $($module.Name)..."
                Install-Module -Name $module.Name -Force -AllowClobber -Scope CurrentUser
                Write-Success "✓ $($module.Name) installed successfully"
            }
        } catch {
            Write-Error "✗ Failed to install $($module.Name): $($_.Exception.Message)"
        }
    }
}

# Function to install external tools
function Install-ExternalTools {
    Write-Info "🔧 Installing external tools..."
    
    # Check for package managers
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    $hasChoco = Get-Command choco -ErrorAction SilentlyContinue
    $hasScoop = Get-Command scoop -ErrorAction SilentlyContinue
    
    if (-not ($hasWinget -or $hasChoco -or $hasScoop)) {
        Write-Warning "⚠ No package manager found. Please install winget, chocolatey, or scoop for automatic tool installation."
        Write-Info "Manual installation required for:"
        Write-Info "  - Oh My Posh: https://ohmyposh.dev/docs/installation/windows"
        Write-Info "  - Zoxide: https://github.com/ajeetdsouza/zoxide#installation"
        Write-Info "  - Git: https://git-scm.com/download/win"
        return
    }
    
    $tools = @(
        @{ Name = "oh-my-posh"; WingetId = "JanDeDobbeleer.OhMyPosh"; ChocoId = "oh-my-posh" },
        @{ Name = "zoxide"; WingetId = "ajeetdsouza.zoxide"; ChocoId = "zoxide" },
        @{ Name = "git"; WingetId = "Git.Git"; ChocoId = "git" }
    )
    
    foreach ($tool in $tools) {
        $toolInstalled = Get-Command $tool.Name -ErrorAction SilentlyContinue
        
        if ($toolInstalled) {
            Write-Success "✓ $($tool.Name) is already installed"
            continue
        }
        
        Write-Info "Installing $($tool.Name)..."
        
        try {
            if ($hasWinget) {
                winget install $tool.WingetId --silent --accept-source-agreements --accept-package-agreements
            } elseif ($hasChoco) {
                choco install $tool.ChocoId -y
            } elseif ($hasScoop) {
                scoop install $tool.Name
            }
            Write-Success "✓ $($tool.Name) installed successfully"
        } catch {
            Write-Warning "⚠ Failed to install $($tool.Name). Please install manually."
        }
    }
}

# Function to backup existing profile
function Backup-ExistingProfile {
    if (Test-Path $PROFILE) {
        $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $PROFILE $backupPath
        Write-Success "✓ Existing profile backed up to: $backupPath"
    }
}

# Function to create profile directory
function Initialize-ProfileDirectory {
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Success "✓ Created profile directory: $profileDir"
    }
}

# Function to copy profile files
function Copy-ProfileFiles {
    Write-Info "📋 Copying profile files..."
    
    $sourceDir = $PSScriptRoot
    $profileDir = Split-Path $PROFILE -Parent
    
    # Copy main profile
    Copy-Item -Path "$sourceDir\Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
    Write-Success "✓ Profile copied to: $PROFILE"
    
    # Copy thecyberden theme if exists
    if (Test-Path "$sourceDir\thecyberden.omp.json") {
        Copy-Item -Path "$sourceDir\thecyberden.omp.json" -Destination $profileDir -Force
        Write-Success "✓ TheCyberden theme copied"
    }
    
    # Copy modules if they exist
    if (Test-Path "$sourceDir\Modules") {
        $modulesDestination = "$profileDir\Modules"
        if (Test-Path $modulesDestination) {
            Remove-Item $modulesDestination -Recurse -Force
        }
        Copy-Item -Path "$sourceDir\Modules" -Destination $modulesDestination -Recurse -Force
        Write-Success "✓ Custom modules copied"
    }
    
    # Copy scripts if they exist
    if (Test-Path "$sourceDir\Scripts") {
        $scriptsDestination = "$profileDir\Scripts"
        if (Test-Path $scriptsDestination) {
            Remove-Item $scriptsDestination -Recurse -Force
        }
        Copy-Item -Path "$sourceDir\Scripts" -Destination $scriptsDestination -Recurse -Force
        Write-Success "✓ Scripts copied"
    }
}

# Function to update environment variables
function Update-Environment {
    Write-Info "🔄 Updating environment variables..."
    
    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Add Oh My Posh to PATH if not already there
    $ohMyPoshPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
    if ((Test-Path $ohMyPoshPath) -and ($env:PATH -notlike "*$ohMyPoshPath*")) {
        $env:PATH += ";$ohMyPoshPath"
        Write-Success "✓ Oh My Posh added to PATH"
    }
}

# Function to test profile
function Test-Profile {
    Write-Info "🧪 Testing profile..."
    
    try {
        # Test if profile can be loaded
        $null = & powershell -NoProfile -Command ". '$PROFILE'; exit 0"
        Write-Success "✓ Profile loads successfully"
        return $true
    } catch {
        Write-Error "✗ Profile failed to load: $($_.Exception.Message)"
        return $false
    }
}

# Main installation process
try {
    Write-Info "🚀 Starting installation process..."
    
    # Step 1: Install required modules
    if (-not $SkipModules) {
        Install-RequiredModules
    } else {
        Write-Info "⏭ Skipping module installation (--SkipModules)"
    }
    
    # Step 2: Install external tools
    if (-not $SkipTools) {
        Install-ExternalTools
    } else {
        Write-Info "⏭ Skipping tool installation (--SkipTools)"
    }
    
    # Step 3: Backup existing profile
    if (-not $Force) {
        Backup-ExistingProfile
    }
    
    # Step 4: Initialize profile directory
    Initialize-ProfileDirectory
    
    # Step 5: Copy profile files
    Copy-ProfileFiles
    
    # Step 6: Update environment
    Update-Environment
    
    # Step 7: Test profile
    if (Test-Profile) {
        Write-Host ""
        Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Green
        Write-Host "│                 Installation Complete!                  │" -ForegroundColor Green
        Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Green
        Write-Host "│ Your PowerShell profile has been successfully installed │" -ForegroundColor Green
        Write-Host "│                                                         │" -ForegroundColor Green
        Write-Host "│ Next steps:                                             │" -ForegroundColor Green
        Write-Host "│ 1. Restart your PowerShell session                     │" -ForegroundColor Green
        Write-Host "│ 2. Run 'neofetch' to see system information            │" -ForegroundColor Green
        Write-Host "│ 3. Run 'help-profile' to see available commands        │" -ForegroundColor Green
        Write-Host "│                                                         │" -ForegroundColor Green
        Write-Host "│ Repository: github.com/ichimbogdancristian/powershell   │" -ForegroundColor Green
        Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Green
        Write-Host ""
        Write-Info "Restart PowerShell to activate the new profile!"
    } else {
        Write-Error "Installation completed but profile test failed. Please check the logs above."
    }
    
} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    Write-Error "Please check the error above and try again."
    exit 1
}

# Optional: Open new PowerShell window with the profile
$openNew = Read-Host "Would you like to open a new PowerShell window to test the profile? (y/N)"
if ($openNew -eq 'y' -or $openNew -eq 'Y') {
    Start-Process powershell -ArgumentList "-NoExit"
}
