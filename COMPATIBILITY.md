# PowerShell Enhanced Profile - Cross-Platform Compatibility Guide

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 (Build 1903) or Windows 11
- **PowerShell**: PowerShell 5.1 (Windows PowerShell) OR PowerShell 7+ (PowerShell Core)
- **Memory**: 2 GB RAM minimum
- **Disk Space**: 100 MB free space
- **Internet**: Required for initial installation and tool downloads

### Supported Configurations

#### PowerShell Versions
- ✅ **PowerShell 7.0+** (Recommended - PowerShell Core)
- ✅ **PowerShell 5.1** (Windows PowerShell - Built into Windows)
- ❌ PowerShell 4.0 and below (Not supported)

#### Windows Versions
- ✅ **Windows 11** (All editions)
- ✅ **Windows 10** (Version 1903 and later)
- ✅ **Windows Server 2019/2022**
- ⚠️ **Windows Server 2016** (Limited support - older PowerShell versions)
- ❌ Windows 8.1 and below (Not supported)

## Cross-Platform Path Detection

The installation automatically detects and supports various system configurations:

### Documents Folder Detection
The installer intelligently detects your Documents folder in the following priority order:

1. **OneDrive Personal Documents**
   - `%OneDrive%\Documents` (English)
   - `%OneDrive%\Documente` (Romanian)
   - `%OneDrive%\Dokumenty` (Polish)

2. **OneDrive Business Documents**
   - `%OneDriveCommercial%\Documents`
   - `%OneDriveCommercial%\Documente`

3. **System Documents Folder**
   - `[System.Environment]::GetFolderPath("MyDocuments")`
   - `%USERPROFILE%\Documents`

### Profile Installation Locations
Based on the detected Documents folder, profiles are installed to:

- **PowerShell Core (7+)**: `{Documents}\PowerShell\Microsoft.PowerShell_profile.ps1`
- **Windows PowerShell (5.1)**: `{Documents}\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

### Module Installation
Bundled modules are installed to:
- `{Documents}\PowerShell\Modules\`
- `{Documents}\WindowsPowerShell\Modules\`

The profile automatically adds these paths to `$env:PSModulePath`.

## Localization Support

### Supported Languages/Cultures
The installer supports various Windows language configurations:

- **English**: Documents folder detection
- **Romanian**: Documente folder detection  
- **Polish**: Dokumenty folder detection
- **Other languages**: Falls back to system default Documents folder

### Unicode and Character Encoding
- ✅ Full Unicode support in all scripts
- ✅ UTF-8 encoding for configuration files
- ✅ Nerd Font icons and symbols
- ✅ Emoji support in terminal output

## Environment Variable Dependencies

### Required Environment Variables
These must be available on all systems:
```powershell
$env:USERPROFILE    # User home directory
$env:USERNAME       # Current user name
$env:COMPUTERNAME   # Computer name
$env:APPDATA        # Application data folder
$env:LOCALAPPDATA   # Local application data
$env:TEMP           # Temporary files folder
```

### Optional Environment Variables
These enhance functionality when available:
```powershell
$env:OneDrive           # OneDrive Personal folder
$env:OneDriveConsumer   # OneDrive Personal (alternative)
$env:OneDriveCommercial # OneDrive for Business
$env:POSH_THEMES_PATH   # Oh My Posh themes directory
```

## Tool Dependencies

### Automatically Installed Tools
The installer will attempt to install these via `winget`:
- **Oh My Posh** - Prompt theme engine
- **Git** - Version control system  
- **Zoxide** - Smart directory navigation

### PowerShell Modules
The installer includes these modules:
- **PSReadLine** - Enhanced command line editing
- **posh-git** - Git integration for PowerShell
- **Terminal-Icons** - File type icons in terminal

## Compatibility Testing

Run the compatibility test before installation:
```powershell
.\test-compatibility.ps1
```

This will verify:
- ✅ Environment variables availability
- ✅ Documents folder detection
- ✅ PowerShell installation detection
- ✅ Required tools availability
- ✅ Module installation capability
- ✅ System configuration compatibility

## Installation Methods

### Method 1: Direct PowerShell Script (Recommended)
```powershell
# Download and run installer directly
.\quick-install.ps1
```

### Method 2: Batch File Launcher
```cmd
# Run from Command Prompt or double-click
quick-setup.bat
```

### Method 3: Manual GitHub Download
1. Download repository as ZIP
2. Extract to temporary location
3. Run `quick-install.ps1` from extracted folder

## Troubleshooting Cross-Platform Issues

### OneDrive Sync Conflicts
**Issue**: Profile files may not sync immediately across devices
**Solution**: 
- Wait for OneDrive sync to complete
- Manually force sync in OneDrive settings
- Use local Documents folder if sync is disabled

### Execution Policy Issues
**Issue**: Scripts cannot run due to execution policy
**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow scripts (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Path Length Limitations
**Issue**: Windows path length limitations (260 characters)
**Solution**: 
- Use shorter OneDrive folder names
- Enable long path support in Windows
- Choose local Documents folder over OneDrive

### Multiple PowerShell Versions
**Issue**: Profile conflicts between PowerShell 5.1 and 7+
**Solution**: 
- Installer creates separate profiles for each version
- Each profile is independent and version-specific
- No conflicts between installations

### Corporate/Restricted Environments
**Issue**: Limited install permissions or blocked tools
**Solutions**:
- Use `-NoInstall` parameter to skip tool installation
- Pre-install required tools through IT department
- Use portable versions of tools when available
- Request whitelist for required domains/tools

### Network Connectivity Issues
**Issue**: Cannot download tools or repository
**Solutions**:
- Use offline installation method
- Configure proxy settings if required
- Download tools manually and place in PATH
- Use corporate software repository if available

## Verification Commands

After installation, verify everything works:

```powershell
# Test profile loading
$PROFILE
Test-Path $PROFILE

# Test tools
oh-my-posh --version
git --version
zoxide --version

# Test modules
Get-Module PSReadLine, posh-git, Terminal-Icons -ListAvailable

# Test custom commands
ll          # Enhanced directory listing
health      # System health check
help-profile # Show available commands
```

## Support Matrix

| Feature | Win10 | Win11 | Server 2019 | Server 2022 |
|---------|-------|-------|-------------|-------------|
| Core Installation | ✅ | ✅ | ✅ | ✅ |
| OneDrive Detection | ✅ | ✅ | ⚠️ | ⚠️ |
| Tool Auto-Install | ✅ | ✅ | ⚠️ | ⚠️ |
| Unicode Support | ✅ | ✅ | ✅ | ✅ |
| PowerShell 7+ | ✅ | ✅ | ✅ | ✅ |
| Windows PowerShell | ✅ | ✅ | ✅ | ✅ |

Legend:
- ✅ Fully Supported
- ⚠️ Partial Support (may require manual configuration)
- ❌ Not Supported

## Performance Considerations

### Startup Time
- Profile loads in < 2 seconds on modern systems
- VS Code optimizations reduce overhead in integrated terminal
- Lazy loading for non-essential features

### Memory Usage
- Base profile: ~10MB additional PowerShell memory
- With all modules loaded: ~25MB additional memory
- Oh My Posh: ~5MB additional memory

### Compatibility Mode
For older or slower systems, the profile automatically:
- Disables animations in VS Code
- Reduces completion query items
- Uses lightweight color themes
- Skips heavy operations on startup

---

*This compatibility guide ensures the PowerShell Enhanced Profile works reliably across different Windows configurations, user environments, and system setups.*