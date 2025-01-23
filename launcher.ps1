# Set error action preference
$ErrorActionPreference = 'Stop'

try {
    # Load Avalonia assemblies
    $avaloniaPath = ".\data\AvaloniaUI"
    Get-ChildItem "$avaloniaPath\*.dll" | ForEach-Object {
        Add-Type -Path $_.FullName
    }
    
    # Start the application
    & ".\scripts\interface.ps1"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}