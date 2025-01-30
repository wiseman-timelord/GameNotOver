# Script: ".\scripts\utility.ps1"

function Import-GameConfiguration {
    param (
        [string]$Path = (Join-Path $PSScriptRoot "..\data\configuration.psd1")
    )
    
    if (-not (Test-Path $Path)) { 
        Write-Warning "Configuration file not found: $Path"
        return @{}  # Changed from Categories structure
    }
    
    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Configuration file is empty"
        }
        
        $config = Import-PowerShellData1 -Path $Path
        if (-not $config) {
            throw "Invalid configuration format"
        }
        
        # Validate process arrays
        foreach ($key in $config.Keys) {
            $processes = $config[$key]
            if ($processes -isnot [array]) {
                throw "Invalid process list format for $key"
            }
        }
        
        return $config
    } 
    catch {
        Write-Warning "Configuration validation failed: $_"
        return @{}  # Changed from Categories structure
    }
}

function Save-GameConfiguration {
    param (
        [Parameter(Mandatory)][hashtable]$Config,
        [string]$Path = (Join-Path $PSScriptRoot "..\data\configuration.psd1")
    )
    
    try {
        # Ensure directory exists
        $configDir = Split-Path -Parent $Path
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Create backup before saving
        $backupPath = "$Path.backup"
        if (Test-Path $Path) {
            Copy-Item -Path $Path -Destination $backupPath -Force
        }
        
        Export-PowerShellData1 -Data $Config -Path $Path
        
        # Verify the saved file
        $testImport = Import-GameConfiguration -Path $Path
        if (-not $testImport -or -not $testImport.Categories) {
            throw "Configuration verification failed"
        }
        
        # Remove backup on success
        if (Test-Path $backupPath) {
            Remove-Item $backupPath -Force
        }
    }
    catch {
        # Restore from backup on failure
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $Path -Force
            Remove-Item $backupPath -Force
        }
        throw "Failed to save configuration: $_"
    }
}

function Get-ProcessCount {
    param (
        [Parameter(Mandatory)][string[]]$ProcessNames
    )
    
    $count = 0
    Write-Debug "Checking processes: $($ProcessNames -join ', ')"
    
    foreach ($name in $ProcessNames) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        
        try {
            # Clean the name
            $cleanName = $name -replace '\.exe$', ''
            Write-Debug "Checking for process: $cleanName"
            
            $processes = Get-Process -Name $cleanName -ErrorAction SilentlyContinue
            if ($processes) {
                $currentCount = @($processes).Count
                Write-Debug "Found $currentCount instance(s) of $cleanName"
                $count += $currentCount
            }
        }
        catch {
            Write-Debug "Error counting process '$name': $_"
        }
    }
    
    Write-Debug "Total count for $($ProcessNames -join ', '): $count"
    return $count
}

function Stop-GameProcesses {
    param (
        [Parameter(Mandatory)][string[]]$ProcessNames
    )
    
    $terminated = $false
    $errors = @()
    
    foreach ($name in $ProcessNames) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        
        try {
            $procs = Get-Process -Name $name -ErrorAction Stop
            foreach ($proc in $procs) {
                try {
                    # Skip system processes
                    if ($proc.SessionId -eq 0) {
                        $errors += "Skipped system process $($proc.Name) (PID: $($proc.Id))"
                        continue
                    }
                    
                    $proc | Stop-Process -Force -ErrorAction Stop
                    $terminated = $true
                }
                catch {
                    $errors += "Failed to stop process $($proc.Name) (PID: $($proc.Id)): $_"
                }
            }
        }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            # Process not found - silent continue
            continue
        }
        catch {
            if ($_.Exception.Message -notmatch 'Cannot find a process') {
                $errors += "Error accessing process '$name': $_"
            }
        }
    }
    
    if ($errors) {
        Write-Warning ($errors -join "`n")
    }
    
    return $terminated
}

function Import-PowerShellData1 {
    param ([string]$Path)
    
    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Empty configuration file"
        }
        
        # Clean up the content
        $content = $content -replace '(?m)^\s*#.*$', '' # Remove comments
        $content = $content -replace '(?ms)/\*.*?\*/', '' # Remove block comments
        $content = $content -replace '\bTrue\b', '$true' -replace '\bFalse\b', '$false'
        
        # Basic syntax validation
        if ($content -notmatch '^\s*@{' -or $content -notmatch '}\s*$') {
            throw "Invalid hashtable format"
        }
        
        $scriptBlock = [scriptblock]::Create($content)
        $data = & $scriptBlock
        
        if ($data -isnot [hashtable]) {
            throw "Configuration must be a hashtable"
        }
        
        return $data
    }
    catch {
        throw "Failed to parse configuration: $_"
    }
}

function Export-PowerShellData1 {
    param (
        [Parameter(Mandatory)][hashtable]$Data,
        [Parameter(Mandatory)][string]$Path
    )
    
    try {
        $psd1Content = "@{`n"
        foreach ($key in $Data.Keys | Sort-Object) {
            $value = $Data[$key]
            if ($value -is [array]) {
                $psd1Content += "    '$key' = @("
                $processList = $value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | 
                                       ForEach-Object { "'$($_ -replace "'", "''")'" }
                $psd1Content += $processList -join ", "
                $psd1Content += ")`n"
            }
        }
        $psd1Content += "}"
        
        # Use UTF8 encoding without BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($Path, $psd1Content, $utf8NoBom)
    }
    catch {
        throw "Failed to export configuration: $_"
    }
}