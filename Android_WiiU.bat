@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DIY Wii U Display Manager

set "BASE_DIR=%~dp0"
set "CONFIG_FILE=%BASE_DIR%wiiu_config.txt"
set "SESSION_DIR=%BASE_DIR%wiiu_session"

if not exist "!SESSION_DIR!" mkdir "!SESSION_DIR!"

set "FOCUS_LOCK_PID_FILE=!SESSION_DIR!\focuslock.pid"

REM ==========================================================
REM DEFAULT SETTINGS
REM ==========================================================

set "SCRCPY_WIDTH=1920"
set "SCRCPY_HEIGHT=1080"
set "SCRCPY_BITRATE=12M"
set "SCRCPY_EXE="
set "LAUNCH_NIAGARA=1"
set "ADB_SERIAL="

REM ==========================================================
REM LOAD CONFIG
REM ==========================================================

if exist "!CONFIG_FILE!" (
    for /f "usebackq tokens=1,* delims==" %%A in ("!CONFIG_FILE!") do (
        if /I "%%A"=="SCRCPY_EXE" set "SCRCPY_EXE=%%B"
        if /I "%%A"=="SCRCPY_WIDTH" set "SCRCPY_WIDTH=%%B"
        if /I "%%A"=="SCRCPY_HEIGHT" set "SCRCPY_HEIGHT=%%B"
        if /I "%%A"=="SCRCPY_BITRATE" set "SCRCPY_BITRATE=%%B"
        if /I "%%A"=="LAUNCH_NIAGARA" set "LAUNCH_NIAGARA=%%B"
    )
)

del /q "!FOCUS_LOCK_PID_FILE!" >nul 2>&1

echo.
echo ==========================================
echo              Android Wii U
echo ==========================================
echo.

REM ==========================================================
REM FIND SCRCPY
REM ==========================================================

if defined SCRCPY_EXE (
    if exist "!SCRCPY_EXE!" goto SCRCPY_PATH_OK
)

echo scrcpy.exe was not found at the saved location.
echo.
echo Right-click scrcpy.exe in Windows Explorer and select:
echo   Copy as path
echo.
echo Paste the path below.
echo.

set /p "SCRCPY_EXE=Path to scrcpy.exe: "
set "SCRCPY_EXE=!SCRCPY_EXE:"=!"

if not exist "!SCRCPY_EXE!" (
    echo.
    echo ERROR: scrcpy.exe was not found.
    echo.
    pause
    exit /b 1
)

(
    echo SCRCPY_EXE=!SCRCPY_EXE!
    echo SCRCPY_WIDTH=!SCRCPY_WIDTH!
    echo SCRCPY_HEIGHT=!SCRCPY_HEIGHT!
    echo SCRCPY_BITRATE=!SCRCPY_BITRATE!
    echo LAUNCH_NIAGARA=!LAUNCH_NIAGARA!
) > "!CONFIG_FILE!"

echo.
echo scrcpy path saved.

:SCRCPY_PATH_OK

REM ==========================================================
REM ADB CONNECTION
REM ==========================================================

echo.
echo ==========================================
echo          WIRELESS ADB CONNECTION
echo ==========================================
echo.

echo Checking ADB...
echo.

where adb >nul 2>&1

if errorlevel 1 (
    echo ERROR: adb.exe was not found.
    echo.
    echo Make sure Android Platform-Tools is installed
    echo and adb.exe is available in PATH.
    echo.
    pause
    exit /b 1
)

adb start-server >nul 2>&1

REM ==========================================================
REM CONNECTION RETRY LOOP
REM ==========================================================

for /L %%R in (1,1,15) do (

    echo Attempt %%R/15...

    REM ------------------------------------------------------
    REM CHECK FOR ALREADY CONNECTED DEVICE
    REM ------------------------------------------------------

    set "ADB_SERIAL="

    for /f "skip=1 tokens=1,2" %%A in ('adb devices 2^>nul') do (
        if "%%B"=="device" (
            if not defined ADB_SERIAL (
                set "ADB_SERIAL=%%A"
            )
        )
    )

    if defined ADB_SERIAL (
        goto ADB_CONNECTED
    )

    REM ------------------------------------------------------
    REM CHECK mDNS SERVICES
    REM ------------------------------------------------------

    for /f "tokens=1,2,3,4" %%A in ('adb mdns services 2^>nul') do (

        set "CANDIDATE="

        REM Normal entry:
        REM NAME  _adb-tls-connect._tcp  IP:PORT

        if "%%B"=="_adb-tls-connect._tcp" (
            set "CANDIDATE=%%C"
        )

        REM Duplicate-name entry:
        REM NAME  (2)  _adb-tls-connect._tcp  IP:PORT

        if "%%C"=="_adb-tls-connect._tcp" (
            set "CANDIDATE=%%D"
        )

        if defined CANDIDATE (

            echo Found wireless ADB service:
            echo   !CANDIDATE!
            echo.
            echo Trying connection...
            echo.

            adb connect "!CANDIDATE!"

            timeout /t 1 /nobreak >nul

            REM --------------------------------------------------
            REM CHECK FOR REAL CONNECTED DEVICE
            REM --------------------------------------------------

            set "ADB_SERIAL="

            for /f "skip=1 tokens=1,2" %%E in ('adb devices 2^>nul') do (
                if "%%F"=="device" (
                    if not defined ADB_SERIAL (
                        set "ADB_SERIAL=%%E"
                    )
                )
            )

            if defined ADB_SERIAL (
                goto ADB_CONNECTED
            )

            echo.
            echo Connection attempt did not produce a usable
            echo ADB device.
            echo.
        )
    )

    if %%R LSS 15 (
        echo No connection yet. Retrying...
        echo.
        timeout /t 1 /nobreak >nul
    )
)

