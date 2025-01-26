# Script: ".\scripts\utility.ps1"
function Import-GameConfiguration {
    param ([string]$Path = ".\data\configuration.psd1")
    if (-not (Test-Path $Path)) { throw "Configuration file not found: $Path" }
    try {
        $config = Import-PowerShellData1 -Path $Path
        if (-not $config.Categories) {
            throw "Invalid configuration format: Missing Categories"
        }
        return $config
    } catch {
        throw "Configuration validation failed: $_"
    }
}

function Save-GameConfiguration {
    param (
        [Parameter(Mandatory)][hashtable]$Config,
        [string]$Path = ".\data\configuration.psd1"
    )
    if (-not $Config.Categories) {
        throw "Invalid configuration format: Missing Categories"
    }
    Export-PowerShellData1 -Data $Config -Path $Path -Name
}

function Get-ProcessCount {
    param ([Parameter(Mandatory)][string[]]$ProcessNames)
    $count = 0
    foreach ($name in $ProcessNames) {
        $count += @(Get-Process -Name $name -ErrorAction SilentlyContinue).Count
    }
    return $count
}

function Stop-GameProcesses {
    param ([Parameter(Mandatory)][string[]]$ProcessNames)
    $terminated = $false
    foreach ($name in $ProcessNames) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($procs) {
            $procs | Stop-Process -Force
            $terminated = $true
        }
    }
    return $terminated
}

function Import-PowerShellData1 {
    param (
        [string]$Path
    )
    $content = Get-Content -Path $Path -Raw
    $content = $content -replace '^(#.*[\r\n]*)+', '' # Remove lines starting with '#'
    $content = $content -replace '\bTrue\b', '$true' -replace '\bFalse\b', '$false'
    $scriptBlock = [scriptblock]::Create($content)
    $data = . $scriptBlock
    return $data
}

function Export-PowerShellData1 {
    param (
        [Parameter(Mandatory)][hashtable]$Data,
        [Parameter(Mandatory)][string]$Path
    )
    $psd1Content = "@{`n"
    foreach ($key in $Data.Keys) {
        $psd1Content += "    $key = @{`n"
        foreach ($subKey in $Data[$key].Keys) {
            $psd1Content += "        $subKey = @("
            # Properly format each process name as a string
            $processList = $Data[$key][$subKey] | ForEach-Object { "'$_'" }
            $psd1Content += $processList -join ", "
            $psd1Content += ")`n"
        }
        $psd1Content += "    }`n"
    }
    $psd1Content += "}"
    Set-Content -Path $Path -Value $psd1Content -Force
}