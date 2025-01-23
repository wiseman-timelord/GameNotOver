# Check for Administrative Privileges
$ErrorActionPreference = 'Stop'

function Test-AdminPrivileges {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-AvaloniaUI {
    try {
        $requiredFiles = @(
            "Avalonia.Base.dll",
            "Avalonia.Controls.dll",
            "Avalonia.Desktop.dll",
            "Avalonia.Markup.dll",
            "Avalonia.Markup.Xaml.dll",
            "Avalonia.Styling.dll",
            "Avalonia.Themes.Simple.dll"
        )
        
        $missingFiles = $requiredFiles | Where-Object { -not (Test-Path ".\data\AvaloniaUI\$_") }
        if ($missingFiles.Count -gt 0) {
            Write-Host "Missing files: $($missingFiles -join ', ')"
        }
        return $missingFiles.Count -eq 0
    } catch {
        return $false
    }
}

function Initialize-Directories {
    param (
        [string[]]$Directories
    )
    
    foreach ($dir in $Directories) {
        if (-not (Test-Path $dir)) {
            Write-Host "Creating directory: $dir"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        } else {
            Write-Host "Directory already exists: $dir"
        }
    }
}

function Install-AvaloniaUI {
    try {
        $avaloniaVersion = "11.0.5"
        $avaloniaPackages = @(
            "Avalonia.Desktop",
            "Avalonia",
            "Avalonia.Skia",
            "Avalonia.Themes.Simple"
        )
        
        # Create temp directory if it doesn't exist
        Initialize-Directories -Directories @(".\temp", ".\data", ".\data\AvaloniaUI")
        
        foreach ($package in $avaloniaPackages) {
            $packageUrl = "https://www.nuget.org/api/v2/package/$package/$avaloniaVersion"
            $packagePath = ".\temp\$package.nupkg"
            
            # Download package
            Write-Host "Downloading $package package..."
            Invoke-WebRequest -Uri $packageUrl -OutFile $packagePath -ErrorAction Stop
            
            # Rename .nupkg to .zip
            Write-Host "Renaming $package.nupkg to .zip..."
            Rename-Item -Path $packagePath -NewName "$package.zip" -Force
            
            # Extract package
            Write-Host "Extracting $package package..."
            Expand-Archive -Path ".\temp\$package.zip" -DestinationPath ".\temp\$package" -Force
            
            # Copy DLLs from net6.0 directory
            $sourceDir = ".\temp\$package\lib\net6.0"
            if (-not (Test-Path $sourceDir)) {
                Write-Host "Warning: No net6.0 directory found in $package"
                continue
            }
            
            $dllFiles = Get-ChildItem -Path $sourceDir -Filter *.dll
            if ($dllFiles.Count -eq 0) {
                Write-Host "Warning: No DLLs found in $sourceDir"
                continue
            }
            
            foreach ($file in $dllFiles) {
                $destinationPath = Join-Path -Path ".\data\AvaloniaUI" -ChildPath $file.Name
                Write-Host "Copying $($file.Name) from $sourceDir"
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            }
        }
        
        # Verify installation
        if (-not (Test-AvaloniaUI)) {
            throw "Missing required files after installation"
        }
        
        Write-Host "Avalonia UI installed successfully!" -ForegroundColor Green
    } catch {
        throw "Failed to install Avalonia UI: $_"
    }
}

# Main installation script
try {
    if (-not (Test-AdminPrivileges)) {
        throw "This script requires administrative privileges. Please run as administrator."
    }

    Write-Host "Installing Requirements..."
    
    # Check and install Avalonia UI if needed
    if (-not (Test-AvaloniaUI)) {
        Install-AvaloniaUI
    }

    # Create interface.xml if it doesn't exist
    $interfaceXmlPath = ".\scripts\interface.xml"
    if (-not (Test-Path $interfaceXmlPath)) {
        Write-Host "Creating interface.xml..."
        Copy-Item ".\interface.xml" -Destination $interfaceXmlPath -Force
    }

    # Clean up temp directory
    if (Test-Path ".\temp") {
        Write-Host "Cleaning up temporary files..."
        Remove-Item -Path ".\temp" -Recurse -Force
    }

    Write-Host "Installation completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}

# Pause at the end to allow the user to see the output
Write-Host "Press any key to continue . . ."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")