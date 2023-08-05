# GameNotOver
Status: Working.

## Description
GameNotOver is a PowerShell application tailored for Windows users, enabling them to forcefully close all instances of selected programs through an interactive menu
The script is also a framework, that through, analysis of the script and adding/removing lines in 2 loctions, can be customized for your own preference of programs. 
When modding games in windows 10, these games would typically leave a residual 500MB-4GB, that would lock mods in place or prevent the game from loading.
It is also intended to be a shortlist for closing those applications, known to hang and that you use most intensively, saving on manual intervention.

## Features

1. **Interactive Menu Selection:** Categorized into A.I., Media, Games, and System, the menu offers an intuitive navigation experience, allowing users to terminate with ease.
2. **Forceful Termination of Processes:** Empowers users to forcefully close all occurrences of selected applications, effectively handling unresponsive or crashed programs.
3. **Robust Error Handling:** Designed to gracefully manage errors, such as unfound processes, ensuring a smooth user experience without abrupt script termination.
4. **Administrative Privilege Check:** Incorporates a built-in check for administrative rights, guaranteeing that the script has the required permissions to perform its tasks.

## Usage

1. Execute the script to launch the GameNotOver menu.
2. Utilize the arrow keys to navigate the menu and highlight the desired program for termination.
3. Press the Enter key to initiate the termination of the selected program.
4. A confirmation message will appear, prompting you to press any key to continue.
5. Select "Exit Menu" to gracefully exit GameNotOver.

## Requirements

- Windows 2008 R2, 2012, 8.1, 10 (Powershell)
- Administrative rights.

## Disclaimer

GameNotOver is designed to forcefully terminate processes, which may lead to the loss of unsaved data or other unexpected consequences in the terminated applications. 
It is strongly advised to save all work before utilizing GameNotOver to close any program. Use at your own discretion and risk.
