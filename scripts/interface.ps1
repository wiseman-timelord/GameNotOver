# Script: ".\scripts\interface.ps1"
using namespace System.Windows
using namespace System.Windows.Controls
using namespace System.Windows.Media
using namespace System.Windows.Input
using namespace System.Collections.ObjectModel

Add-Type -AssemblyName PresentationFramework
. $PSScriptRoot\utility.ps1

class ProcessMonitor {
    [hashtable]$Categories
    [ObservableCollection[string]]$ProcessItems
    [string]$StatusMessage
    [hashtable]$Config
    hidden [System.Timers.Timer]$Timer
    hidden [Window]$Window

    # Hardcoded Settings and Theme
    hidden [hashtable]$Settings = @{
        RefreshInterval = 5000
        WindowTitle = "Game Not Over!"
        WindowWidth = 800
        WindowHeight = 600
        MinWidth = 400
        MinHeight = 300
        ProcessNameWatermark = "Enter process display name..."
        ProcessIdWatermark = "Enter process ID(s) separated by commas..."
        CategorySelectorWatermark = "Select category..."
    }

    hidden [hashtable]$Theme = @{
        Background = [Colors]::WhiteSmoke
        HeaderBorder = [Colors]::LightGray
        ListBorder = [Colors]::Gray
        DangerButton = [Colors]::Red
        WarningButton = [Colors]::Orange
        PrimaryButton = [Colors]::DodgerBlue
        TextColor = [Colors]::Black
        StatusTextColor = [Colors]::DarkGray
    }

    ProcessMonitor([Window]$window) {
        $this.Window = $window
        $this.ProcessItems = New-Object ObservableCollection[string]
        $this.LoadConfiguration()
        $this.InitializeTimer()
    }

    [void] InitializeTimer() {
        $this.Timer = New-Object System.Timers.Timer
        $this.Timer.Interval = $this.Settings.RefreshInterval
        $this.Timer.AutoReset = $true
        $this.Timer.Enabled = $true
        $this.Timer.Add_Elapsed({
            $this.Window.Dispatcher.Invoke({ $this.RefreshProcesses() })
        })
        $this.Timer.Start()
    }

    [void] LoadConfiguration() {
        try {
            $this.Config = Import-GameConfiguration
            $this.Categories = $this.Config.Categories
            $this.RefreshProcesses()
            $this.StatusMessage = "Configuration loaded successfully"
        } catch {
            $this.StatusMessage = "Error loading configuration: $_"
            throw
        }
    }

    [void] SaveConfiguration() {
        try {
            $this.Config.Categories = $this.Categories
            Save-GameConfiguration -Config $this.Config
            $this.StatusMessage = "Configuration saved successfully"
        } catch {
            $this.StatusMessage = "Error saving configuration: $_"
            throw
        }
    }

    [void] RefreshProcesses() {
        $this.ProcessItems.Clear()
        foreach ($cat in $this.Categories.Keys | Sort-Object) {
            foreach ($name in $this.Categories[$cat].Keys | Sort-Object) {
                $count = Get-ProcessCount -ProcessNames $this.Categories[$cat][$name]
                $this.ProcessItems.Add("$cat - $name ($count running)")
            }
        }
    }

    [void] TerminateProcess($selected) {
        if ($selected -match '^(.+?) - (.+?) \(\d+') {
            try {
                $cat, $name = $matches[1,2]
                $terminated = Stop-GameProcesses -ProcessNames $this.Categories[$cat][$name]
                $this.RefreshProcesses()
                $this.StatusMessage = if ($terminated) { "Process(es) terminated" } else { "No running processes found" }
            } catch {
                $this.StatusMessage = "Error terminating process: $_"
            }
        } else {
            $this.StatusMessage = "No process selected"
        }
    }

    [void] Dispose() {
        if ($this.Timer) {
            $this.Timer.Stop()
            $this.Timer.Dispose()
        }
        $this.SaveConfiguration()
    }
}

class MainWindow : Window {
    hidden [ProcessMonitor]$Monitor
    hidden [bool]$IsClosing = $false

    MainWindow() {
        $this.InitializeComponent()
        $this.Monitor = [ProcessMonitor]::new($this)
        $this.DataContext = $this.Monitor
        $this.ApplyConfiguration()
        $this.ConfigureEvents()
    }

