
# PowerShell Enhanced Profile

An advanced, cross-version PowerShell enhancement suite providing a Linux-like experience, productivity tools, and a beautiful prompt for both Windows PowerShell 5.1 and PowerShell Core 7+. Designed for seamless, automated setup and robust user experience on Windows.


## 🚀 Quick Start

**Recommended (GitHub download & clean install):**
```batch
quick-setup.bat
```

**Local install (if repo is cloned):**
```powershell
# Clean install (removes all profile contents, no backups)
./quick-install.ps1 -CleanInstall

# Preserve existing configs
./quick-install.ps1
```


## ✨ Key Features

- **🐧 Linux-like aliases**: `ll`, `la`, `grep`, `find`, `top`, `df`, `free`, etc.
- **📊 System monitoring**: `neofetch`, `health` commands with real-time stats
- **🔧 Git integration**: Enhanced git status and branch info
- **🎨 Oh My Posh themes**: Custom, beautiful prompt with platform, git, and system info
- **📁 Enhanced file operations**: Smart `ls` with icons, colors, and details
- **⚡ Cross-platform**: Installs for both PowerShell 5.1 and 7+ automatically
- **🔄 Smart installation**: Clean install option, automatic backups, cross-version support


## 🛠️ Requirements

- **OS**: Windows 10/11 (or Server 2019/2022)
- **PowerShell**: 5.1 and/or 7+
- **Internet**: Required for first-time setup


## 📦 What Gets Installed

1. **PowerShell Modules**: PSReadLine, posh-git, Terminal-Icons (from Gallery or bundled)
2. **Tools**: Oh My Posh, Git, Zoxide (via winget)
3. **Profile**: Unified, robust PowerShell profile with aliases, prompt, and helpers
4. **Theme**: Custom Oh My Posh theme (`oh-my-posh-default.json`)

**Profile Locations:**
- PowerShell Core: `Documents\PowerShell\`
- Windows PowerShell: `Documents\WindowsPowerShell\`


## 🏁 Example Commands

```powershell
neofetch        # System information
ll              # Enhanced directory listing
health          # System health status
help-profile    # Show all available commands
z <dir>         # Smart jump (if zoxide installed)
```


## 🧠 How It Works

- Detects all installed PowerShell versions and deploys profiles to both
- Cleans profile directories if `-CleanInstall` is used (no backups)
- Installs modules from Gallery or uses bundled versions for reliability
- Installs tools via `winget` if available
- Verifies theme and font setup after install


## 🎨 Theme Customization

The included `oh-my-posh-default.json` theme provides:
- OS and platform icons
- Smart path and folder icons
- Git status, branch, and change indicators
- Node.js and Python environment detection
- Execution time, clock, and admin status

To use a different theme:
```powershell
# List available themes
Get-PoshThemes

# Set a different theme temporarily
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\[theme-name].omp.json" | Invoke-Expression
# To make permanent, edit the profile or replace oh-my-posh-default.json
```


## 🛠️ Troubleshooting

**Theme not loading:**
1. Ensure Oh My Posh is installed: `winget install JanDeDobbeleer.OhMyPosh`
2. Check if theme file exists in your PowerShell directory
3. Restart PowerShell after installation

**Icons not displaying:**
1. Install a Nerd Font (e.g., FiraCode Nerd Font)
2. Set your terminal font to the Nerd Font

**Profile not loading:**
1. Run the installer again
2. Check execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Restart PowerShell

**Module errors:**
1. Update PowerShell: `winget upgrade Microsoft.PowerShell`
2. Update modules: `Update-Module -Name PSReadLine,posh-git,Terminal-Icons`

**Performance issues:**
- The profile is optimized for fast loading
- Disable animations: `$env:POSH_DISABLE_ANIMATIONS = $true`

---


---

**Repository:** https://github.com/ichimbogdancristian/powershell
**Author:** Bogdan Ichim