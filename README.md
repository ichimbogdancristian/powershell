# Po## Quick Start

**🚀 Ultra-fast installation (downloads from GitHub):**ell Enhanced Profile

A streamlined PowerShell profile with Linux-like aliases, system monitoring, and enhanced prompt that works seamlessly across both PowerShell 5.1 and PowerShell Core 7+.

## Quick Start

> **� System Compatibility**: Before installing, see [COMPATIBILITY.md](./COMPATIBILITY.md) for detailed system requirements and cross-platform compatibility information.

**�🚀 Ultra-fast installation (downloads from GitHub):**
```batch
quick-setup.bat
```

**📦 Local installation (if you have the repository):**
```powershell
# Always overwrites existing profiles
.\quick-install.ps1
```

**🧪 Test compatibility first:**
```powershell
.\quick-install.ps1 -TestCompatibility
```

## ✨ Key Features

- **🐧 Linux-like aliases**: `ll`, `la`, `grep`, `find`, `top`, `df`, `free`, etc.
- **📊 System monitoring**: `neofetch`, `health` commands with real-time stats
- **🔧 Git integration**: Enhanced git status and branch info
- **🎨 Oh My Posh themes**: Beautiful, customizable prompts with custom default theme
- **📁 Enhanced file operations**: Smart ls with colors, file type icons, and detailed views
- **⚡ Cross-platform**: Automatically installs for both PowerShell 5.1 and PowerShell Core 7+
- **🔄 Smart installation**: Always overwrites existing profiles for consistent setup

## 🎯 What Makes This Different

- **Dual PowerShell Support**: Automatically detects and installs for both PS5 and PS7
- **Always Fresh**: Overwrites existing configurations for consistent experience
- **Enhanced Compatibility**: Works in VS Code, Windows Terminal, and regular PowerShell
- **Comprehensive**: Includes modules, themes, and tools in one package

## 📋 Installation Options

### Option 1: GitHub Download (Recommended)
Downloads the latest version and completely clears profile directories for fresh installation:
```batch
quick-setup.bat
```
**⚠️ Note: This will completely remove ALL contents from your PowerShell profile directories without backups!**

### Option 2: Local Installation
If you've cloned the repository:
```powershell
# Always overwrites existing profiles (no backups)
.\quick-install.ps1

# Verbose output for troubleshooting
.\quick-install.ps1 -Verbose
```

## 🔍 Installation Details

The installer will:
1. **Detect** both PowerShell 5.1 and PowerShell Core 7+ installations
2. **Always overwrite** existing profile directories - **NO BACKUPS**
3. **Install** essential modules: PSReadLine, posh-git, Terminal-Icons
4. **Install** tools via winget: oh-my-posh, git, zoxide
5. **Copy** fresh profiles to both PowerShell versions
6. **Verify** installation success

**Installation Locations:**
- PowerShell Core: `Documents\PowerShell\` (always overwritten)
- Windows PowerShell: `Documents\WindowsPowerShell\` (always overwritten)

## Included Oh My Posh Theme

The project includes a custom `oh-my-posh-default.json` theme featuring:
- OS detection with platform icons
- Smart path display with folder icons
- Node.js and Python environment detection
- Comprehensive Git status indicators
- Execution time tracking
- Real-time clock
- Admin/root status indicator
- Optimized colors for readability

## Quick Commands After Install

```powershell
neofetch        # System information
ll              # Enhanced directory listing
health          # System health status
help-profile    # Show all available commands
```

## Theme Customization

The project uses a custom Oh My Posh theme (`oh-my-posh-default.json`) that provides:
- Multi-segment prompt with visual indicators
- Git status with branch information and changes
- Environment detection (Node.js, Python)
- Performance metrics (execution time)
- User session and admin status

To use a different theme:
```powershell
# List available themes
Get-PoshThemes

# Set a different theme temporarily
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\[theme-name].omp.json" | Invoke-Expression

# To make permanent changes, edit the profile or replace oh-my-posh-default.json
```

## 📋 System Compatibility

### Minimum Requirements
- **OS**: Windows 10 (Build 1903) or Windows 11
- **PowerShell**: PowerShell 5.1 (Windows PowerShell) OR PowerShell 7+ (PowerShell Core)
- **Memory**: 2 GB RAM minimum
- **Disk Space**: 100 MB free space
- **Internet**: Required for initial installation and tool downloads

### Supported Configurations
- ✅ **PowerShell 7.0+** (Recommended - PowerShell Core)
- ✅ **PowerShell 5.1** (Windows PowerShell - Built into Windows)
- ✅ **Windows 11** (All editions)
- ✅ **Windows 10** (Version 1903 and later)
- ✅ **Windows Server 2019/2022**
- ⚠️ **Windows Server 2016** (Limited support)

### Documents Folder Detection
The installation automatically detects Documents folders in this priority order:
1. **OneDrive Personal**: `%OneDrive%\Documents` (with localization support)
2. **OneDrive Business**: `%OneDriveCommercial%\Documents`
3. **System Documents**: `[Environment]::GetFolderPath("MyDocuments")`
4. **Fallback**: `%USERPROFILE%\Documents`

### Installation Verification
You can test compatibility and verify installations:

```powershell
# Test system compatibility
.\quick-install.ps1 -TestCompatibility

# Verify existing installation
.\quick-install.ps1 -VerifyInstallation

# Verify theme installation
.\quick-install.ps1 -VerifyTheme
```

## Troubleshooting

**Theme not loading:**
1. Ensure Oh My Posh is installed: `winget install JanDeDobbeleer.OhMyPosh`
2. Check if theme file exists in your PowerShell directory
3. Restart PowerShell after installation

**No existing profile (fresh installation):**
1. Run the main installer: `.\quick-install.ps1`
2. Ensure PowerShell execution policy allows scripts: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Restart PowerShell after installation

**Icons not displaying:**
1. Install a Nerd Font (recommended: FiraCode Nerd Font)
2. Set your terminal font to the installed Nerd Font
3. For Windows Terminal, update settings.json with the font family

**Performance issues:**
- The theme automatically optimizes for VS Code
- Disable animations if needed: `$env:POSH_DISABLE_ANIMATIONS = $true`

**Cross-platform issues:**
- The installer automatically sets up both PowerShell 5.1 and 7+ if present
- Use `$PROFILE` to check your profile location
- Manual installation: copy files to `Documents\PowerShell\` or `Documents\WindowsPowerShell\`

---

**Author:** Bogdan Ichim  
**Repository:** https://github.com/ichimbogdancristian/powershell
