# PowerShell Profile Compatibility Test
Write-Host "PowerShell Profile Compatibility Test" -ForegroundColor Cyan

# Test Documents folder detection
Write-Host "`nTesting Documents folder detection..." -ForegroundColor Yellow
$docs = @(
    "$env:OneDrive\Documents",
    "$env:OneDrive\Documente",
    [Environment]::GetFolderPath("MyDocuments"),
    "$env:USERPROFILE\Documents"
)

$foundDocs = $docs | Where-Object { $_ -and (Test-Path $_) }
Write-Host "Found $($foundDocs.Count) Documents locations:" -ForegroundColor Green
$foundDocs | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# Test PowerShell installations
Write-Host "`nTesting PowerShell installations..." -ForegroundColor Yellow
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
$powershell = Get-Command powershell -ErrorAction SilentlyContinue

if ($pwsh) { Write-Host "  PowerShell Core: Found" -ForegroundColor Green }
else { Write-Host "  PowerShell Core: Not found" -ForegroundColor Red }

if ($powershell) { Write-Host "  Windows PowerShell: Found" -ForegroundColor Green }
else { Write-Host "  Windows PowerShell: Not found" -ForegroundColor Red }

# Test profile files
Write-Host "`nTesting profile files..." -ForegroundColor Yellow
if ($foundDocs.Count -gt 0) {
    $mainDoc = $foundDocs[0]
    $profiles = @(
        "$mainDoc\PowerShell\Microsoft.PowerShell_profile.ps1",
        "$mainDoc\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    )
    
    foreach ($profilePath in $profiles) {
        if (Test-Path $profilePath) {
            Write-Host "  Profile found: $profilePath" -ForegroundColor Green
        } else {
            Write-Host "  Profile missing: $profilePath" -ForegroundColor Red
        }
    }
}

# Test tools
Write-Host "`nTesting required tools..." -ForegroundColor Yellow
$tools = @("oh-my-posh", "git", "zoxide")
foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "  ${tool}: Found" -ForegroundColor Green
    } else {
        Write-Host "  ${tool}: Not found" -ForegroundColor Red
    }
}

Write-Host "`nCompatibility test completed!" -ForegroundColor Cyan