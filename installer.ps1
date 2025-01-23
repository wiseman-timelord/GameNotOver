# Check for Administrative Privileges
$ErrorActionPreference = 'Stop'

function Test-AdminPrivileges {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DotNetSDK {
    try {
        $dotnetVersion = dotnet --version
        Write-Host "Found .NET SDK version: $dotnetVersion"
        return $true
    } catch {
        Write-Host "No .NET SDK found"
        return $false
    }
}

function Test-AvaloniaTemplates {
    try {
        $templates = dotnet new list | Select-String "avalonia"
        return $templates.Count -gt 0
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
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created directory: $dir"
        } else {
            Write-Host "Directory already exists: $dir"
        }
    }
}

function Install-DotNetSDK {
    try {
        Write-Host "Downloading .NET SDK..."
        $dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/85473c45-8d91-48cb-ab41-86ec7abc1000/83cd0c82f0cde9a566bae4245ea5a65b/dotnet-sdk-7.0.100-win-x64.exe"
        $installerPath = ".\temp\dotnet-sdk-installer.exe"
        
        # Create temp directory if it doesn't exist
        if (-not (Test-Path ".\temp")) {
            New-Item -ItemType Directory -Path ".\temp" -Force | Out-Null
        }
        
        # Download with progress bar
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($dotnetUrl, $installerPath)
        
        Write-Host "Installing .NET SDK..."
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
        
        Write-Host "Installing Avalonia templates..."
        $process = Start-Process -FilePath "dotnet" -ArgumentList "new --install Avalonia.Templates" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Template installation failed with exit code: $($process.ExitCode)"
        }
        
        # Verify templates installation
        if (-not (Test-AvaloniaTemplates)) {
            throw "Avalonia templates installation could not be verified"
        }
        
        Write-Host "Avalonia templates installed successfully"
    } catch {
        throw "Failed to install .NET SDK: $_"
    }
}

# Main installation script
try {
    if (-not (Test-AdminPrivileges)) {
        throw "This script requires administrative privileges. Please run as administrator."
    }

    Write-Host "Starting GameNotOver installation..."
    
    # Create directories
    $directories = @(
        ".\scripts",
        ".\data",
        ".\temp"
    )
    Initialize-Directories -Directories $directories

    # Create empty list.txt if it doesn't exist
    $listPath = ".\data\list.txt"
    if (-not (Test-Path $listPath)) {
        "" | Set-Content $listPath
        Write-Host "Created empty list.txt file"
    }

    # Check and install .NET SDK if needed
    if (-not (Test-DotNetSDK)) {
        Install-DotNetSDK
    }

    # Create interface.xml
    $interfaceXmlPath = ".\scripts\interface.xml"
    if (-not (Test-Path $interfaceXmlPath)) {
        Write-Host "Creating interface configuration..."
        Copy-Item ".\interface.xml" -Destination $interfaceXmlPath -Force
        Write-Host "Created interface XML at: $interfaceXmlPath"
    }

    # Clean up temp directory
    if (Test-Path ".\temp") {
        Remove-Item -Path ".\temp" -Recurse -Force
        Write-Host "Cleaned up temporary files"
    }

    Write-Host "Installation completed successfully!"
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}