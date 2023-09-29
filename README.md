# GameNotOver
Status: Working.

### Update: 2023/09/29
- Window Resizing and Title Setting - Moved window resize to the powershell script, and made window little bigger.
- Some, organization and improvement, of, code and text.
- Refined choices on the example menu, reduced games to just, Fallout and Skyrim.

### Description:

GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an interactive menu. 
When using programs in windows 10, upon, exiting or instances of crash, some specific programs typically leave a residual 500MB-4GB, that, lock files in place or prevent loading, for example modding beta games. Additionally some applications may, crash and ui hang, to then not close through, [x] or taskbar. So this application creates a shortlist for closing those troublesome applications, saving on repeatingly, running task manager and searching for running processes.
The script is intended to be hacked by the user, so as, through, analysis of the script and adding/removing/editing pre-existing lines in 2 loctions in the last 30 lines of the script, can be, customized and optimized, for your own preference of programs. 
Programs currently featured in the program are, ChatGPT (LenX), PaintShop Pro, Bannerlord, Kenshi, they give a good enough demonstration of the format of the code, when you run the app in parallel to editing the code, its not complicated.

### Features:

1. **Interactive Menu Selection: Categorized into A.I.**, Media, Games, and System, the menu offers an intuitive navigation experience, allowing users to terminate with ease.
2. **Forceful Termination of Processes:** Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. **Robust Error Handling:** Designed to gracefully manage errors, such as unfound processes, ensuring a smooth user experience without abrupt script termination.
4. **Administrative Privilege Check:** Incorporates a built-in check for administrative rights, guaranteeing that the script has the required permissions to perform its tasks.

### Output:
The app looks like this..
```

                   GAME NOT OVER!

 Please select which programs to terminate..

  A.I.:
      ChatGPT (LenX)

  Media:
      PaintShop Pro (Corel/Jasc)

  Games:
      Fallout (3/NV/4)
      Skyrim (Legacy/SE)

  Options:
      Exit Menu


```
##

### Usage:

1. Execute the batch "GameNotOver.bat" to launch the gamenotover.ps1 powershell script as Admin.
2. Utilize the arrow keys to navigate the menu and highlight the desired program for termination.
3. Press the Enter key to initiate the termination of the selected program(s).
4. A confirmation message will appear, prompting you to press any key to continue.
5. Select "Exit Menu" to gracefully exit GameNotOver, or keep the app in the background.
6. The "GameNotOver.lnk" shortcut provided with preset arguements to run ".bat" on taskbar.

### Requirements:

- Windows 2008 R2, 2012, 8.1, 10 (Powershell)
- Administrative rights.

### Disclaimer:

GameNotOver is designed to forcefully terminate processes, which may lead to the loss of unsaved data or other unexpected consequences in the terminated applications. 
It is strongly advised to save all work before utilizing GameNotOver to close any program. Use at your own discretion and risk.
