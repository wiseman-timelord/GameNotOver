# GameNotOver
### Status: Updating Now

### Description:
GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an Avalonia UI. When using programs in windows 10, upon, exiting or crashing, some programs may leave a residual 500MB-4GB, that, lock files in place or prevent loading, for example beta programes, additionally some programs may freeze, which may even cause issues shutting down. My application is a manageable shortlist for closing all instances of pre-selected troublesome programs, thus, saving on repeatingly, running task manager and searching for running processes, each time. There are some default apps already, but as I mentioned you will be able to manage the list within the program.

### Features:
1. **Interactive Menu Selection: Categorized into A.I.**, Media, Games, and System, the menu offers an intuitive navigation experience, allowing users to terminate with ease.
2. **Forceful Termination of Processes:** Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. **Robust Error Handling:** Designed to gracefully manage errors, such as unfound processes, ensuring a smooth user experience without abrupt script termination.
4. **Administrative Privilege Check:** Incorporates a built-in check for administrative rights, guaranteeing that the script has the required permissions to perform its tasks.

### Output:
- Picture coming soon...

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
│   ├── list.txt  # Customizeable process list
│   └── AvaloniaUI\  # Avalonia UI components installed by installer from SDK
│       ├── Avalonia.dll
│       ├── Avalonia.Controls.dll
│       ├── Avalonia.Markup.Xaml.dll
│       └── ...
└── temp\  =used during install
```

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
