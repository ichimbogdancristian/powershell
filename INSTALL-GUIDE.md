# PowerShell Enhanced Profile - Simplified Installation

This repository provides three installation options, from ultra-fast to detailed feedback.

## Installation Options

### Option 1: Ultra-Quick Install (Recommended)
```batch
quick-setup.bat
```
- **Fully unattended** - No prompts, auto-closes in 3 seconds
- **Silent mode** - Minimal output, perfect for automation
- **Fastest** - Ideal for bulk deployment or quick setup

### Option 2: Quick Install with Progress
```powershell
.\quick-install.ps1
```
- **Unattended** but shows installation progress
- **Compact output** - Essential information only
- **Error handling** - Continues on minor issues

### Option 3: Detailed Install (Advanced)
```powershell
.\install_new.ps1
```
- **Full feedback** - Complete installation progress
- **Better error handling** - Graceful failure recovery
- **Options support** - Use `-Quiet` for silent mode, `-Force` to skip backups

## What Gets Installed

All installation methods install the same components:

**PowerShell Modules:**
- PSReadLine (enhanced command line editing)
- posh-git (Git integration)
- Terminal-Icons (file type icons)

**External Tools:**
- Oh My Posh (prompt theming)
- Git (version control)

**Profile Features:**
- Linux-like aliases (`ll`, `la`, `grep`, etc.)
- System monitoring (`health`, `neofetch`)
- Enhanced navigation and file operations
- Git status integration
- Custom prompt with Oh My Posh

## Installation Comparison

| Method | Speed | Output | Interaction | Best For |
|--------|--------|--------|-------------|----------|
| `quick-setup.bat` | Fastest | Minimal | None | Automation, bulk deployment |
| `quick-install.ps1` | Fast | Compact | None | Personal use, quick setup |
| `install_new.ps1` | Standard | Detailed | Optional | Troubleshooting, customization |

## File Structure

The repository now contains only essential files:

```
powershell/
├── quick-setup.bat          # Ultra-fast silent installer
├── quick-install.ps1        # Compact PowerShell installer
├── install_new.ps1          # Detailed installer with advanced options
├── Microsoft.PowerShell_profile.ps1  # Main PowerShell profile
├── oh-my-posh-default.json # Oh My Posh theme configuration
├── Modules/                 # Custom PowerShell modules
│   ├── posh-git/           # Git integration module
│   └── Terminal-Icons/     # File type icons module
└── INSTALL-GUIDE.md        # This installation guide
```

## Requirements

- **Windows 10/11** with PowerShell 5.1+
- **Internet connection** for downloading modules and tools
- **Winget** (recommended) or other package manager for tools

## Post-Installation

After installation:
1. **Restart PowerShell** to activate the new profile
2. Try these commands:
   - `neofetch` - System information
   - `ll` - Enhanced directory listing
   - `health` - System health status
   - `help-profile` - Show all available commands

## Troubleshooting

If installation fails:
1. **Run as Administrator**
2. **Check internet connection**
3. **Temporarily disable antivirus**
4. **Use the detailed installer:** `.\install_new.ps1`

## Uninstallation

To remove the profile:
```powershell
Remove-Item $PROFILE -Force
Remove-Item (Split-Path $PROFILE)\oh-my-posh-default.json -Force
Remove-Item (Split-Path $PROFILE)\Modules -Recurse -Force
```

---

**Repository:** https://github.com/ichimbogdancristian/powershell  
**Author:** Bogdan Ichim
