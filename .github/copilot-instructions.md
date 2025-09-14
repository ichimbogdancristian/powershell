# Copilot Instructions for AI Coding Agents

## Project Overview
This repository provides an enhanced PowerShell profile with Linux-like aliases, system monitoring, Git integration, and a custom Oh My Posh theme. It is designed for seamless use across PowerShell 5.1 and PowerShell Core 7+ on Windows, with a focus on developer productivity and cross-platform compatibility.

## Key Components
- `Microsoft.PowerShell_profile.ps1`: Main profile script loaded by PowerShell.
- `quick-install.ps1` / `quick-setup.bat`: Automated installers for local and fresh setups.
- `oh-my-posh-default.json`: Custom Oh My Posh theme for prompt customization.
- `Modules/posh-git/`, `Modules/Terminal-Icons/`: Bundled modules for Git and file icon enhancements.
- `verify-theme.ps1`: Script to validate theme installation and configuration.

## Developer Workflows
- **Install/Update Profile:**
  - Run `quick-setup.bat` for a fresh install (removes all profile contents, no backups).
  - Run `quick-install.ps1` for local install (preserves existing configs by default).
  - Use `-CleanInstall` flag for a full reset.
- **Test Theme/Prompt:**
  - Use `verify-theme.ps1` to check prompt and theme setup.
- **Troubleshooting:**
  - See `README.md` for common issues (fonts, icons, execution policy).

## Project Conventions
- All profile scripts are designed to be idempotent and cross-version compatible.
- Custom aliases and functions are defined in the main profile or supporting scripts.
- Oh My Posh theme is referenced by default; override by editing the profile or replacing `oh-my-posh-default.json`.
- Module updates should be placed in the appropriate `Modules/` subdirectory.

## Integration Points
- **External Tools:**
  - Installs/uses: Oh My Posh, posh-git, Terminal-Icons, PSReadLine, zoxide, git (see installer scripts).
  - Uses `winget` for tool installation if available.
- **Font Requirements:**
  - Nerd Font (e.g., FiraCode Nerd Font) is required for full icon support.

## Examples
- To list files with icons: `ll`
- To check system info: `neofetch`
- To view system health: `health`
- To change prompt theme: `oh-my-posh init pwsh --config "<theme-path>" | Invoke-Expression`

## References
- See `README.md` for installation, troubleshooting, and customization details.
- Key scripts: `quick-install.ps1`, `verify-theme.ps1`, `Microsoft.PowerShell_profile.ps1`
- Custom theme: `oh-my-posh-default.json`

---
For new features or changes, follow the established patterns in the main profile and installer scripts. When in doubt, prefer explicit, cross-version compatible PowerShell code.
