:: Initiation
@echo off
Echo.
Echo.

:: Check for argument indicating this is a relaunched instance
if "%~1"=="admin" goto :RunScript

:: Get Admin Rights
set "CurrentDir=%~dp0"
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with admin rights
) else (
    echo Running without admin rights, relaunching with admin rights...
    PowerShell -Command "Start-Process -FilePath '%0' -ArgumentList 'admin' -WorkingDirectory '%CurrentDir%' -Verb RunAs"
    exit /b
)

:RunScript
cd /d "%CurrentDir%"
Echo.
Echo.

:: Run PowerShell Command
Echo Running the script...
echo.
@echo on
powershell -ExecutionPolicy Bypass -File "%~dp0gamenotover.ps1"
@echo off
Echo.

:: Exit Program
echo Program has exited, press any key to close...
pause > nul
