@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DIY Wii U - Wireless ADB Pairing

echo.
echo ==========================================
echo       DIY Wii U WIRELESS ADB SETUP
echo ==========================================
echo.
echo This is a ONE-TIME setup.
echo You should NOT need a USB cable.
echo.
echo Your Android device and PC must be connected to
echo the SAME Wi-Fi network.
echo.
pause

REM ==========================================================
REM CHECK ADB
REM ==========================================================

echo.
echo Checking ADB...
echo.

where adb >nul 2>&1

if errorlevel 1 (
echo ERROR: ADB was not found.
echo.
echo Make sure adb.exe is installed and available
echo in your PATH, or place this BAT file in your
echo Android Platform-Tools folder.
echo.
pause
exit /b 1
)

adb start-server >nul 2>&1

REM ==========================================================
REM FIND PHONE IP
REM ==========================================================

echo.
echo ==========================================
echo       STEP 1 - ENTER PHONE IP
echo ==========================================
echo.
echo On your Android device:
echo.
echo 1. Open Settings.
echo.
echo 2. Open Wi-Fi / Network and Internet.
echo.
echo 3. Tap the Wi-Fi network you are
echo    currently connected to.
echo.
echo 4. Find the IPv4 address.
echo.
echo    Example:
echo      192.168.0.100
echo.
echo IMPORTANT:
echo.
echo Use the IPv4 address from your phone's
echo Wi-Fi network settings.
echo.
echo DO NOT use the IP address shown later in
echo the "Pair device with pairing code" popup.
echo.
set /p "PHONE_IP=Phone IPv4 address: "

if not defined PHONE_IP (
echo.
echo ERROR: No IP address entered.
echo.
pause
exit /b 1
)

REM ==========================================================
REM WIRELESS DEBUGGING PAIRING
REM ==========================================================

echo.
echo ==========================================
echo       STEP 2 - WIRELESS DEBUGGING
echo ==========================================
echo.
echo Now go to:
echo.
echo   Settings
echo   ^> Developer options
echo   ^> Wireless debugging
echo.
echo Then select:
echo.
echo   Pair device with pairing code
echo.
echo A popup should appear showing:
echo.
echo   - An IP address
echo   - A pairing port
echo   - A 6-digit pairing code
echo.
pause

REM ==========================================================
REM GET PAIRING PORT
REM ==========================================================

echo.
echo ==========================================
echo       STEP 3 - ENTER PAIRING PORT
echo ==========================================
echo.
echo Enter the PAIRING PORT shown in the
echo "Pair device with pairing code" popup.
echo.
echo Example:
echo   39894
echo.
set /p "PAIR_PORT=Pairing port: "

if not defined PAIR_PORT (
echo.
echo ERROR: No pairing port entered.
echo.
pause
exit /b 1
)

set "PAIR_ADDRESS=!PHONE_IP!:!PAIR_PORT!"

REM ==========================================================
REM PAIR
REM ==========================================================

echo.
echo ==========================================
echo             STEP 4 - PAIR
echo ==========================================
echo.
echo Running:
echo.
echo   adb pair !PAIR_ADDRESS!
echo.
echo When prompted, enter the 6-digit
echo pairing code shown on your Android device.
echo.
echo ------------------------------------------
echo.

adb pair "!PAIR_ADDRESS!"

if errorlevel 1 (
echo.
echo ==========================================
echo          PAIRING FAILED
echo ==========================================
echo.
echo Check that:
echo.
echo - The IPv4 address came from the Android device's
echo   Wi-Fi network settings.
echo - You used the PAIRING port from the
echo   pairing-code popup.
echo - The pairing code is correct.
echo - The Android device and PC are on the same Wi-Fi.
echo - Wireless debugging is enabled.
echo.
pause
exit /b 1
)

REM ==========================================================
REM SUCCESS
REM ==========================================================

echo.
echo ==========================================
echo          PAIRING SUCCESSFUL
echo ==========================================
echo.
echo Your PC is now paired with this Android device.
echo.
echo You normally only need to do this once.
echo.

REM ==========================================================
REM FIND CONNECTION SERVICE
REM ==========================================================

echo Checking for the Android device's wireless ADB
echo connection service...
echo.

timeout /t 2 /nobreak >nul

adb mdns services

echo.
echo ==========================================
echo              SETUP COMPLETE
echo ==========================================
echo.
echo The Android device is now paired with this PC.
echo.
echo You can close this window and run the
echo Android Wii U program.
echo.

pause
exit /b 0