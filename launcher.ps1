# Script: ".\launcher.ps1"
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'

try {
    Add-Type -AssemblyName PresentationFramework
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptPath
    
    if (-not (Test-Path ".\scripts\interface.ps1")) {
        throw "Required interface script not found."
    }
    
    & ".\scripts\interface.ps1"
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Debug ($_ | Format-List -Force | Out-String)
    exit 1
}