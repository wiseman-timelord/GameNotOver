# Check for Administrative Privileges
$ErrorActionPreference = 'Stop'

function Test-AdminPrivileges {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DotNetInstallation {
    try {
        $dotnetVersion = (dotnet --list-sdks) -match "6.0|8.0"
        if (-not $dotnetVersion) {
            throw "Required .NET SDK (6.0 or 8.0) is not installed."
        }
        return $true
    } catch {
        return $false
    }
}

function Initialize-CleanInstall {
    param (
        [string[]]$Directories
    )
    foreach ($dir in $Directories) {
        if (Test-Path $dir) {
            Write-Host "Removing existing directory: $dir"
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
        }
    }
}

function Test-RequiredFiles {
    param (
        [string]$Directory,
        [string[]]$RequiredFiles
    )
    $missingFiles = $RequiredFiles | Where-Object { -not (Test-Path (Join-Path -Path $Directory -ChildPath $_)) }
    if ($missingFiles.Count -gt 0) {
        Write-Host "Missing files: $($missingFiles -join ', ')"
        return $false
    }
    return $true
}

function Initialize-Directories {
    param (
        [string[]]$Directories
    )
    foreach ($dir in $Directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

function Install-AvaloniaUI {
    try {
        $avaloniaVersion = "11.2.3"
        $avaloniaPackages = @(
            "Avalonia.Desktop",
            "Avalonia",
            "Avalonia.Skia",
            "Avalonia.Themes.Simple"
        )

        Initialize-Directories @(".\temp", ".\data", ".\data\AvaloniaUI")

        foreach ($package in $avaloniaPackages) {
            $packageUrl = "https://www.nuget.org/api/v2/package/$package/$avaloniaVersion"
            $packagePath = ".\temp\$package.nupkg"

            Write-Host "Downloading $package..."
            Invoke-WebRequest -Uri $packageUrl -OutFile $packagePath -ErrorAction Stop

            Write-Host "Extracting $package..."
            Rename-Item -Path $packagePath -NewName "$package.zip" -Force
            Expand-Archive -Path ".\temp\$package.zip" -DestinationPath ".\temp\$package" -Force

            $sourceDir = ".\temp\$package\lib"
            $destinationDir = ".\data\AvaloniaUI"

            $dllFiles = Get-ChildItem -Path $sourceDir -Recurse -Filter *.dll |
                Where-Object { $_.Directory.Name -match "net6.0|net8.0" }

            foreach ($file in $dllFiles) {
                $destinationPath = Join-Path -Path $destinationDir -ChildPath $file.Name
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            }
        }

        # Verify all required files
        $requiredFiles = @(
            "Avalonia.Base.dll",
            "Avalonia.Controls.dll",
            "Avalonia.Desktop.dll",
            "Avalonia.Markup.dll",
            "Avalonia.Markup.Xaml.dll",
            "Avalonia.Themes.Simple.dll"
        )
        if (-not (Test-RequiredFiles -Directory ".\data\AvaloniaUI" -RequiredFiles $requiredFiles)) {
            throw "Missing required files after installation"
        }
    } catch {
        throw "Failed to install Avalonia UI: $_"
    }
}

# Main installation script
try {
    if (-not (Test-AdminPrivileges)) {
        throw "This script requires administrative privileges."
    }

    if (-not (Test-DotNetInstallation)) {
        throw "Please install .NET 6.0 or .NET 8.0 SDK before proceeding."
    }

    # Force clean install
    Initialize-CleanInstall -Directories @(".\data", ".\temp")

    Write-Host "Installing Requirements..."

    Install-AvaloniaUI

    $interfaceXmlPath = ".\scripts\interface.xml"
    if (-not (Test-Path $interfaceXmlPath)) {
        Copy-Item ".\interface.xml" -Destination $interfaceXmlPath -Force
    }

    Write-Host "Installation completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Press any key to continue . . ."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")