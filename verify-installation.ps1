# Cross-platform installation verification script
# Uses the same logic as the main installer to detect profile locations

# Detect Documents folder using same logic as installer
$documentsPaths = @(
    "$env:OneDrive\Documents",
    "$env:OneDrive\Documente",  # Romanian localization
    "$env:OneDrive\Dokumenty",  # Polish localization
    "$env:OneDriveConsumer\Documents",
    "$env:OneDriveConsumer\Documente",
    "$env:OneDriveCommercial\Documents", 
    "$env:OneDriveCommercial\Documente",
    [Environment]::GetFolderPath("MyDocuments"),
    "$env:USERPROFILE\Documents"
)

# Find the actual Documents folder that exists
$documentsPath = $null
foreach ($path in $documentsPaths) {
    if ($path -and (Test-Path $path)) {
        $documentsPath = $path
        break
    }
}

# Fallback if no Documents folder found
if (-not $documentsPath) {
    $documentsPath = "$env:USERPROFILE\Documents"
}

# Generate profile locations based on detected Documents path
$profileLocations = @(
    "$documentsPath\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$documentsPath\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)

$foundProfiles = @()
foreach ($location in $profileLocations) {
    if (Test-Path $location) {
        $foundProfiles += $location
    }
}

if ($foundProfiles.Count -gt 0) {
    Write-Host "[OK] PowerShell profile found in target location" -ForegroundColor Green
    foreach ($foundPath in $foundProfiles) {
        Write-Host "  Found: $foundPath" -ForegroundColor Gray
    }
    exit 0
} else {
    Write-Host "[ERROR] PowerShell profile not found in any target location" -ForegroundColor Red
    Write-Host "Expected locations:" -ForegroundColor Yellow
    foreach ($location in $profileLocations) {
        Write-Host "  Expected: $location" -ForegroundColor Gray
    }
    exit 1
}