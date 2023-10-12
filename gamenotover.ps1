# Check for Administrative Privileges
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrative privileges. Please run as an administrator."
    return
}

# Function to Resize Window and Set Title
function Set-WindowTitleAndSize {
    param (
        [string]$title = "Default Window Title",
        [int]$width = 37,
        [int]$height = 21,
        [int]$bufferWidth = 37,
        [int]$bufferHeight = 63
    )

    $host.UI.RawUI.WindowTitle = $title
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($width, $height)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($bufferWidth, $bufferHeight)
}
Set-WindowTitleAndSize -title "GameNotOver!"

# Function to Terminate Selected Processes
Function TerminateSelectedProcesses {
    Param(
        [String[]]$ProcessNames
    )

    ForEach ($ProcessName in $ProcessNames) {
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
    }

    Write-Host "`nSuccessfully terminated, press any key... "
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

# Function to Create and Display Menu
Function Create-Menu {
    Param(
        [String]$MenuTitle,
        [array]$MenuOptions
    )

    $selectedIndex = 0

    While ($true) {
        Clear-Host

        # Insert a blank line
        Write-Host ""

        # Center-align the Menu Title
        $padding = [math]::Floor(($host.UI.RawUI.WindowSize.Width - $MenuTitle.Length) / 2)
        $centerAlignedText = (" " * $padding) + $MenuTitle
        Write-Host $centerAlignedText

        Write-Host "" # Blank line
        Write-Host " Select programs to terminate.."
        Write-Host "" # Blank line

        For ($i = 0; $i -lt $MenuOptions.Length; $i++) {
            $option = $MenuOptions[$i]
            $line = $option.Text
            $isSelectable = $option.Selectable

            If ($line -eq "") { Write-Host ""; continue }
            If ($line -match "^(A.I.|Media|Games|Options):") {
                Write-Host ("  " + $line.Substring(0, $line.Length - 1))
                continue
            }

            $prefix = "      "
            $color = 'White'
            If ($isSelectable -and ($i -eq $selectedIndex)) {
                $prefix = "    > "
                $color = 'Green'
            }

            Write-Host "$prefix$line" -ForegroundColor $color
        }

        $keyInfo = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Switch ($keyInfo.VirtualKeyCode) {
            38 { While ($selectedIndex -gt 0 -and !$MenuOptions[--$selectedIndex].Selectable) { } } # Up arrow
            40 { While ($selectedIndex -lt $MenuOptions.Length - 1 -and !$MenuOptions[++$selectedIndex].Selectable) { } } # Down arrow
            13 { If ($MenuOptions[$selectedIndex].Selectable) { Return $MenuOptions[$selectedIndex].Text } } # Enter key
        }
    }
}

# Menu Options and Main Loop
$MenuTitle = "GAME NOT OVER!"
$MenuOptions = @(
    @{ Text = "A.I.:-"; Selectable = $false },
    @{ Text = "ChatGPT (LenX)"; Selectable = $true },
    @{ Text = "Notepad (All)"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "Media:-"; Selectable = $false },
    @{ Text = "PaintShop Pro (Corel/Jasc)"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "Games:-"; Selectable = $false },
    @{ Text = "Fallout (3/NV/4)"; Selectable = $true },
    @{ Text = "Skyrim (Legacy/SE)"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "Options:-"; Selectable = $false },
    @{ Text = "Exit Menu"; Selectable = $true }
)
$Selection = $null
While ($Selection -ne "Exit Menu") {
    $Selection = Create-Menu -MenuTitle $MenuTitle -MenuOptions $MenuOptions

    Switch($Selection) {
        "ChatGPT (LenX)" { TerminateSelectedProcesses -ProcessNames @("ChatGPT") }
        "PaintShop Pro (Corel/Jasc)" { TerminateSelectedProcesses -ProcessNames @("Paint Shop Pro 9", "Paint Shop Pro 8", "Corel PaintShop Pro") }
        "Notepad (All)" { TerminateSelectedProcesses -ProcessNames @("NotePad") } 
		"Fallout (3/NV/4)" { TerminateSelectedProcesses -ProcessNames @("f4se_loader", "Fallout4", "Fallout4Launcher", "Fallout3", "FalloutNV" ) }
        "Skyrim (Legacy/SE)" { TerminateSelectedProcesses -ProcessNames @("Skyrim", "SkyrimSE") }
        "Exit Menu" { Exit }
    }
}
