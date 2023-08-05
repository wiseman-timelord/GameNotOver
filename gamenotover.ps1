$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrative privileges. Please run as an administrator."
    Exit
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
        "ChatGPT" {
            Stop-Process -Name "ChatGPT" -Force -ErrorAction SilentlyContinue
            Write-Host "`nSuccessfully terminated processes for ChatGPT`nPress any key to continue..."
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "PaintShop Pro" {
            Stop-Process -Name "Paint Shop Pro 9" -Force -ErrorAction SilentlyContinue
            Stop-Process -Name "Paint Shop Pro 8" -Force -ErrorAction SilentlyContinue
            Stop-Process -Name "Corel PaintShop Pro" -Force -ErrorAction SilentlyContinue
            Write-Host "`nSuccessfully terminated processes for Paint Shop Pro`nPress any key to continue..."
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "Kenshi" {
            Stop-Process -Name "kenshi_x64" -Force -ErrorAction SilentlyContinue
            Write-Host "`nSuccessfully terminated processes for Kenshi`nPress any key to continue..."
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "Mount & Blade 2: BannerLord" {
            Stop-Process -Name "Bannerlord" -Force -ErrorAction SilentlyContinue
            Stop-Process -Name "Bannerlord.Native" -Force -ErrorAction SilentlyContinue
            Write-Host "`nSuccessfully terminated processes for Mount & Blade 2: BannerLord`nPress any key to continue..."
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "Exit Menu" { Write-Host "`nExiting GameNotOver..."; Exit }
    }
}
