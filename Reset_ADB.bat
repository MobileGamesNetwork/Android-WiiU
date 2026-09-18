@echo off
title Reset ADB

echo.
echo ==========================================
echo              RESETTING ADB
echo ==========================================
echo.

adb kill-server

echo.
echo ADB server stopped.
echo.
pause