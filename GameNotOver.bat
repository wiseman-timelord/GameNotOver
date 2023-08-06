:: Initiation
@echo off
mode 50,20
Echo.
Echo.


:: Get the current directory
set "CurrentDir=%~dp0"

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with admin rights
) else (
    echo Running without admin rights, relaunching with admin rights...
    PowerShell -Command "Start-Process -FilePath '%0' -WorkingDirectory '%CurrentDir%' -Verb RunAs"
    exit /b
)
Echo.
Echo.


:: Change to the directory of the batch file
cd /d "%CurrentDir%"
Echo.
Echo.


:: Welcome To App
Echo Its time to end this game!
Echo.
Echo.


:: Run PowerShell Command
@echo on
powershell -ExecutionPolicy Bypass -File "gamenotover.ps1"
@echo off
Echo.
Echo.


:: Exit Program
pause