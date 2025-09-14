# PowerShell Enhanced Profile

An opinionated, reproducible PowerShell profile stack (prompt, aliases, utilities) that installs identically for **Windows PowerShell 5.1** and **PowerShell (Core) 7+**. Ships with a custom Oh My Posh theme, vendored module versions, Linux‑like ergonomics, and diagnostics helpers—all in a single repo for fast bootstrap or repeatable workstation setup.

## Quick Start

**🚀 Zero-dependency remote install (downloads fresh copy & wipes existing profiles):**
```batch
quick-setup.bat
```

**📦 Local installation (cloned repo already present):**
```powershell
# Completely clean install (DESTROYS existing profile dirs, NO BACKUPS)
\.\quick-install.ps1 -CleanInstall

# Non-destructive install (adds/replaces only managed files if they exist)
\.\quick-install.ps1
```

## ✨ Key Features

- **🐧 Linux-like aliases**: `ll`, `la`, `grep`, `find`, `top`, `df`, `free`, etc.
- **📊 System/host introspection**: `neofetch`, `health`, path + env helpers
- **🔧 Git integration**: Enhanced branch & status prompt (via posh-git + custom theme)
- **🎨 Custom prompt theme**: `oh-my-posh-default.json` optimized for glyph readability & context density
- **📁 Rich directory listings**: Icons + color (Terminal-Icons) with intuitive aliases
- **⚡ Dual-engine support**: Installs to both PS5.1 + PS7 profile roots in one run
- **🧩 Vendored modules**: `Modules/posh-git/<version>` & `Modules/Terminal-Icons/<version>` for offline / deterministic installs
- **� Idempotent installer**: Safe mode (default) or deliberate destructive mode (`-CleanInstall`)
- **🔁 Fast iteration**: Edit profile then reload in-session (`. $PROFILE` or `reload-profile` alias)

## 🎯 What Makes This Different

- **One authoritative profile**: Single `Microsoft.PowerShell_profile.ps1` copied to both engine roots
- **Deterministic setup**: Vendored module versions avoid PSGallery drift (PSGallery install attempted only if not present)
- **Explicitly destructive flag**: `-CleanInstall` nukes contents of `Documents/PowerShell` & `Documents/WindowsPowerShell` (NO BACKUPS). This is intentional for fresh, reproducible environments.
- **Graceful degradation**: winget/tool failures log WARN/ERROR but do not abort entire install
- **UTF-8 enforced**: Ensures emoji / glyph reliability across terminals
- **Developer-friendly**: Clear section headers & isolated destructive logic (`Clear-OldProfiles`) ease contribution

## 📋 Installation Options

### Option 1: GitHub Download (Recommended)
Downloads the latest version and completely clears profile directories for fresh installation:
```batch
quick-setup.bat
```
**⚠️ IRREVERSIBLE:** Deletes ALL contents of your PowerShell profile directories (no backups created). Only use if you intentionally want a clean slate.

### Option 2: Local Installation
If you've cloned the repository:
```powershell
# Complete clean install (destructive)
\.\quick-install.ps1 -CleanInstall

# Incremental install (non-destructive)
\.\quick-install.ps1

# Verbose troubleshooting output
\.\quick-install.ps1 -CleanInstall -Verbose
```

## 🔍 Installation Details

The installer will:
1. **Detect** PS5.1 + PS7 presence
2. **Optionally purge** both profile roots (`-CleanInstall`)
3. **Install / ensure modules**: PSReadLine, posh-git, Terminal-Icons (skip if already available)
4. **Install tools via winget** (if winget + tool absent): oh-my-posh, git, zoxide
5. **Copy assets**: profile, theme, verification script, vendored `Modules` directory
6. **Write UTF-8** profile to preserve glyphs
7. **Summarize + verify** success status per engine

**Installation Locations:**
- PowerShell Core: `Documents\PowerShell\` (completely cleared and repopulated)
- Windows PowerShell: `Documents\WindowsPowerShell\` (completely cleared and repopulated)

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

## Development & Contribution

| Task | Command / Notes |
|------|-----------------|
 Reload after edits | `. $PROFILE` (or `reload-profile` alias if present) |
 Lint profile | `Invoke-ScriptAnalyzer -Path Microsoft.PowerShell_profile.ps1` |
 Verify theme | `./verify-theme.ps1` or `Test-OhMyPoshTheme` function |
 Check functions loaded | `help-profile` |
 Inspect path segments | `Show-Path` |
 Clipboard helpers | `Copy-ToClipboard`, `Get-ClipboardContent` (legacy alias: `Paste-FromClipboard`) |

Naming: Use approved PowerShell verbs (`Get`, `Set`, `Test`, etc.). Provide backward compatibility aliases when renaming (see `Get-ClipboardContent`).

Add new utilities near logically labeled sections (box-drawing separators). Keep functions focused & pipeline-friendly (avoid writing host output unless status/color is needed).

Destructive logic lives in installer (`Clear-OldProfiles`)—extend there; do not scatter file deletes.

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
- Theme adapts to environment; disable animations: `$env:POSH_DISABLE_ANIMATIONS = $true`

**Cross-platform issues:**
- Installer targets both versions automatically
- Check active profile: `$PROFILE`
- Manual placement: copy profile + theme + `Modules` to each profile root

---

## FAQ

**Q: Does `-CleanInstall` back up anything?**  
No. It forcefully empties the profile directories. Create your own backup beforehand if needed.

**Q: Why vendor modules if PSGallery installs them anyway?**  
Deterministic/offline installs. Vendored copy ensures baseline while still allowing newer versions via PSGallery outside this repo.

**Q: Why enforce UTF-8 writes?**  
Prevents broken glyphs/emojis in prompts across terminals and editors.

**Q: Can I safely rename aliases?**  
Add new alias first, keep old one temporarily with a comment, then remove in a later cleanup pass.

---

**Author:** Bogdan Ichim  
**Repository:** https://github.com/ichimbogdancristian/powershell

---
If something feels unclear or you want a leaner quick-start section, open an issue or PR.
