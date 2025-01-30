# Script: ".\scripts\interface.ps1"
using namespace System.Windows
using namespace System.Windows.Controls
using namespace System.Windows.Media
using namespace System.Windows.Input
using namespace System.Collections.ObjectModel

Add-Type -AssemblyName PresentationFramework
. $PSScriptRoot\utility.ps1

# Define a ViewModelBase class to handle property change notifications
class ViewModelBase {
    # Define event for property change notifications
    hidden [System.ComponentModel.PropertyChangedEventHandler]$PropertyChanged

    # Method to raise property changed event
    [void] OnPropertyChanged([string]$propertyName) {
        if ($this.PropertyChanged) {
            $this.PropertyChanged.Invoke($this, (New-Object System.ComponentModel.PropertyChangedEventArgs($propertyName)))
        }
    }

    # Method to register property change handlers
    [void] RegisterPropertyChanged([System.ComponentModel.PropertyChangedEventHandler]$handler) {
        $this.PropertyChanged = [Delegate]::Combine($this.PropertyChanged, $handler)
    }
}

class ProcessMonitor : ViewModelBase {
    # Main properties
    [ObservableCollection[string]]$ProcessItems
    [hashtable]$Config
    hidden [Window]$Window

    # Status Message Property with Notification Support
    [string]$StatusMessage
    hidden [string]$_statusMessage

    [string] get_StatusMessage() { 
        return $this._statusMessage 
    }
    
    [void] set_StatusMessage([string]$value) {
        if ($this._statusMessage -ne $value) {
            $this._statusMessage = $value
            $this.OnPropertyChanged('StatusMessage')
        }
    }

    # Hardcoded Settings and Theme
    hidden [hashtable]$Settings = @{
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
        $this._statusMessage = ""  # Initialize the backing field
        $this.LoadConfiguration()
    }

	[void] LoadConfiguration() {
		try {
			Write-Debug "Loading configuration..."
			$this.Config = Import-GameConfiguration
			
			if (-not $this.Config) {
				Write-Debug "No configuration found, creating default"
				$this.Config = @{}
			}
			
			$this.set_StatusMessage("Configuration loaded successfully")
			$this.RefreshProcesses()
		} catch {
			Write-Debug ("Error loading configuration: {0}" -f $_)
			$this.Config = @{}
			$this.set_StatusMessage(("Error loading configuration: {0}" -f $_))
			$this.RefreshProcesses()
		}
	}

	[void] SaveConfiguration() {
		try {
			Write-Debug "Saving configuration..."
			Save-GameConfiguration -Config $this.Config
			$this.set_StatusMessage("Configuration saved successfully")
		} catch {
			Write-Debug ("Error saving configuration: {0}" -f $_)
			$this.set_StatusMessage(("Error saving configuration: {0}" -f $_))
			throw
		}
	}

	[void] RefreshProcesses() {
		Write-Debug "Refreshing processes..."
		$this.ProcessItems.Clear()
		$this.Window.Cursor = [System.Windows.Input.Cursors]::Wait
		
		try {
			if (-not $this.Config) {
				Write-Debug "No configuration found"
				return
			}
			
			Write-Debug ("Groups found: {0}" -f ($this.Config.Keys -join ', '))
			foreach ($name in $this.Config.Keys | Sort-Object) {
				Write-Debug ("Processing {0}..." -f $name)
				$count = Get-ProcessCount -ProcessNames $this.Config[$name]
				Write-Debug ("Found {0} processes for {1}" -f $count, $name)
				$this.ProcessItems.Add(("{0} ({1} running)" -f $name, $count))
			}
			$this.set_StatusMessage("Process list updated")
		}
		catch {
			Write-Debug ("Error refreshing processes: {0}" -f $_)
			$this.set_StatusMessage(("Error refreshing processes: {0}" -f $_))
		}
		finally {
			$this.Window.Cursor = [System.Windows.Input.Cursors]::Arrow
		}
	}