    [void] InitializeComponent() {
        $xamlPath = Join-Path $PSScriptRoot "interface.xaml"
        if (-not (Test-Path $xamlPath)) {
            throw "XAML file not found: $xamlPath"
        }

        $xamlContent = [System.IO.File]::ReadAllText($xamlPath)
        $reader = [System.Xml.XmlNodeReader]::new([xml]$xamlContent)

        $window = [System.Windows.Markup.XamlReader]::Load($reader)
        if (-not $window) {
            throw "Failed to load XAML"
        }

        $this.Width = $window.Width
        $this.Height = $window.Height
        $this.Title = $window.Title
        $this.Content = $window.Content
        $this.Resources = $window.Resources
        $this.SizeToContent = $window.SizeToContent

        # Apply theme colors directly to UI elements
        $this.ApplyTheme()
    }

    [void] ApplyConfiguration() {
        try {
            $settings = $this.Monitor.Settings
            $theme = $this.Monitor.Theme

            $this.Width = $settings.WindowWidth
            $this.Height = $settings.WindowHeight
            $this.MinWidth = $settings.MinWidth
            $this.MinHeight = $settings.MinHeight
            $this.Title = $settings.WindowTitle

            # Apply theme colors
            $this.Background = New-Object SolidColorBrush($theme.Background)

            # Button configuration with fallbacks
            $buttonConfigs = @{
                "AddProcess" = @{ Color = $theme.PrimaryButton; Fallback = [Colors]::DodgerBlue }
                "DeleteProcess" = @{ Color = $theme.DangerButton; Fallback = [Colors]::Red }
                "RescanProcesses" = @{ Color = $theme.PrimaryButton; Fallback = [Colors]::DodgerBlue }
                "TerminateProcess" = @{ Color = $theme.DangerButton; Fallback = [Colors]::Red }
                "SaveConfig" = @{ Color = $theme.PrimaryButton; Fallback = [Colors]::DodgerBlue }
                "ExitApp" = @{ Color = $theme.WarningButton; Fallback = [Colors]::Orange }
            }

            foreach ($btnName in $buttonConfigs.Keys) {
                $button = $this.FindName($btnName)
                if ($button -is [Button]) {
                    $btnColor = $buttonConfigs[$btnName].Fallback
                    try {
                        $btnColor = $buttonConfigs[$btnName].Color
                    } catch {}
                    $button.Background = New-Object SolidColorBrush($btnColor)
                    $button.Foreground = New-Object SolidColorBrush([Colors]::White)
                }
            }
        }
        catch {
            Write-Warning "Failed to apply theme: $_"
            throw
        }
    }

    [void] ApplyTheme() {
        $theme = $this.Monitor.Theme

        # Apply theme colors directly to UI elements
        $titleText = $this.Content.FindName("TitleText")
        if ($titleText -is [TextBlock]) {
            $titleText.Foreground = New-Object SolidColorBrush($theme.TextColor)
        }

        $statusText = $this.Content.FindName("StatusText")
        if ($statusText -is [TextBlock]) {
            $statusText.Foreground = New-Object SolidColorBrush($theme.StatusTextColor)
        }

        $processList = $this.Content.FindName("ProcessList")
        if ($processList -is [ListBox]) {
            $processList.BorderBrush = New-Object SolidColorBrush($theme.ListBorder)
        }
    }

    [void] ConfigureEvents() {
        $this.FindName("AddProcess").Add_Click({ $this.ShowAddProcessDialog() })
        $this.FindName("DeleteProcess").Add_Click({ $this.DeleteSelectedProcess() })
        $this.FindName("RescanProcesses").Add_Click({ $this.Monitor.RefreshProcesses() })
        $this.FindName("TerminateProcess").Add_Click({ $this.TerminateSelectedProcess() })
        $this.FindName("SaveConfig").Add_Click({ $this.Monitor.SaveConfiguration() })
        $this.FindName("ExitApp").Add_Click({ $this.Close() })

        $this.Closing += {
            param($s, $e)
            if (-not $this.IsClosing) {
                $e.Cancel = $true
                $this.HandleClosing()
            }
        }
    }

    [void] ShowAddProcessDialog() {
        $dialog = [AddProcessDialog]::new($this.Monitor, $this.Monitor.Theme)
        $dialog.Owner = $this
        $dialog.ShowDialog()
    }

    [void] DeleteSelectedProcess() {
        $selected = $this.FindName("ProcessList").SelectedItem
        if ($selected -match '^(.+?) - (.+?) \(\d+') {
            try {
                $cat, $name = $matches[1,2]
                $this.Monitor.Categories[$cat].Remove($name)
                $this.Monitor.RefreshProcesses()
                $this.Monitor.SaveConfiguration()
                $this.Monitor.StatusMessage = "Process '$name' removed successfully"
            } catch {
                $this.Monitor.StatusMessage = "Error removing process: $_"
            }
        } else {
            $this.Monitor.StatusMessage = "No process selected"
        }
    }

