# Script: ".\launcher.ps1"
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'

try {
    Add-Type -AssemblyName PresentationFramework
    
    # Get absolute paths
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    
    $interfacePath = Join-Path $scriptRoot "scripts\interface.ps1"
    if (-not (Test-Path $interfacePath)) {
        throw "Required interface script not found at: $interfacePath"
    }
    
    # Source the interface script
    . $interfacePath
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Debug ($_ | Format-List -Force | Out-String)
    exit 1
}