	[void] TerminateProcess($selected) {
		if ($selected -match '^(.+?)\s+\(\d+\s+running\)$') {
			$name = $matches[1].Trim()
			$this.Window.Cursor = [System.Windows.Input.Cursors]::Wait
			
			try {
				$processNames = $this.Config[$name]  # Changed from Categories["Custom"][$name]
				Write-Debug ("Terminating processes for {0}: {1}" -f $name, ($processNames -join ', '))
				$terminated = Stop-GameProcesses -ProcessNames $processNames
				$this.RefreshProcesses()
				if ($terminated) { 
					$this.set_StatusMessage(("Successfully terminated processes for '{0}'" -f $name))
				} else { 
					$this.set_StatusMessage(("No running processes found for '{0}'" -f $name))
				}
			} catch {
				Write-Debug ("Error terminating processes: {0}" -f $_)
				$this.set_StatusMessage(("Error terminating processes: {0}" -f $_))
			} finally {
				$this.Window.Cursor = [System.Windows.Input.Cursors]::Arrow
			}
		} else {
			$this.set_StatusMessage("No process selected")
		}
	}

    [void] Dispose() {
        try {
            Write-Debug "Disposing ProcessMonitor..."
            $this.SaveConfiguration()
        } catch {
            Write-Debug ("Error during disposal: {0}" -f $_)
            $this.set_StatusMessage(("Error during shutdown: {0}" -f $_))
        }
    }
}

class MainWindow : Window {
    hidden [ProcessMonitor]$Monitor
    hidden [bool]$IsClosing = $false

