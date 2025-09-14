# AI Coding Agent Instructions

Purpose: Help an AI assistant quickly understand and work productively in this repository. This project delivers an "enhanced" PowerShell profile (prompt, aliases, tooling bootstrap) that installs seamlessly for both Windows PowerShell 5.1 and PowerShell (Core) 7+.

## 1. Core Concepts & Architecture
- Single authoritative profile file: `Microsoft.PowerShell_profile.ps1` (feature hub: aliases, functions, prompt setup, utilities, diagnostics).
- Installer scripts:
  - `quick-install.ps1`: Idempotent multi-version installer; handles modules (PSGallery) + tools (winget) + copying profile/theme/modules.
  - `quick-setup.bat`: Zero‑dependency bootstrap (download repo ZIP from GitHub, extract, invoke `quick-install.ps1 -CleanInstall`).
  - `verify-theme.ps1`: Post-install validation for Oh My Posh theme + environment.
- Bundled modules (kept vendor-style under `Modules/`) for offline or deterministic installs: `posh-git`, `Terminal-Icons` (specific versions nested by version folder).
- Custom Oh My Posh theme: `oh-my-posh-default.json` expected to live alongside the profile in each user profile directory.

## 2. Key Workflows
- Fresh remote install: run `quick-setup.bat` (clears target profile dirs; no backups!).
- Local install/update (safe by default): `./quick-install.ps1` (add `-CleanInstall` to wipe profile dirs completely, still no backups by design — emphasize this in UX changes).
- Post-install verification: run `verify-theme.ps1` or commands: `neofetch`, `ll`, `health`, `help-profile`.
- Development iteration: edit `Microsoft.PowerShell_profile.ps1`, then reload with `. $PROFILE` or custom alias if present (e.g., `reload-profile`).

## 3. Conventions & Patterns
- Verb naming: Follow PowerShell approved verbs (recent rename example: `Paste-FromClipboard` -> `Get-ClipboardContent`). Use `Get-Verb` if uncertain.
- Cross-version support: Always treat both profile roots (`Documents\PowerShell` and `Documents\WindowsPowerShell`)—the installer loops detected versions; avoid hardcoding one path.
- Output style in installer: Central `Log` function with type tokens (INFO, STEP, OK, WARN, ERROR, CLEAN) controlling color; preserve pattern if extending.
- Encoding: Profiles written explicitly as UTF-8 to preserve emojis/icons; replicate `[System.IO.File]::WriteAllText(..., [System.Text.Encoding]::UTF8)` when creating new files during install.
- Module vendoring: Keep original structure (ModuleName/Version/*). When adding a new vendored module, follow same layout.
- Aliases: Provide short Unix-like commands (`ll`, `la`, etc.) plus discoverability helper like `help-profile` (ensure new clusters of functions have an aggregated help or listing function if expanding scope).

## 4. Safety & Idempotency
- `-CleanInstall` path intentionally destructive (no backups). If changing behavior, document prominently in README and installer output banners.
- Script must succeed even if some optional components fail (winget missing, module install failures); current pattern: log WARN/ERROR and continue where feasible.
- Avoid introducing interactive prompts—automation friendliness is a goal.

## 5. External Dependencies
- PSGallery modules: `PSReadLine`, `posh-git`, `Terminal-Icons`.
- winget tools: `oh-my-posh`, `git`, `zoxide` (only installed if not already present and winget available).
- Theme + icons assume a Nerd Font; verification script hints at FiraCode Nerd Font.

## 6. Typical Extension Points (Good PR Targets)
- Add new utility functions (network, diagnostics) inside profile near existing logical section headers framed by box-drawing separators.
- Expand `verify-theme.ps1` to validate font glyph rendering more robustly (currently heuristic placeholder).
- Add optional environment toggles (e.g., disable heavy features in constrained terminals—follow existing env var patterns like `$env:POSH_DISABLE_ANIMATIONS`).

## 7. Testing & Validation Hints
- Quick lint: `Invoke-ScriptAnalyzer -Path Microsoft.PowerShell_profile.ps1` (focus on naming + style rules when modifying functions).
- Smoke reload after edits: `. $PROFILE` then exercise a changed function.
- Install flow dry-run: Temporarily mock (or comment out) destructive portions when experimenting with logic—never commit mocks.

## 8. Style & Structural Markers
- Section separators use heavy box drawing lines; keep consistent for readability.
- Prefer small single-purpose functions with clear names; return values explicitly when output is consumed.
- Use `Write-Host` only for user-facing colored status; use standard output for pipeline-friendly data.

## 9. Adding New Installer Steps
- Gate external calls with `Get-Command` checks.
- Reuse `Log` with appropriate type to maintain uniform console UX.
- Keep destructive actions isolated (currently `Clear-OldProfiles`). Extend there rather than scattering deletes.

## 10. Do / Avoid Summary
- DO ensure both PS5.1 and PS7 locations updated.
- DO use approved verbs.
- DO maintain UTF-8 encoding.
- AVOID interactive Read-Host prompts in automation path.
- AVOID silent breaking changes to alias names (add compatibility alias first, then deprecate with a warning if needed).

## 11. Quick Reference Paths
- Profile sources: root repo files copied into: `%UserProfile%\Documents\PowerShell` and `%UserProfile%\Documents\WindowsPowerShell`.
- Theme file destination: same directory as profile (mirrors repo name).

---
Feedback welcome: If any conventions above seem incomplete (e.g., alias taxonomy, help generator strategy), specify and this guide can be refined.
