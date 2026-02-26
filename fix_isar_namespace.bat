@echo off
echo Fixing Isar namespace issue...

set ISAR_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle

if exist "%ISAR_PATH%" (
    echo Found Isar build.gradle at: %ISAR_PATH%
    
    REM Backup original file
    copy "%ISAR_PATH%" "%ISAR_PATH%.backup" >nul 2>&1
    
    REM Add namespace to the file
    (
        echo android {
        echo     namespace "dev.isar.isar_flutter_libs"
        echo.
        type "%ISAR_PATH%"
    ) > "%ISAR_PATH%.tmp"
    
    move /Y "%ISAR_PATH%.tmp" "%ISAR_PATH%" >nul
    
    echo ✅ Fixed! Namespace added to Isar build.gradle
    echo Now run: flutter run
) else (
    echo ❌ Isar build.gradle not found at expected location
    echo Please check the path manually
)

pause
