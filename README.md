# PowerShell Enhanced Profile

A streamlined PowerShell profile with Linux-like aliases, system monitoring, and enhanced prompt.

## Quick Start

**Ultra-fast installation (downloads from GitHub):**
```batch
quick-setup.bat
```

**Standard installation (if you have the repository):**
```powershell
.\quick-install.ps1
```

## Features

- **Linux-like aliases**: `ll`, `la`, `grep`, `find`, etc.
- **System monitoring**: `neofetch`, `health` commands
- **Git integration**: Enhanced git status and branch info
- **Oh My Posh themes**: Beautiful, customizable prompts with custom default theme
- **Enhanced file operations**: Smart ls, file type icons
- **Cross-platform**: Works on both Windows PowerShell 5.1 and PowerShell 7+

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
