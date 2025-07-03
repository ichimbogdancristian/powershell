# PowerShell Enhanced Profile - Quick Start Guide

## Installation
1. Run `setup.ps1` to install all required dependencies
2. Restart PowerShell to load the new profile

## Features

### 🎨 Oh My Posh Theme
- Custom theme with boxes showing:
  - Current date and time
  - Current directory path
  - Git status (if in a git repository)
  - Command execution status
  - User session information
  - Shell information
  - Command execution time

### 🔍 Enhanced History & Autocompletion
- Predictive IntelliSense based on command history
- ListView for predictions
- Enhanced tab completion
- Linux-style history navigation with arrow keys

### 🐧 Linux-like Aliases
- **File Operations**: `ls`, `ll`, `la`, `cat`, `grep`, `find`, `touch`, `rm`, `mv`, `cp`, `mkdir`
- **System**: `ps`, `kill`, `top`, `ping`, `which`, `sudo`, `pwd`, `cd`
- **Network**: `wget`, `curl`, `nslookup`
- **System Info**: `neofetch`, `df`, `free`, `uptime`, `health`
- **Git**: `g`, `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, `gb`, `gco`

### 📊 System Health Monitoring
- Real-time CPU, Memory, and Disk usage
- Color-coded health indicators
- Detailed system information with `neofetch`
- Health check with `health` command

### 🗂️ Smart Navigation
- **Zoxide**: Use `z <directory>` for smart directory jumping
- **Enhanced cd**: Use `cd -` to go back to the previous directory
- **mkdir**: Creates directory and navigates to it

### 🎯 Quick Commands
- `ll` - Detailed file listing with colors
- `la` - Show all files including hidden
- `neofetch` - System information display
- `health` - System health check
- `reload-profile` - Reload PowerShell profile
- `edit-profile` - Edit profile in VS Code

### 🔧 Advanced Features
- **Custom Prompt**: Two-line prompt with user@host, path, and git status
- **Error Handling**: Better error messages and formatting
- **Tab Completion**: Enhanced for git commands and directories
- **File Icons**: Beautiful file icons with Terminal-Icons module
- **Git Integration**: posh-git for enhanced Git support

### 📋 Useful Keybindings
- **Ctrl+D**: Delete character
- **Ctrl+W**: Delete word backward
- **Alt+D**: Delete word forward
- **Ctrl+Left/Right**: Move by word
- **Ctrl+Z**: Undo
- **Ctrl+Y**: Redo
- **Up/Down**: History search

### 🎨 Color Scheme
- **Directories**: Different colors for easy identification
- **Files**: Color-coded based on file type
- **Git Status**: Color-coded git information
- **Health Status**: Green (good), Yellow (warning), Red (critical)

### 📝 Profile Functions
- `Edit-Profile` - Edit the PowerShell profile
- `Reload-Profile` - Reload the profile without restarting
- `Show-Path` - Display PATH environment variable
- `Find-Process <name>` - Find processes by name
- `Get-NetworkConnections` - Show active network connections

## ⚙️ Customization

### Custom Theme
Edit `thecyberden.omp.json` to customize your Oh My Posh theme:

```powershell
oh-my-posh init pwsh --config .\thecyberden.omp.json --print
```

### Adding Custom Functions
Edit the profile file:

```powershell
edit-profile
```

Add your custom functions in the "Custom Functions" section.

### Environment Variables
The profile sets up useful environment shortcuts:

```powershell
$env:DOCS = "$env:USERPROFILE\Documents"
$env:DOWNLOADS = "$env:USERPROFILE\Downloads"
```

## Troubleshooting
- If execution policy issues occur, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- If Oh My Posh doesn't load, check if it's installed with `oh-my-posh --version`
- If zoxide doesn't work, check installation with `zoxide --version`

Enjoy your enhanced PowerShell experience! 🚀
