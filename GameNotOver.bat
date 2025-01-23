REM .\GameNotOver.bat
@echo off
setlocal enabledelayedexpansion

REM Global Variables
set "LAUNCHER=.\launcher.ps1"
set "INSTALLER=.\installer.ps1"
set "TITLE=GameNotOver

REM Set window title and color scheme
title %TITLE%
color 1F

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Error: Admin Required!
    timeout /t 2 >nul
    echo Right Click, Run As Administrator.
    timeout /t 2 >nul
    goto :end_of_script
)
echo Status: Administrator
timeout /t 1 >nul

REM Functions
goto :SkipFunctions

:DisplayTitle
echo ========================================================================================================================
echo     %TITLE% - %~1
echo ========================================================================================================================
echo.
goto :eof

:DisplaySeparator
echo ------------------------------------------------------------------------------------------------------------------------
goto :eof

:MainMenu
cls
call :DisplayTitle "Main Menu"
echo     1. Launch %TITLE%
echo.
echo     2. Install Requirements
echo.
call :DisplaySeparator
set /p "choice=Selection; Options = 1-2, Exit = X: "

REM Process user input
if /i "%choice%"=="1" (
    cls
    call :DisplayTitle "Initialization"
    echo Starting %TITLE%...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%"
    if errorlevel 1 (
        echo Error launching %TITLE%
        pause
    )
    goto MainMenu
)

if /i "%choice%"=="2" (
    cls
    call :DisplayTitle "Installation"
    echo Installing Requirements...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
    if errorlevel 1 (
        echo Error during installation
        pause
    )
    goto MainMenu
)

if /i "%choice%"=="X" (
    cls
    call :DisplayTitle "Shutdown"
    echo Closing %TITLE%...
    timeout /t 2 >nul
    goto :end_of_script
)

REM Invalid input handling
echo.
echo Invalid selection. Please try again.
timeout /t 2 >nul
goto MainMenu

:SkipFunctions
goto MainMenu

:end_of_script
exit