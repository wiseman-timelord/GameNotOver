# Check for Administrative Privileges
$ErrorActionPreference = 'Stop'
try {
    Write-Host "Starting GameNotOver..."
    & ".\scripts\interface.ps1"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}