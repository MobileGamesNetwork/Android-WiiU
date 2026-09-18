@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Install ADB to PATH

echo.
echo ==========================================
echo        ADB / PLATFORM-TOOLS SETUP
echo ==========================================
echo.

echo Checking for winget...
where winget >nul 2>&1

if errorlevel 1 (
    echo.
    echo ERROR: winget was not found.
    echo.
    echo Install/update App Installer from the Microsoft Store,
    echo then run this script again.
    echo.
    pause
    exit /b 1
)

echo.
echo Installing Android SDK Platform-Tools...
echo.

winget install --id Google.PlatformTools --exact --accept-source-agreements --accept-package-agreements

if errorlevel 1 (
    echo.
    echo ERROR: Platform-Tools installation failed.
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo          FINDING PLATFORM-TOOLS
echo ==========================================
echo.

set "ADB_DIR="

for /f "delims=" %%A in ('where adb 2^>nul') do (
    if not defined ADB_DIR (
        set "ADB_PATH=%%A"
        for %%B in ("%%A") do set "ADB_DIR=%%~dpB"
    )
)

if not defined ADB_DIR (
    echo ADB was installed, but Windows cannot find adb.exe yet.
    echo.
    echo This can happen because the current CMD window has the old PATH.
    echo.
    echo Please close this window and open a new Command Prompt.
    echo Then run:
    echo.
    echo    adb version
    echo.
    pause
    exit /b 0
)

set "ADB_DIR=!ADB_DIR:~0,-1!"

echo ADB found at:
echo !ADB_DIR!
echo.

echo Adding ADB to the system PATH...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$path=[Environment]::GetEnvironmentVariable('Path','Machine'); $dir='!ADB_DIR!'; if (($path -split ';') -notcontains $dir) { [Environment]::SetEnvironmentVariable('Path',(($path.TrimEnd(';')+';'+$dir)),'Machine'); Write-Host 'ADB added to system PATH.' } else { Write-Host 'ADB is already in system PATH.' }"

if errorlevel 1 (
    echo.
    echo ERROR: Could not modify the system PATH.
    echo Make sure this BAT was run as Administrator.
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo                COMPLETE
echo ==========================================
echo.

echo ADB has been installed and added to the system PATH.
echo.
echo IMPORTANT:
echo Close this Command Prompt and open a NEW one.
echo Then test with:
echo.
echo    adb version
echo.

pause