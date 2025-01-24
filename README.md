# GameNotOver
### Status: Updating Now - Here is the readme to the next version, it will be UPGRADED. For now the releases are the working but are non-GUI versions. The purpose of going back to this program, is to figure out avalonia issues with a simpler program first.

### Development
- The plan is to have a GUI using avalonia...
1. There was no need for an installer, as we are not using avalonia now. >_> 2 days gone!!
2. Program needs conversion from Avalonia to WPF.
3. testing and bugfixing.

### Files list...
```
.\  # Root folder
.\GameNotOver.bat  # Entry point for user
.\main_script.ps1  # Entry point for the main program
├── scripts\  # Scripts folder
│   ├── interface.ps1  # Interface script
├── data\  # Data folder
│   └── ****.***  # some kind of persistent configuration file.
```

### Description:
GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an GUI. When using programs in windows 10, upon, exiting or crashing, some programs may leave a residual 500MB-4GB, that, lock files in place or prevent loading, for example beta programes, additionally some programs may freeze, which may even cause issues shutting down. My application is a manageable shortlist for closing all instances of pre-selected troublesome programs, thus, saving on repeatingly, running task manager and searching for running processes, each time. There are some default apps already, but as I mentioned you will be able to manage the list within the program.

### Features:
1. Graphical User Interface - For managing the list and user interacctions, with persistence in the text file in `.\data`.
2. Forceful Termination of Processes - Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. Batch Launcher - For easy running of Powershell Script at the click of a button.

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
3. Select 1 to run the main program, this runs `.\main_script.ps1`.
4. ...

## Notes
- None currently

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
