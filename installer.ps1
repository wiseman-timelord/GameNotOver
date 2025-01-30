# Script: ".\installer.ps1"
$ErrorActionPreference = 'Stop'

# Directory Creation
function Initialize-Directories {
    @(".\scripts", ".\data") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
}

# Configuration Creation
function Create-DefaultConfiguration {
    $configPath = ".\data\configuration.psd1"
    if (Test-Path $configPath) {
        $overwrite = Read-Host "Configuration file already exists. Overwrite? (Y/N)"
        if ($overwrite -ne 'Y') {
            Write-Host "Configuration file not overwritten." -ForegroundColor Yellow
            return
        }
    }

    $defaultConfig = @"
@{
    'Fallout' = @('f4se_loader', 'Fallout4', 'Fallout4Launcher', 'Fallout3', 'FalloutNV')
    'Skyrim' = @('Skyrim', 'SkyrimSE')
    'PaintShop' = @('Paint Shop Pro 9', 'Paint Shop Pro 8', 'Corel PaintShop Pro')
    'ChatGPT' = @('ChatGPT')
    'Edge' = @('msedgewebview2', 'MicrosoftEdgeUpdate')
    'Brave' = @('brave', 'BraveCrashHandler', 'BraveCrashHandler64')
}
"@

    Set-Content -Path $configPath -Value $defaultConfig -Force
    Write-Host "Configuration initialized successfully!" -ForegroundColor Green
}

# Main Installation
try {
    Initialize-Directories
    Create-DefaultConfiguration
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}