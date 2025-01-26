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
        WindowWidth = 400
        WindowHeight = 450
        MinWidth = 400
        MinHeight = 450
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
            $this.Window.Dispatcher.Invoke([Action]{ $this.RefreshProcesses() })
        })
        $this.Timer.Start()
    }

    [void] LoadConfiguration() {
        try {
            $this.Config = Import-GameConfiguration
            # Ensure Categories exist even if the file is empty/corrupt
            if (-not $this.Config.Categories) { 
                $this.Config.Categories = @{ Custom = @{} } 
            }
            # Ensure "Custom" category exists
            if (-not $this.Config.Categories.ContainsKey("Custom")) {
                $this.Config.Categories["Custom"] = @{}
            }
            $this.Categories = $this.Config.Categories
            $this.RefreshProcesses()
            $this.StatusMessage = "Configuration loaded successfully"
        } catch {
            # Fallback to minimal valid config
            $this.Config = @{ Categories = @{ Custom = @{} } }
            $this.Categories = $this.Config.Categories
            $this.StatusMessage = "Loaded default configuration"
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
        foreach ($name in $this.Categories["Custom"].Keys | Sort-Object) {
            $count = Get-ProcessCount -ProcessNames $this.Categories["Custom"][$name]
            $this.ProcessItems.Add("$name ($count running)")
        }
    }

    [void] TerminateProcess($selected) {
        if ($selected -match '^(.+?)\s+\(\d+\s+running\)$') {  # More precise regex
            try {
                $name = $matches[1].Trim()
                $terminated = Stop-GameProcesses -ProcessNames $this.Categories["Custom"][$name]
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
        try {
            $this.SaveConfiguration()  # Save configuration before exiting
            if ($this.Timer) {
                $this.Timer.Stop()
                $this.Timer.Dispose()
            }
        } catch {
            $this.StatusMessage = "Error during shutdown: $_"
        }
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
        
        $this.AddHandler([System.Windows.Input.Keyboard]::PreviewKeyDownEvent,
            [System.Windows.Input.KeyEventHandler]{
                param($sender, $e)
                if ($e.Key -eq 'Escape') { $this.Close() }
            })
    }

    [void] InitializeComponent() {
        Add-Type -AssemblyName PresentationFramework
        
        $xamlPath = Join-Path $PSScriptRoot "interface.xaml"
        if (-not (Test-Path $xamlPath)) {
            throw "XAML file not found: $xamlPath"
        }
        
        $xamlContent = [System.IO.File]::ReadAllText($xamlPath)
        $reader = [System.Xml.XmlNodeReader]::new([xml]$xamlContent)
        
        try {
            $window = [System.Windows.Markup.XamlReader]::Load($reader)
            if (-not $window) {
                throw "Failed to load XAML window"
            }
            
            [System.Windows.NameScope]::SetNameScope($this, (New-Object System.Windows.NameScope))
            
            $this.Width = $window.Width
            $this.Height = $window.Height
            $this.Title = $window.Title
            $this.SizeToContent = $window.SizeToContent
            $this.Resources = $window.Resources
            
            $rootGrid = $window.Content
            $this.Content = $rootGrid
            
            function Find-NamedElement {
                param($parent, $name)
                if ($parent.Name -eq $name) { return $parent }
                foreach ($child in $parent.Children) {
                    if ($child.Name -eq $name) { return $child }
                    $result = Find-NamedElement $child $name
                    if ($result) { return $result }
                }
                return $null
            }
            
            $processList = Find-NamedElement $rootGrid 'ProcessList'
            if ($processList) {
                $this.RegisterName('ProcessList', $processList)
            }
            
            # Only register buttons that exist in the XAML
            foreach ($name in @('AddProcess', 'DeleteProcess', 'RescanProcesses', 'TerminateProcess')) {
                $button = Find-NamedElement $rootGrid $name
                if ($button) {
                    $this.RegisterName($name, $button)
                }
            }
        } catch {
            throw "Failed to load XAML: $_"
        }
    }

    [void] ApplyConfiguration() {
        try {
            $this.Width = $this.Monitor.Settings.WindowWidth
            $this.Height = $this.Monitor.Settings.WindowHeight
            $this.MinWidth = $this.Monitor.Settings.MinWidth
            $this.MinHeight = $this.Monitor.Settings.MinHeight
            $this.Title = $this.Monitor.Settings.WindowTitle

            $this.Background = New-Object SolidColorBrush($this.Monitor.Theme.Background)

            $buttonConfigs = @{
                "AddProcess" = $this.Monitor.Theme.PrimaryButton
                "DeleteProcess" = $this.Monitor.Theme.DangerButton
                "RescanProcesses" = $this.Monitor.Theme.PrimaryButton
                "TerminateProcess" = $this.Monitor.Theme.DangerButton
            }

            foreach ($btnName in $buttonConfigs.Keys) {
                $button = $this.FindName($btnName)
                if ($button -is [Button]) {
                    $button.Background = New-Object SolidColorBrush($buttonConfigs[$btnName])
                    $button.Foreground = New-Object SolidColorBrush([Colors]::White)
                }
            }
        } catch {
            Write-Warning "Failed to apply theme: $_"
            throw
        }
    }

    [void] ConfigureEvents() {
        $addProcessButton = $this.FindName("AddProcess")
        $deleteProcessButton = $this.FindName("DeleteProcess")
        $rescanProcessesButton = $this.FindName("RescanProcesses")
        $terminateProcessButton = $this.FindName("TerminateProcess")

        if ($addProcessButton) {
            $mainWindow = $this
            $addProcessButton.Add_Click({ 
                try {
                    $dialog = [AddProcessDialog]::new($mainWindow.Monitor)
                    $dialog.Owner = $mainWindow
                    $result = $dialog.ShowDialog()
                    if (-not $result) {
                        $mainWindow.Monitor.StatusMessage = "Process addition cancelled"
                    }
                } catch {
                    $mainWindow.Monitor.StatusMessage = "Error adding process: $_"
                }
            })
        }
        if ($deleteProcessButton) {
            $deleteProcessButton.Add_Click({ 
                try {
                    $this.DeleteSelectedProcess() 
                } catch {
                    $this.Monitor.StatusMessage = "Error deleting process: $_"
                }
            })
        }
        if ($rescanProcessesButton) {
            $rescanProcessesButton.Add_Click({ 
                try {
                    $this.Monitor.RefreshProcesses()
                    $this.Monitor.StatusMessage = "Process list refreshed"
                } catch {
                    $this.Monitor.StatusMessage = "Error refreshing processes: $_"
                }
            })
        }
        if ($terminateProcessButton) {
            $terminateProcessButton.Add_Click({ 
                try {
                    $this.TerminateSelectedProcess()
                } catch {
                    $this.Monitor.StatusMessage = "Error terminating process: $_"
                }
            })
        }
        
        # Handle window closing (X button)
        $this.Add_Closing({ 
            param($sender, $e)
            if (-not $this.IsClosing) {
                $e.Cancel = $true
                $this.HandleClosing()
            }
        })
    }

    [void] DeleteSelectedProcess() {
        $selected = $this.FindName("ProcessList").SelectedItem
        if ($selected -match '^(.+?) \(\d+') {
            try {
                $name = $matches[1]
                $this.Monitor.Categories["Custom"].Remove($name)
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
            $this.Monitor.Dispose()  # Saves configuration and cleans up
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
    hidden [TextBox]$Process1Box
    hidden [TextBox]$Process2Box  
    hidden [TextBox]$Process3Box

    AddProcessDialog([ProcessMonitor]$monitor) {
        $this.Monitor = $monitor
        $this.Title = "Add New Process"
        $this.Width = 400
        $this.Height = 500
        $this.WindowStartupLocation = "CenterOwner"
        $this.ResizeMode = "NoResize"

        $this.Background = New-Object SolidColorBrush([Colors]::White)

        $grid = New-Object Grid
        $grid.Margin = 15

        0..8 | ForEach-Object {
            $grid.RowDefinitions.Add((New-Object RowDefinition))
        }
        $grid.RowDefinitions[8].Height = "*"

        # Labels with consistent black text
        $labels = @(
            @{ Content = "Display Name:"; Row = 0 },
            @{ Content = "Process Name 1:"; Row = 2 },
            @{ Content = "Process Name 2 (Optional):"; Row = 4 },
            @{ Content = "Process Name 3 (Optional):"; Row = 6 }
        )

        foreach ($labelInfo in $labels) {
            $label = New-Object Label
            $label.Content = $labelInfo.Content
            $label.Margin = "0,5"
            $label.Foreground = New-Object SolidColorBrush([Colors]::Black)
            [Grid]::SetRow($label, $labelInfo.Row)
            $grid.Children.Add($label)
        }

        # TextBoxes with consistent styling
        $this.NameBox = New-Object TextBox
        $this.Process1Box = New-Object TextBox
        $this.Process2Box = New-Object TextBox
        $this.Process3Box = New-Object TextBox

        $textBoxes = @(
            @{ Box = $this.NameBox; Row = 1 },
            @{ Box = $this.Process1Box; Row = 3 },
            @{ Box = $this.Process2Box; Row = 5 },
            @{ Box = $this.Process3Box; Row = 7 }
        )

        foreach ($boxInfo in $textBoxes) {
            $boxInfo.Box.Margin = "0,5"
            $boxInfo.Box.Background = New-Object SolidColorBrush([Colors]::White)
            $boxInfo.Box.Foreground = New-Object SolidColorBrush([Colors]::Black)
            $boxInfo.Box.BorderBrush = New-Object SolidColorBrush([Colors]::Gray)
            [Grid]::SetRow($boxInfo.Box, $boxInfo.Row)
            $grid.Children.Add($boxInfo.Box)
        }

        # Button panel with improved contrast
        $buttonPanel = New-Object StackPanel
        $buttonPanel.Orientation = "Horizontal"
        $buttonPanel.HorizontalAlignment = "Right"
        $buttonPanel.Margin = "0,15,0,0"
        [Grid]::SetRow($buttonPanel, 8)

        $okButton = New-Object Button
        $okButton.Content = "OK"
        $okButton.Width = 75
        $okButton.Height = 25
        $okButton.Margin = "0,0,10,0"
        $okButton.Background = New-Object SolidColorBrush([Colors]::DodgerBlue)
        $okButton.Foreground = New-Object SolidColorBrush([Colors]::White)
        $okButton.Add_Click({ $this.AddProcess() })

        $cancelButton = New-Object Button
        $cancelButton.Content = "Cancel"
        $cancelButton.Width = 75
        $cancelButton.Height = 25
        $cancelButton.Background = New-Object SolidColorBrush([Colors]::LightGray)
        $cancelButton.Foreground = New-Object SolidColorBrush([Colors]::Black)
        $cancelButton.Add_Click({ $this.DialogResult = $false })

        $buttonPanel.Children.Add($okButton)
        $buttonPanel.Children.Add($cancelButton)
        $grid.Children.Add($buttonPanel)

        $this.Content = $grid
        
        $this.AddHandler([System.Windows.Input.Keyboard]::PreviewKeyDownEvent, 
            [System.Windows.Input.KeyEventHandler]{
                param($sender, $e)
                if ($e.Key -eq 'Enter') { $this.AddProcess() }
                elseif ($e.Key -eq 'Escape') { $this.DialogResult = $false }
            })
    }

    [void] AddProcess() {
        if ($this.NameBox.Text -and ($this.Process1Box.Text -or $this.Process2Box.Text -or $this.Process3Box.Text)) {            
            $name = $this.NameBox.Text.Trim()
            # Check for duplicate
            if ($this.Monitor.Categories["Custom"].ContainsKey($name)) {
                $this.Monitor.StatusMessage = "Process group '$name' already exists"
                return
            }
            # Add processes
            $processes = @(
                $this.Process1Box.Text.Trim(),
                $this.Process2Box.Text.Trim(),
                $this.Process3Box.Text.Trim()
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            
            $this.Monitor.Categories["Custom"][$name] = $processes
            $this.Monitor.RefreshProcesses()
            $this.Monitor.SaveConfiguration()
            $this.Monitor.StatusMessage = "Process group added successfully"
            $this.DialogResult = $true
            $this.Close()
        } else {
            $this.Monitor.StatusMessage = "Please enter a name and at least one process"
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