@echo off
setlocal

title GitHub APK Installer

set "SCRIPT=%~dp0github_apk_installer.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: github_apk_installer.ps1 was not found.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
pause