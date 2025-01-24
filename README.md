# GameNotOver
### Status: Updating Now - Here is the readme to the next version, it will be UPGRADED. For now the releases are the working but are non-GUI versions. The purpose of going back to this program, is to figure out avalonia issues with a simpler program first.

### Development
- The plan is to have a GUI using avalonia...
1. Installer done, but some issue with the avalonia.styling not actually existing, so we lopped it off after 5 hours of banging my head against the monitor.
2. Program needs testing and bugfixing.
3. move settings to a psd1 and include functions for expimppsd1,  possibly even a utility script.

### Files list...
```
.\  # Root folder
.\GameNotOver.bat  # Entry point for user
.\launcher.ps1  # Entry point for the main program
.\installer.ps1 # The main script
├── scripts\  # Scripts folder
│   ├── interface.ps1  # Interface script
│   └── interface.xml  # Interface config 
├── data\  # Data folder created by installer
│   └── AvaloniaUI\  # Avalonia UI components installed by installer from SDK
│   │   ├── Avalonia.Base.dll
│   │   ├── Avalonia.Controls.dll
│   │   ├── Avalonia.Desktop.dll
│   │   ├── Avalonia.Markup.dll
│   │   ├── Avalonia.Markup.Xaml.dll
│   │   └── Avalonia.Themes.Default.dll
└── temp\  =used during install
```

### Description:
GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an Avalonia UI. When using programs in windows 10, upon, exiting or crashing, some programs may leave a residual 500MB-4GB, that, lock files in place or prevent loading, for example beta programes, additionally some programs may freeze, which may even cause issues shutting down. My application is a manageable shortlist for closing all instances of pre-selected troublesome programs, thus, saving on repeatingly, running task manager and searching for running processes, each time. There are some default apps already, but as I mentioned you will be able to manage the list within the program.

### Features:
1. Graphical User Interface - For managing the list and user interacctions, with persistence in the text file in `.\data`.
2. Forceful Termination of Processes - Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. Batch Installer/Launcher - For installing requirements and launching the powershell scripts at the click of a button.

### Preview:
- Picture of main program coming soon...
- The Batch Installer/Launcher...
```
========================================================================================================================
    GameNotOver - Main Menu
========================================================================================================================

    1. Launch GameNotOver

    2. Install Requirements

------------------------------------------------------------------------------------------------------------------------
Selection; Options = 1-2, Exit = X: 2
```


### Requirements:
- Windows 10 - the scripts are in Powershell.
- Libraries - The installer handles, AvaloniaUI and DotNet-Sdk (zip).
- [DotNet](https://dotnet.microsoft.com/en-us/download/dotnet/8.0) - Avalonia requires either DotNet 6 or 8.

### Usage:
1. Execute the batch "GameNotOver.bat" as Administrator, to launch the batch menu.
2. Select 2 to install any library requirements, this will take you to the menu after.
3. Select 1 to run the main program, this runs `.\launcher.ps1`.
4. ...

## Credits
- [Avalonia UI](https://github.com/AvaloniaUI/Avalonia) - Multi-Platform Graphical User Interface.

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
