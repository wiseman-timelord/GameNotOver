:: Initiation
@echo off
Echo.
Echo.


:: Get Admin Rights
set "CurrentDir=%~dp0"
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with admin rights
) else (
    echo Running without admin rights, relaunching with admin rights...
    PowerShell -Command "Start-Process -FilePath '%0' -WorkingDirectory '%CurrentDir%' -Verb RunAs"
    exit /b
)
cd /d "%CurrentDir%"
Echo.
Echo.


:: Run PowerShell Command
Echo Running the script...
echo.
@echo on
powershell -ExecutionPolicy Bypass -File "gamenotover.ps1"
@echo off
Echo.


:: Exit Program
echo Script has exited, press any key to continue...
pause > nul