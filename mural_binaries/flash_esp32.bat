@echo off
REM ESP32 Flash Batch Wrapper
REM This batch file runs the PowerShell flash script

echo Starting ESP32 Flash Script...
echo.

PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0flash_esp32.ps1"

if errorlevel 1 (
    echo.
    echo Script execution failed!
    pause
)
