# Script: .\launcher.ps1

$ErrorActionPreference = 'Stop'

function Initialize-Runtime {
    $runtimePath = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
    $installedVersion = (Get-ChildItem $runtimePath | Where-Object { $_.Name -like "8.0.*" } | Sort-Object Name -Descending | Select-Object -First 1).Name
    
    if (-not $installedVersion) {
        throw ".NET 8 runtime not found in: $runtimePath"
    }

    Write-Host "Using .NET runtime: $installedVersion"
    $env:DOTNET_ROOT = "C:\Program Files\dotnet"
    $env:PATH = "$runtimePath\$installedVersion;$env:PATH"
}

try {
    Initialize-Runtime
    
    $avaloniaPath = ".\data\AvaloniaUI"
    if (-not (Test-Path $avaloniaPath)) {
        throw "Avalonia directory not found"
    }

    # Load Avalonia.Desktop first as it's the entry point
    $entryDll = Join-Path $avaloniaPath "Avalonia.Desktop.dll"
    if (-not (Test-Path $entryDll)) {
        throw "Avalonia.Desktop.dll not found"
    }

    Add-Type -Path $entryDll
    & ".\scripts\interface.ps1"
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    exit 1
}