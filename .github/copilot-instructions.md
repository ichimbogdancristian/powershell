# Copilot Instructions for PowerShell Enhanced Profile

## Project Overview
This project is a cross-version PowerShell enhancement suite that provides a Linux-like experience, advanced prompt, and productivity tools for both Windows PowerShell 5.1 and PowerShell Core 7+. It is designed for seamless, automated setup and robust user experience.

## Architecture & Key Components
- **quick-install.ps1**: Main installer script. Handles detection, cleaning, module/tool installation, profile deployment, and verification.
- **quick-setup.bat**: Windows batch script for GitHub-based installation and repo download.
- **Microsoft.PowerShell_profile.ps1**: The main user profile, loaded by PowerShell at startup. Imports modules, sets aliases, configures prompt, and more.
- **oh-my-posh-default.json**: Custom Oh My Posh theme for prompt styling.
- **Modules/**: Contains bundled versions of posh-git and Terminal-Icons for offline/robust installs.

## Installation & Developer Workflows
- **Install via batch**: `quick-setup.bat` (downloads and runs the installer from GitHub)
- **Install locally**: `./quick-install.ps1 [-CleanInstall] [-Verbose]` (optionally wipes old profiles)
- **Profile deployment**: Installs to both `%USERPROFILE%\Documents\PowerShell` and `%USERPROFILE%\Documents\WindowsPowerShell`.
- **Module installation**: Uses `Install-Module` for PSReadLine, posh-git, Terminal-Icons. Bundled modules are copied for redundancy.
- **Tool installation**: Uses `winget` for oh-my-posh, git, zoxide.
- **Verification**: Runs theme and font checks after install.

## Project-Specific Patterns & Conventions
- **Logging**: Use the `Log` function for all output (color-coded, respects silent/verbose flags).
- **Error Handling**: All major steps are wrapped in try/catch with user-friendly output.
- **Cleanup**: Use `Clear-TempFiles` for all temp file cleanup (handles both success and failure paths).
- **Profile logic**: Profile is robust to missing modules/tools; features degrade gracefully if dependencies are missing.
- **Theme location**: Always ensure `oh-my-posh-default.json` is present in the profile directory.

## Integration Points & External Dependencies
- **PowerShell Gallery**: For module installation (PSReadLine, posh-git, Terminal-Icons)
- **winget**: For tool installation (oh-my-posh, git, zoxide)
- **Nerd Font**: Required for full icon support in prompt and directory listings
- **Windows Terminal/VS Code**: Recommended for best experience

## Examples & Key Files
- See `quick-install.ps1` for all automation logic and conventions
- See `Microsoft.PowerShell_profile.ps1` for user experience, aliases, and prompt logic
- See `README.md` for user-facing documentation and troubleshooting

## Special Notes
- The installer is destructive with `-CleanInstall` (removes all profile contents, no backups)
- All scripts are cross-version and cross-platform aware
- No tests are included; verification is done via runtime checks and summary output

---
For more, see the project README and inline comments in each script.
