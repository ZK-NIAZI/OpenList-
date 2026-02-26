@echo off
REM =====================================================
REM CLEAR APP DATA ON ANDROID DEVICE
REM =====================================================
REM This script clears all local Isar data from your Android device
REM Run this from your project root directory
REM =====================================================

echo.
echo ========================================
echo  CLEARING OPENLIST APP DATA
echo ========================================
echo.

REM Get the device ID
echo Checking connected devices...
adb devices
echo.

REM Clear app data (this will clear Isar database)
echo Clearing app data...
adb shell pm clear com.example.openlist
echo.

echo ✅ App data cleared!
echo.
echo NEXT STEPS:
echo 1. Run the clear_all_test_data.sql in Supabase SQL Editor
echo 2. Restart your app
echo 3. Log in again
echo 4. You'll have a fresh start for testing!
echo.
pause
