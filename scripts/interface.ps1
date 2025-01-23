using namespace Avalonia
using namespace Avalonia.Controls
using namespace Avalonia.Controls.ApplicationLifetimes
using namespace Avalonia.Markup.Xaml
using namespace System.Xml

# Define the App class for Avalonia initialization
class App : Application {
    App() {
        # Load the XAML for the application
        AvaloniaXamlLoader.Load($this)
    }

    [void] OnFrameworkInitializationCompleted() {
        # Set up the main window if running in a desktop environment
        if ($this.ApplicationLifetime -is [IClassicDesktopStyleApplicationLifetime]) {
            $this.ApplicationLifetime.MainWindow = [MainWindow]::new()
        }
        base.OnFrameworkInitializationCompleted()
    }
}

# Define the MainWindow class
class MainWindow : Window {
    [XmlDocument]$ConfigXml
    [hashtable]$Categories = @{}
    [System.Collections.ObjectModel.ObservableCollection[string]]$ProcessItems = `
        New-Object System.Collections.ObjectModel.ObservableCollection[string]
    [string]$StatusMessage = ""
    hidden [bool]$IsClosing = $false

    MainWindow() {
        try {
            # Load the XAML for the window
            [AvaloniaXamlLoader]::Load($this)
            $this.DataContext = $this

            # Handle the window closing event
            $this.Closing += { param($s, $e) 
                if (-not $this.IsClosing) { 
                    $e.Cancel = $true 
                    $this.HandleClosing()
                }
            }

            # Load configuration and initialize events
            $this.LoadConfig()
            $this.InitEvents()

            # Start process monitoring
            $this.StartProcessMonitor()
        } catch {
            throw
        }
    }

    [void] LoadConfig() {
        try {
            # Load the configuration XML file
            $this.ConfigXml = New-Object XmlDocument
            $this.ConfigXml.Load(".\scripts\interface.xml")
            $this.Categories.Clear()
            $this.ProcessItems.Clear()

            # Parse process definitions from the XML
            foreach ($cat in $this.ConfigXml.SelectNodes("//ResourceDictionary[@x:Key='ProcessDefinitions']//x:Array")) {
                $catName = $cat.GetAttribute("x:Key").Split('.')[0]
                $this.Categories[$catName] = @{}
                foreach ($proc in $cat.ChildNodes) {
                    $name, $ids = $proc.InnerText -split '\|'
                    $this.Categories[$catName][$name] = $ids.Split(',')
                    $this.UpdateProcessCount($catName, $name)
                }
            }

            # Parse custom processes from the XML
            $customProcessesNode = $this.ConfigXml.SelectSingleNode("//CustomProcesses")
            if ($customProcessesNode) {
                foreach ($proc in $customProcessesNode.ChildNodes) {
                    $name, $ids = $proc.InnerText -split '\|'
                    $this.Categories["Custom"] = @{} if (-not $this.Categories.ContainsKey("Custom"))
                    $this.Categories["Custom"][$name] = $ids.Split(',')
                    $this.UpdateProcessCount("Custom", $name)
                }
            }

            # Populate the category selector
            $this.FindControl<ComboBox>("CategorySelector").Items = $this.Categories.Keys
            $this.StatusMessage = "Configuration loaded"
        } catch {
            $this.StatusMessage = "Failed to load configuration"
            throw
        }
    }

    [void] UpdateProcessCount($category, $name) {
        $count = 0
        foreach ($id in $this.Categories[$category][$name]) {
            $count += @(Get-Process -Name $id -ErrorAction SilentlyContinue).Count
        }
        $displayName = "$category - $name ($count running)"
        
        # Update or add to ProcessItems
        $existingIndex = $this.ProcessItems.IndexOf("$category - $name")
        if ($existingIndex -ge 0) {
            $this.ProcessItems[$existingIndex] = $displayName
        } else {
            $this.ProcessItems.Add($displayName)
        }
    }

    [void] StartProcessMonitor() {
        $self = $this
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 5000 # Update every 5 seconds
        $timer.Add_Elapsed({
            $self.Dispatcher.InvokeAsync({
                foreach ($cat in $self.Categories.Keys) {
                    foreach ($name in $self.Categories[$cat].Keys) {
                        $self.UpdateProcessCount($cat, $name)
                    }
                }
            })
        })
        $timer.Start()
    }

    [void] SaveConfig() {
        try {
            # Save process definitions to the XML file
            foreach ($cat in $this.Categories.Keys) {
                if ($cat -eq "Custom") {
                    # Handle custom processes separately
                    $customNode = $this.ConfigXml.SelectSingleNode("//CustomProcesses")
                    if (-not $customNode) {
                        $customNode = $this.ConfigXml.CreateElement("CustomProcesses")
                        $this.ConfigXml.DocumentElement.AppendChild($customNode)
                    }
                    $customNode.InnerXml = ""
                    foreach ($proc in $this.Categories[$cat].Keys) {
                        $ids = $this.Categories[$cat][$proc] -join ','
                        $procNode = $this.ConfigXml.CreateElement("Process")
                        $procNode.InnerText = "$proc|$ids"
                        $customNode.AppendChild($procNode)
                    }
                } else {
                    # Handle predefined categories
                    $node = $this.ConfigXml.SelectSingleNode("//x:Array[@x:Key='$cat.Processes']")
                    if ($node) {
                        $node.InnerXml = ""
                        foreach ($proc in $this.Categories[$cat].Keys) {
                            $ids = $this.Categories[$cat][$proc] -join ','
                            $procNode = $this.ConfigXml.CreateElement("x:String")
                            $procNode.InnerText = "$proc|$ids"
                            $node.AppendChild($procNode)
                        }
                    }
                }
            }

            # Save the updated XML
            $this.ConfigXml.Save(".\scripts\interface.xml")
            $this.StatusMessage = "Configuration saved"
        } catch {
            $this.StatusMessage = "Failed to save configuration"
            throw
        }
    }

    [void] InitEvents() {
        # Bind button click events
        $this.FindControl<Button>("TerminateButton").Add_Click({ $this.TerminateSelected() })
        $this.FindControl<Button>("RefreshButton").Add_Click({ $this.LoadConfig() })
        $this.FindControl<Button>("AddProcess").Add_Click({ $this.AddProcess() })
        $this.FindControl<Button>("RemoveProcess").Add_Click({ $this.RemoveSelected() })
    }

    [void] TerminateSelected() {
        $selected = $this.FindControl<ListBox>("ProcessList").SelectedItem
        if ($selected -match '^(.+?) - (.+?) \(\d+') {
            $cat = $matches[1]
            $name = $matches[2]
            try {
                $terminated = $false
                foreach ($id in $this.Categories[$cat][$name]) {
                    $procs = Get-Process -Name $id -ErrorAction SilentlyContinue
                    if ($procs) {
                        foreach ($proc in $procs) {
                            Stop-Process -Id $proc.Id -Force
                            $terminated = $true
                        }
                    }
                }
                $this.UpdateProcessCount($cat, $name)
                $this.StatusMessage = if ($terminated) { "Process(es) terminated" } else { "No running processes found" }
            } catch {
                $this.StatusMessage = "Failed to terminate process: $_"
            }
        }
    }

    [void] AddProcess() {
        $name = $this.FindControl<TextBox>("NewProcessName").Text
        $ids = $this.FindControl<TextBox>("NewProcessId").Text
        $cat = $this.FindControl<ComboBox>("CategorySelector").SelectedItem
        
        if ($name -and $ids -and $cat) {
            try {
                $this.Categories[$cat][$name] = $ids.Split(',')
                $this.UpdateProcessCount($cat, $name)
                $this.SaveConfig()
                $this.FindControl<TextBox>("NewProcessName").Text = ""
                $this.FindControl<TextBox>("NewProcessId").Text = ""
                $this.StatusMessage = "Process added: $name"
            } catch {
                $this.StatusMessage = "Failed to add process"
            }
        }
    }

    [void] RemoveSelected() {
        $selected = $this.FindControl<ListBox>("ProcessList").SelectedItem
        if ($selected -match '^(.+?) - (.+?) \(\d+') {
            try {
                $cat = $matches[1]
                $name = $matches[2]
                $this.Categories[$cat].Remove($name)
                $this.ProcessItems.Remove($selected)
                $this.SaveConfig()
                $this.StatusMessage = "Process removed: $name"
            } catch {
                $this.StatusMessage = "Failed to remove process"
            }
        }
    }

    [void] HandleClosing() {
        try {
            $this.SaveConfig()
            $this.IsClosing = $true
            $this.Close()
        } catch {
            $this.StatusMessage = "Error during shutdown"
        }
    }
}

# Start the Avalonia application
try {
    [AppBuilder]::Configure([App]::new())
        .UsePlatformDetect()
        .LogToTrace()
        .StartWithClassicDesktopLifetime(@())
} catch {
    throw
}