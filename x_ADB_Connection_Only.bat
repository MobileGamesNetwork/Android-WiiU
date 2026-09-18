@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Android ADB Connection

echo.
echo ==========================================
echo          ANDROID ADB CONNECTION
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
    REM CHECK WIRELESS ADB mDNS SERVICES
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

            echo.
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
            echo Connection attempt failed.
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
REM CONNECTION FAILED
REM ==========================================================

echo.
echo ==========================================
echo          ADB CONNECTION FAILED
echo ==========================================
echo.

echo No Android device could be connected.
echo.

echo Current ADB devices:
echo ------------------------------------------
adb devices
echo ------------------------------------------

echo.
echo Current wireless ADB services:
echo ------------------------------------------
adb mdns services
echo ------------------------------------------
echo.

pause
exit /b 1

REM ==========================================================
REM CONNECTED
REM ==========================================================

:ADB_CONNECTED

echo.
echo ==========================================
echo             ADB CONNECTED
echo ==========================================
echo.

echo Device:
echo   !ADB_SERIAL!
echo.

echo Current ADB devices:
echo ------------------------------------------
adb devices
echo ------------------------------------------
echo.

echo The Android device is now connected to this PC.
echo You can use ADB commands normally.
echo.

pause
exit /b 0