REM ==========================================================
REM ADB CONNECTION FAILED
REM ==========================================================

echo.
echo ==========================================
echo       ERROR: ADB CONNECTION FAILED
echo ==========================================
echo.

echo The Android device did not become available after 15 attempts.
echo Check whether Wireless Debugging was automatically turned off.
echo.

echo Current ADB devices:
echo ------------------------------------------
adb devices
echo ------------------------------------------

echo.
echo Current mDNS services:
echo ------------------------------------------
adb mdns services
echo ------------------------------------------
echo.

pause
exit /b 1

REM ==========================================================
REM ADB CONNECTED
REM ==========================================================

:ADB_CONNECTED

echo.
echo ==========================================
echo              ADB CONNECTED
echo ==========================================
echo.

echo ADB device detected:
echo   !ADB_SERIAL!
echo.

echo Current ADB devices:
echo ------------------------------------------
adb devices
echo ------------------------------------------
echo.

REM ==========================================================
REM CREATE VIRTUAL DISPLAY
REM ==========================================================

echo Creating !SCRCPY_WIDTH!x!SCRCPY_HEIGHT! virtual display...
echo.

if "!LAUNCH_NIAGARA!"=="1" (
    echo Niagara launcher: ENABLED
    echo.

    start "" "!SCRCPY_EXE!" ^
        -s "!ADB_SERIAL!" ^
        --new-display=!SCRCPY_WIDTH!x!SCRCPY_HEIGHT!/1 ^
        --start-app=bitpit.launcher ^
        --video-bit-rate=!SCRCPY_BITRATE! ^
        --fullscreen
) else (
    echo Niagara launcher: DISABLED
    echo.

    start "" "!SCRCPY_EXE!" ^
        -s "!ADB_SERIAL!" ^
        --new-display=!SCRCPY_WIDTH!x!SCRCPY_HEIGHT!/1 ^
        --video-bit-rate=!SCRCPY_BITRATE! ^
        --fullscreen
)

if errorlevel 1 (
    echo.
    echo ERROR: Failed to start scrcpy.
    echo.
    pause
    exit /b 1
)

echo Waiting for virtual display...
echo.

REM ==========================================================
REM FIND VIRTUAL DISPLAY
REM ==========================================================

set "DISPLAY_ID="

for /L %%N in (1,1,20) do (

    set "DISPLAY_LINE="
    set "DISPLAY_INFO="

    for /f "delims=" %%A in ('adb -s "!ADB_SERIAL!" shell dumpsys display 2^>nul ^| findstr /R /I /C:"Display [0-9][0-9]* \[id=virtual:com.android.shell,2000,scrcpy,"') do (
        set "DISPLAY_LINE=%%A"
    )

    if defined DISPLAY_LINE (

        for /f "tokens=2 delims=[]" %%A in ("!DISPLAY_LINE!") do (
            set "DISPLAY_INFO=%%A"
        )

        for /f "tokens=1" %%A in ("!DISPLAY_INFO!") do (
            set "DISPLAY_ID=%%A"
        )
    )

    if defined DISPLAY_ID goto DISPLAY_FOUND

    timeout /t 1 /nobreak >nul
)

REM ==========================================================
REM DISPLAY NOT DETECTED
REM ==========================================================

echo.
echo ==========================================
echo       ERROR: DISPLAY NOT DETECTED
echo ==========================================
echo.

echo Current display information:
echo ------------------------------------------
adb -s "!ADB_SERIAL!" shell dumpsys display
echo ------------------------------------------
echo.

pause
exit /b 1

REM ==========================================================
REM DISPLAY FOUND
REM ==========================================================

:DISPLAY_FOUND

echo Virtual display found:
echo   Display ID: !DISPLAY_ID!
echo.

REM ==========================================================
REM START CONTROLLER FOCUS LOCK
REM ==========================================================

echo Starting controller focus lock...
echo.

powershell -NoProfile -Command "$p=(Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-Command','adb -s ""!ADB_SERIAL!"" shell ""while true; do input -d !DISPLAY_ID! keyevent 0; sleep 0.01; done""' -PassThru); Set-Content -Path '!FOCUS_LOCK_PID_FILE!' -Value $p.Id"

timeout /t 1 /nobreak >nul

echo.
echo ==========================================
echo                  READY
echo ==========================================
echo.

echo ADB device     : !ADB_SERIAL!
echo Game display   : !DISPLAY_ID!
echo Phone display  : 0

if "!LAUNCH_NIAGARA!"=="1" (
    echo Niagara        : Enabled
) else (
    echo Niagara        : Disabled
)

echo.
echo Physical controller focus is locked to:
echo   Display !DISPLAY_ID!
echo.
echo Touching the Android device should not steal controller focus.
echo.
echo When finished:
echo	- Return to home screen on Android device (IMPORTANT - Otherwise your home icons may reset!)
echo	- Close Android Wii U
echo	- Close scrcpy
echo.

pause

REM ==========================================================
REM CLEANUP
REM ==========================================================

if exist "!FOCUS_LOCK_PID_FILE!" (

    set /p "FOCUS_PID="<"!FOCUS_LOCK_PID_FILE!"

    if defined FOCUS_PID (
        taskkill /PID !FOCUS_PID! /F >nul 2>&1
    )

    del /q "!FOCUS_LOCK_PID_FILE!" >nul 2>&1
)

adb kill-server >nul 2>&1

exit /b 0