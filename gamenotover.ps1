$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrative privileges. Please run as an administrator."
    Exit
}

Function TerminateSelectedProcesses {
    Param(
        [String[]]$ProcessNames
    )

    ForEach ($ProcessName in $ProcessNames) {
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
    }

    Write-Host "`nSuccessfully terminated, press any key..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

Function Create-Menu {
    Param(
        [String]$MenuTitle,
        [array]$MenuOptions
    )

    $selectedIndex = 0

    While ($true) {
        Clear-Host
        Write-Host "" # Blank line
		Write-Host $MenuTitle
        Write-Host "Please select which programs to terminate.."
        Write-Host "" # Blank line

        For ($i = 0; $i -lt $MenuOptions.Length; $i++) {
            $option = $MenuOptions[$i]
            $line = $option.Text
            $isSelectable = $option.Selectable

            If ($line -eq "") { Write-Host ""; continue }
            If ($line -match "^(A.I.|Media|Games|System):") {
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

$MenuTitle = "                GameNotOver!"
$MenuOptions = @(
    @{ Text = "A.I.:"; Selectable = $false },
    @{ Text = "ChatGPT"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "Media:"; Selectable = $false },
    @{ Text = "PaintShop Pro"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "Games:"; Selectable = $false },
    @{ Text = "Kenshi"; Selectable = $true },
    @{ Text = "Mount & Blade 2: BannerLord"; Selectable = $true },
    @{ Text = ""; Selectable = $false },
    @{ Text = "System:"; Selectable = $false },
    @{ Text = "Exit Menu"; Selectable = $true }
)
$Selection = $null

While ($Selection -ne "Exit Menu") {
    $Selection = Create-Menu -MenuTitle $MenuTitle -MenuOptions $MenuOptions

    Switch($Selection) {
        "ChatGPT" { TerminateSelectedProcesses -ProcessNames @("ChatGPT") }
        "PaintShop Pro" { TerminateSelectedProcesses -ProcessNames @("Paint Shop Pro 9", "Paint Shop Pro 8", "Corel PaintShop Pro") }
        "Kenshi" { TerminateSelectedProcesses -ProcessNames @("kenshi_x64") }
        "Mount & Blade 2: BannerLord" { TerminateSelectedProcesses -ProcessNames @("Bannerlord", "Bannerlord.Native") }
        "Exit Menu" { Write-Host "`nExiting GameNotOver..."; Exit }
    }
}
