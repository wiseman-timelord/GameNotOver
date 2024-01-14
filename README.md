# GameNotOver
### Status:
Working(ish). The batches for this program may only run on Windows 10 due to the different PowerShell launch commands required for various OS versions, that microsoft have bizarly chosen to use for each OS, and may cause endless launch loop on other systems.

### Description:

GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an interactive menu. 
When using programs in windows 10, upon, exiting or crashing, some programs may leave a residual 500MB-4GB, that, lock files in place or prevent loading, for example beta programes, additionally some programs may freeze, so this application is a framework for a personalized shortlist for closing troublesome programs, thus, saving on repeatingly, running task manager and searching for running processes, each time.
The script is intended to be edited by the user, so as, through, analysis of the script and adding/removing/editing pre-existing lines, currently featured are, ChatGPT (LenX), PaintShop Pro, Skyrim, Fallout, they give a good enough demonstration of the scripts, and its not complicated to edit, just need to get the entries in both locations in the "# Menu Options and Main Loop" exactly the same, but for each line you add, you will have to set the window height +1 in "# Function to Resize Window and Set Title".

### Features:

1. **Interactive Menu Selection: Categorized into A.I.**, Media, Games, and System, the menu offers an intuitive navigation experience, allowing users to terminate with ease.
2. **Forceful Termination of Processes:** Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. **Robust Error Handling:** Designed to gracefully manage errors, such as unfound processes, ensuring a smooth user experience without abrupt script termination.
4. **Administrative Privilege Check:** Incorporates a built-in check for administrative rights, guaranteeing that the script has the required permissions to perform its tasks.

### Output:
The app looks like this..
```

                  GAME NOT OVER!

 Please select which programs to terminate...

  A.I.:
      ChatGPT (LenX)

  Media:
      PaintShop Pro (Corel/Jasc)
      PhotoShop (All)

  Games:
      Fallout (3/NV/4)
      Skyrim (Legacy/SE)

  Options:
    > Exit Menu

```
##

### Usage:

1. Execute the batch "GameNotOver.bat" to launch the gamenotover.ps1 powershell script as Admin.
2. Utilize the arrow keys to navigate the menu and highlight the desired program for termination.
3. Press the Enter key to initiate the termination of the selected program(s).
4. A confirmation message will appear, prompting you to press any key to continue.
5. Select "Exit Menu" to gracefully exit GameNotOver, or keep the app in the background.
* To run from taskbar the "GameNotOver.lnk" is provided, but it needs new locations in its properties.

### Requirements:

- Windows 2008 R2, 2012, 8.1, 10 (Powershell)
- Administrative rights.

### DISCLAIMER
Read "Licence.Txt", its, what its there for and why its supplied with the package.
