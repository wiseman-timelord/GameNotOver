# GameNotOver
### Status: Updating Now - Here is the readme to the next version, it will be UPGRADED. For now the releases are the working but non-GUI versions.

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
- Admin - Batch must be run with Administrative rights.

### Usage:
1. Execute the batch "GameNotOver.bat" to launch the gamenotover.ps1 powershell script as Admin.
2. Utilize the arrow keys to navigate the menu and highlight the desired program for termination.
3. Press the Enter key to initiate the termination of the selected program(s).
4. A confirmation message will appear, prompting you to press any key to continue.
5. Select "Exit Menu" to gracefully exit GameNotOver, or keep the app in the background.
* To run from taskbar the "GameNotOver.lnk" is provided, but it needs new locations in its properties.

## Development
- Files list...
```
.\  # Root folder
.\GameNotOver.bat  # Entry point for user
.\launcher.ps1  # Entry point for the main program
.\installer.ps1 # The main script
.\GameNotOver.bat  # Entry point for user
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
│   │   ├── Avalonia.Styling.dll
│   │   └── Avalonia.Themes.Default.dll
└── temp\  =used during install
```

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
