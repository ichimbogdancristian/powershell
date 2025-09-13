# PowerShell Enhanced Profile

A streamlined PowerShell profile with Linux-like aliases, system monitoring, and enhanced prompt that works seamlessly across both PowerShell 5.1 and PowerShell Core 7+.

## Quick Installation

**🚀 One-click installation:**
```batch
install.bat
```

**📦 Alternative method:**
```powershell
# Download and run manually
Invoke-WebRequest -Uri "https://github.com/ichimbogdancristian/powershell/raw/main/install.bat" -OutFile "install.bat"
.\install.bat
```

## ✨ Features

- **🐧 Linux-like aliases**: `ll`, `la`, `grep`, `which`, `neofetch`, `health`
- **📊 System monitoring**: Real-time CPU, memory, and disk usage
- **🔧 Git integration**: Enhanced git status and shortcuts (`gs`, `gl`)
- **🎨 Oh My Posh themes**: Beautiful customizable prompts
- **📁 Smart navigation**: Enhanced directory listing with zoxide smart jumping (`z` command)
- **⚡ Cross-platform**: Supports both PowerShell 5.1 and 7+
- **🔄 Optimized**: Fast loading, minimal resource usage

## Installation Requirements

- **OS**: Windows 10 (1903+) or Windows 11
- **PowerShell**: 5.1 or 7+ (automatically detected)
- **Memory**: 1 GB RAM minimum
- **Internet**: Required for initial setup

## What Gets Installed

1. **PowerShell Modules**: PSReadLine, posh-git, Terminal-Icons
2. **Tools**: Oh My Posh, Git (via winget)
3. **Profile**: Enhanced PowerShell profile with custom functions
4. **Theme**: Custom Oh My Posh theme with system indicators

**Installation Locations:**
- PowerShell Core: `Documents\PowerShell\`
- Windows PowerShell: `Documents\WindowsPowerShell\`

## Available Commands

After installation, try these commands:

```powershell
neofetch        # System information
ll              # Enhanced directory listing
z documents     # Smart jump to Documents folder
health          # System health check
myip            # Show public IP
gs              # Git status
help-profile    # Show all commands
```

## System Compatibility

### Supported Configurations
- ✅ **PowerShell 7.0+** (Recommended)
- ✅ **PowerShell 5.1** (Windows built-in)
- ✅ **Windows 11** (All editions)
- ✅ **Windows 10** (Version 1903+)
- ✅ **Windows Server 2019/2022**

### Documents Folder Detection
The installer automatically detects Documents folders in this order:
1. **System Documents**: `[Environment]::GetFolderPath("MyDocuments")`
2. **User Documents**: `%USERPROFILE%\Documents`
3. **OneDrive Documents**: `%OneDrive%\Documents` (if available)

### Installation Process
The `install.bat` file automatically:
- Checks for administrator privileges
- Downloads the latest version from GitHub
- Installs required PowerShell modules (PSReadLine, posh-git, Terminal-Icons)
- Installs productivity tools (Oh My Posh, Git, Zoxide)
- Configures profiles for all PowerShell versions
- Sets up custom Oh My Posh themes

### Smart Directory Navigation with Zoxide
After installation, use the `z` command for intelligent directory jumping:
```powershell
z documents     # Jump to Documents folder
z desktop       # Jump to Desktop
z proj          # Jump to your most-used "project" folder
z pow setup     # Jump to PowerShell setup directory
```
Zoxide learns your navigation patterns and gets smarter over time!

## Theme Customization

The project includes a custom Oh My Posh theme with:
- OS detection with platform icons
- Smart path display with folder icons
- Git status indicators
- Execution time tracking
- Real-time clock and system status

To use a different theme:
```powershell
# List available themes
Get-PoshThemes

# Set a different theme (temporary)
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\[theme-name].omp.json" | Invoke-Expression
```

## Troubleshooting

**Profile not loading:**
1. Restart PowerShell after installation
2. Check execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Verify installation: `Test-Path $PROFILE`

**Theme not displaying:**
1. Install a Nerd Font (recommended: FiraCode Nerd Font)
2. Set terminal font to the Nerd Font
3. Ensure Oh My Posh is installed: `winget install JanDeDobbeleer.OhMyPosh`

**Module errors:**
1. Update PowerShell: `winget upgrade Microsoft.PowerShell`
2. Update modules: `Update-Module -Name PSReadLine,posh-git,Terminal-Icons`

**Performance issues:**
- The profile is optimized for fast loading
- Disable predictions if needed: Add `$env:POSH_DISABLE_PREDICTIONS = $true` to profile

---

**Repository:** https://github.com/ichimbogdancristian/powershell  
**Author:** Bogdan Ichim