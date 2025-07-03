# ═══════════════════════════════════════════════════════════════════════════════
# PowerShell Enhanced Profile - One-Line Installer
# Repository: https://github.com/ichimbogdancristian/powershell
# Usage: irm https://raw.githubusercontent.com/ichimbogdancristian/powershell/main/install.ps1 | iex
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [switch]$Force,
    [switch]$SkipModules,
    [switch]$SkipTools
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Variables
$repoUrl = "https://github.com/ichimbogdancristian/powershell"
$tempDir = Join-Path $env:TEMP "powershell-profile-install"
$profileDir = Split-Path $PROFILE -Parent

# Color functions
function Write-Success { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }

# Header
Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Blue
Write-Host "│          PowerShell Enhanced Profile Installer          │" -ForegroundColor Blue
Write-Host "│                  by Bogdan Ichim                        │" -ForegroundColor Blue
Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Blue
Write-Host ""

Write-Info "📥 Downloading PowerShell Enhanced Profile..."

try {
    # Clean up temp directory if it exists
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    
    # Create temp directory
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Download repository as ZIP
    $zipUrl = "$repoUrl/archive/refs/heads/main.zip"
    $zipPath = Join-Path $tempDir "powershell-main.zip"
    
    Write-Info "Downloading from: $zipUrl"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    
    # Extract ZIP
    Write-Info "📂 Extracting files..."
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # Find the extracted folder
    $extractedFolder = Get-ChildItem -Path $tempDir -Directory | Where-Object { $_.Name -like "*powershell*" } | Select-Object -First 1
    
    if (-not $extractedFolder) {
        throw "Could not find extracted repository folder"
    }
    
    $sourcePath = $extractedFolder.FullName
    Write-Success "✓ Repository downloaded and extracted"
    
    # Change to source directory and run setup
    Push-Location $sourcePath
    
    Write-Info "🚀 Running setup script..."
    
    # Build parameters for setup script
    $setupParams = @()
    if ($Force) { $setupParams += "-Force" }
    if ($SkipModules) { $setupParams += "-SkipModules" }
    if ($SkipTools) { $setupParams += "-SkipTools" }
    
    # Run setup script
    if ($setupParams) {
        & ".\setup.ps1" @setupParams
    } else {
        & ".\setup.ps1"
    }
    
    Pop-Location
    
    # Clean up
    Write-Info "🧹 Cleaning up temporary files..."
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host ""
    Write-Host "╭─────────────────────────────────────────────────────────╮" -ForegroundColor Green
    Write-Host "│              Installation Complete!                     │" -ForegroundColor Green
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Green
    Write-Host "│ PowerShell Enhanced Profile has been installed!        │" -ForegroundColor Green
    Write-Host "│                                                         │" -ForegroundColor Green
    Write-Host "│ 🎉 Restart PowerShell to activate your new profile!    │" -ForegroundColor Green
    Write-Host "│                                                         │" -ForegroundColor Green
    Write-Host "│ Try these commands:                                     │" -ForegroundColor Green
    Write-Host "│ • neofetch     - System information                    │" -ForegroundColor Green
    Write-Host "│ • help-profile - Show all commands                     │" -ForegroundColor Green
    Write-Host "│ • health       - System health check                   │" -ForegroundColor Green
    Write-Host "│                                                         │" -ForegroundColor Green
    Write-Host "│ Repository: github.com/ichimbogdancristian/powershell   │" -ForegroundColor Green
    Write-Host "╰─────────────────────────────────────────────────────────╯" -ForegroundColor Green
    
} catch {
    Write-Error "❌ Installation failed: $($_.Exception.Message)"
    Write-Info "Please try manual installation:"
    Write-Info "1. git clone $repoUrl"
    Write-Info "2. cd powershell"
    Write-Info "3. .\setup.ps1"
    
    # Clean up on error
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}