    [void] TerminateSelectedProcess() {
        $selected = $this.FindName("ProcessList").SelectedItem
        if ($selected) {
            $this.Monitor.TerminateProcess($selected)
        } else {
            $this.Monitor.StatusMessage = "No process selected"
        }
    }

    [void] HandleClosing() {
        try {
            $this.Monitor.Dispose()
            $this.IsClosing = $true
            $this.Close()
        } catch {
            $this.Monitor.StatusMessage = "Error during shutdown: $_"
        }
    }
}

class AddProcessDialog : Window {
    hidden [ProcessMonitor]$Monitor
    hidden [TextBox]$NameBox
    hidden [TextBox]$IdBox

    AddProcessDialog([ProcessMonitor]$monitor, [hashtable]$theme) {
        $this.Monitor = $monitor
        $this.Title = "Add New Process"
        $this.Width = 400
        $this.Height = 250
        $this.WindowStartupLocation = "CenterOwner"
        $this.ResizeMode = "NoResize"

        # Color handling with fallbacks
        $colors = @{
            Background = $theme.Background
            Text = $theme.TextColor
            Primary = $theme.PrimaryButton
            Warning = $theme.WarningButton
        }

        $brushes = @{}
        foreach ($key in $colors.Keys) {
            $brushes[$key] = New-Object SolidColorBrush($colors[$key])
        }

        $this.Background = $brushes.Background

        $grid = New-Object Grid
        $grid.Margin = 15

        0..4 | ForEach-Object {
            $grid.RowDefinitions.Add((New-Object RowDefinition))
        }
        $grid.RowDefinitions[4].Height = "*"

        $nameLabel = New-Object Label
        $nameLabel.Content = "Process Name:"
        $nameLabel.Margin = "0,5"
        $nameLabel.Foreground = $brushes.Text
        [Grid]::SetRow($nameLabel, 0)
        $grid.Children.Add($nameLabel)

        $this.NameBox = New-Object TextBox
        $this.NameBox.Margin = "0,5"
        [Grid]::SetRow($this.NameBox, 1)
        $grid.Children.Add($this.NameBox)

        $idLabel = New-Object Label
        $idLabel.Content = "Process ID(s) (comma-separated):"
        $idLabel.Margin = "0,5"
        $idLabel.Foreground = $brushes.Text
        [Grid]::SetRow($idLabel, 2)
        $grid.Children.Add($idLabel)

        $this.IdBox = New-Object TextBox
        $this.IdBox.Margin = "0,5"
        [Grid]::SetRow($this.IdBox, 3)
        $grid.Children.Add($this.IdBox)

        $buttonPanel = New-Object StackPanel
        $buttonPanel.Orientation = "Horizontal"
        $buttonPanel.HorizontalAlignment = "Right"
        $buttonPanel.Margin = "0,15,0,0"
        [Grid]::SetRow($buttonPanel, 4)

        $okButton = New-Object Button
        $okButton.Content = "OK"
        $okButton.Width = 75
        $okButton.Height = 25
        $okButton.Margin = "0,0,10,0"
        $okButton.Background = $brushes.Primary
        $okButton.Foreground = New-Object SolidColorBrush([Colors]::White)
        $okButton.Add_Click({ $this.AddProcess() })

        $cancelButton = New-Object Button
        $cancelButton.Content = "Cancel"
        $cancelButton.Width = 75
        $cancelButton.Height = 25
        $cancelButton.Background = $brushes.Warning
        $cancelButton.Foreground = New-Object SolidColorBrush([Colors]::White)
        $cancelButton.Add_Click({ $this.DialogResult = $false })

        $buttonPanel.Children.Add($okButton)
        $buttonPanel.Children.Add($cancelButton)
        $grid.Children.Add($buttonPanel)

        $this.Content = $grid
        $this.KeyDown += {
            param($sender, $e)
            if ($e.Key -eq 'Enter') { $this.AddProcess() }
            elseif ($e.Key -eq 'Escape') { $this.DialogResult = $false }
        }
    }

    [void] AddProcess() {
        if ($this.NameBox.Text -and $this.IdBox.Text) {
            if (-not $this.Monitor.Categories.ContainsKey("Custom")) {
                $this.Monitor.Categories["Custom"] = @{}
            }
            $this.Monitor.Categories["Custom"][$this.NameBox.Text] = $this.IdBox.Text.Split(',').Trim()
            $this.Monitor.RefreshProcesses()
            $this.Monitor.SaveConfiguration()
            $this.Monitor.StatusMessage = "Process added successfully"
            $this.DialogResult = $true
        }
    }
}

try {
    $window = [MainWindow]::new()
    $window.ShowDialog()
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Debug ($_ | Format-List -Force | Out-String)
    exit 1
}