	MainWindow() {
		$this.InitializeComponent()
		
		Write-Debug "Initializing Monitor..."
		$this.Monitor = [ProcessMonitor]::new($this)
		if (-not $this.Monitor) {
			throw "Failed to initialize ProcessMonitor"
		}
		
		Write-Debug "Setting DataContext..."
		$this.DataContext = $this.Monitor
		
		Write-Debug "Applying configuration..."
		$this.ApplyConfiguration()
		
		Write-Debug "Configuring events..."
		$this.ConfigureEvents()
		
		Write-Debug "Initial process refresh..."
		$this.Monitor.RefreshProcesses()
		
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

		# Store reference to this for use in event handlers
		$mainWindow = $this

		if ($rescanProcessesButton) {
			$rescanProcessesButton.Add_Click({
				try {
					if ($mainWindow.Monitor) {
						$mainWindow.Monitor.RefreshProcesses()
					} else {
						Write-Warning "Monitor object not found"
						throw "Monitor initialization failed"
					}
				} catch {
					Write-Debug "Error in refresh: $_"
					if ($mainWindow.Monitor) {
						$mainWindow.Monitor.set_StatusMessage("Error refreshing processes: $($_.Exception.Message)")
					}
				}
			})
		}
        if ($deleteProcessButton) {
            $deleteProcessButton.Add_Click({ 
                try {
                    $this.DeleteSelectedProcess() 
                } catch {
                    $this.Monitor.set_StatusMessage(("Error deleting process: {0}" -f $_))
                }
            })
        }
		if ($rescanProcessesButton) {
			$rescanProcessesButton.Add_Click({ 
				try {
					if ($this.Monitor) {
						$this.Monitor.RefreshProcesses()
					} else {
						Write-Warning "Monitor not initialized"
					}
				} catch {
					Write-Debug "Error in refresh: $_"
					if ($this.Monitor) {
						$this.Monitor.set_StatusMessage("Error refreshing processes: $($_.Exception.Message)")
					}
				}
			})
		}
        if ($terminateProcessButton) {
            $terminateProcessButton.Add_Click({ 
                try {
                    $this.TerminateSelectedProcess()
                } catch {
                    $this.Monitor.set_StatusMessage(("Error terminating process: {0}" -f $_))
                }
            })
        }
        
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
				$this.Monitor.Config.Remove($name)
				$this.Monitor.RefreshProcesses()
				$this.Monitor.SaveConfiguration()
				$this.Monitor.set_StatusMessage(("Process '{0}' removed successfully" -f $name))
			} catch {
				$this.Monitor.set_StatusMessage(("Error removing process: {0}" -f $_))
			}
		} else {
			$this.Monitor.set_StatusMessage("No process selected")
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
            $this.Monitor.set_StatusMessage(("Error during shutdown: {0}" -f $_))
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
        $this.InitializeComponent()
    }

    [void] InitializeComponent() {
        $this.Title = "Add New Process"
        $this.Width = 400
        $this.Height = 500
        $this.WindowStartupLocation = "CenterOwner"
        $this.ResizeMode = "NoResize"
        $this.Background = New-Object SolidColorBrush([Colors]::White)

        $grid = New-Object Grid
        $grid.Margin = 15

        0..8 | ForEach-Object { $grid.RowDefinitions.Add((New-Object RowDefinition)) }
        $grid.RowDefinitions[8].Height = "*"

        # Labels
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

        # TextBoxes
        $this.NameBox = New-Object TextBox
        $this.Process1Box = New-Object TextBox
        $this.Process2Box = New-Object TextBox
        $this.Process3Box = New-Object TextBox

        $textBoxes = @(
            @{ Box = $this.NameBox; Row = 1; Watermark = "Enter display name" },
            @{ Box = $this.Process1Box; Row = 3; Watermark = "Enter process name (required)" },
            @{ Box = $this.Process2Box; Row = 5; Watermark = "Enter process name (optional)" },
            @{ Box = $this.Process3Box; Row = 7; Watermark = "Enter process name (optional)" }
        )

        foreach ($boxInfo in $textBoxes) {
            $box = $boxInfo.Box
            $box.Margin = "0,5"
            $box.Padding = "5,3"
            $box.Background = New-Object SolidColorBrush([Colors]::White)
            $box.Foreground = New-Object SolidColorBrush([Colors]::Black)
            $box.BorderBrush = New-Object SolidColorBrush([Colors]::Gray)
            
            # Add watermark
            $box.Tag = $boxInfo.Watermark
            $box.Add_GotFocus({
                if ($this.Text -eq $this.Tag) {
                    $this.Text = ""
                    $this.Foreground = New-Object SolidColorBrush([Colors]::Black)
                }
            })
            $box.Add_LostFocus({
                if ([string]::IsNullOrWhiteSpace($this.Text)) {
                    $this.Text = $this.Tag
                    $this.Foreground = New-Object SolidColorBrush([Colors]::Gray)
                }
            })
            $box.Text = $boxInfo.Watermark
            $box.Foreground = New-Object SolidColorBrush([Colors]::Gray)
            
            [Grid]::SetRow($box, $boxInfo.Row)
            $grid.Children.Add($box)
        }

        # Button panel
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
        $okButton.Add_Click({ $this.ValidateAndAdd() })

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
                if ($e.Key -eq 'Enter') { $this.ValidateAndAdd() }
                elseif ($e.Key -eq 'Escape') { $this.DialogResult = $false }
            })
    }

	[void] ValidateAndAdd() {
		# Get actual text (ignore watermarks)
		$displayName = if ($this.NameBox.Text -eq $this.NameBox.Tag) { "" } else { $this.NameBox.Text.Trim() }
		$process1 = if ($this.Process1Box.Text -eq $this.Process1Box.Tag) { "" } else { $this.Process1Box.Text.Trim() }
		$process2 = if ($this.Process2Box.Text -eq $this.Process2Box.Tag) { "" } else { $this.Process2Box.Text.Trim() }
		$process3 = if ($this.Process3Box.Text -eq $this.Process3Box.Tag) { "" } else { $this.Process3Box.Text.Trim() }

		# Validation
		if ([string]::IsNullOrWhiteSpace($displayName)) {
			$this.Monitor.set_StatusMessage("Please enter a display name")
			$this.NameBox.Focus()
			return
		}

		if ([string]::IsNullOrWhiteSpace($process1) -and 
			[string]::IsNullOrWhiteSpace($process2) -and 
			[string]::IsNullOrWhiteSpace($process3)) {
			$this.Monitor.set_StatusMessage("Please enter at least one process name")
			$this.Process1Box.Focus()
			return
		}

		# Check for duplicate display name
		if ($this.Monitor.Config.ContainsKey($displayName)) {
			$this.Monitor.set_StatusMessage(("Process group '{0}' already exists" -f $displayName))
			$this.NameBox.Focus()
			return
		}

		# Validate process names
		$processes = @($process1, $process2, $process3) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
		foreach ($proc in $processes) {
			# Allow alphanumeric, dots, hyphens, and spaces in process names
			if ($proc -notmatch '^[a-zA-Z0-9\s\._-]+$') {
				$this.Monitor.set_StatusMessage(("Invalid process name (only letters, numbers, spaces, dots, and hyphens allowed): '{0}'" -f $proc))
				return
			}
			# Check length
			if ($proc.Length -gt 260) {  # Windows MAX_PATH
				$this.Monitor.set_StatusMessage(("Process name too long: '{0}'" -f $proc))
				return
			}
		}

		# Add to configuration
		$this.Monitor.Config[$displayName] = $processes
		$this.Monitor.RefreshProcesses()
		$this.Monitor.SaveConfiguration()
		$this.Monitor.set_StatusMessage(("Process group '{0}' added successfully" -f $displayName))
		$this.DialogResult = $true
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