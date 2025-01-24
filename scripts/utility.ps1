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
        [Parameter(Mandatory = $true)]
        [hashtable]$Data,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [switch]$Name
    )
    function ConvertTo-Psd1Content {
        param ($Value)
        switch ($Value) {
            { $_ -is [System.Collections.Hashtable] } {
                "@{" + ($Value.GetEnumerator() | ForEach-Object {
                    "`n    $($_.Key) = $(ConvertTo-Psd1Content $_.Value)"
                }) -join ";" + "`n}" + "`n"
            }
            { $_ -is [System.Collections.IEnumerable] -and $_ -isnot [string] } {
                "@(" + ($Value | ForEach-Object {
                    ConvertTo-Psd1Content $_
                }) -join ", " + ")"
            }
            { $_ -is [PSCustomObject] } {
                $hashTable = @{}
                $_.psobject.properties | ForEach-Object { $hashTable[$_.Name] = $_.Value }
                ConvertTo-Psd1Content $hashTable
            }
            { $_ -is [string] } { "`"$Value`"" }
            { $_ -is [int] -or $_ -is [long] -or $_ -is [bool] -or $_ -is [double] -or $_ -is [decimal] } { $_ }
            default { 
                "`"$Value`"" 
            }
        }
    }
    $fileName = if ($Name) { Split-Path $Path -Leaf } else { $null }
    $psd1Content = if ($fileName) { "# Script: $fileName`n`n" } else { "" }
    $psd1Content += "@{" + ($Data.GetEnumerator() | ForEach-Object {
        "`n    $($_.Key) = $(ConvertTo-Psd1Content $_.Value)"
    }) -join ";" + "`n" + "}"
    if (-not $psd1Content.EndsWith("}")) {
        $psd1Content += "`n}"
    }
    Set-Content -Path $Path -Value $psd1Content -Force
}