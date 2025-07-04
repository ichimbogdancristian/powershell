# Test installation script
param([switch]$Silent, [switch]$Verbose)

function Log($msg, $type="INFO") {
    $color = switch($type) {
        "OK" { "Green" }
        "WARN" { "Yellow" } 
        "ERROR" { "Red" }
        "STEP" { "Cyan" }
        default { "White" }
    }
    
    if (-not $Silent) { 
        Write-Host "[$type] $msg" -ForegroundColor $color
    }
}

Log "Starting test..." "STEP"
Log "Test completed successfully!" "OK"
