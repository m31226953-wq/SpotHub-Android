@echo off
title SpotHub Android ADB Patcher
color 0A

echo ========================================
echo    SpotHub Android - ADB Patcher
echo ========================================
echo.

:: Check ADB connection
adb devices | findstr "device$" > nul
if errorlevel 1 (
    echo [ERROR] Phone not found. Enable USB debugging.
    pause
    exit /b
)

echo [OK] Phone connected
echo.

:: 1. Extract Spotify from phone
echo [1] Extracting Spotify from phone...
adb shell pm path com.spotify.music > temp.txt
set /p SPOTIFY_PATH=<temp.txt
set SPOTIFY_PATH=%SPOTIFY_PATH:package:=%
del temp.txt
set SPOTIFY_PATH=%SPOTIFY_PATH:\r=%
set SPOTIFY_PATH=%SPOTIFY_PATH: =%

adb pull %SPOTIFY_PATH% working\current.apk
echo [OK] APK extracted
echo.

:: 2. Decompile APK
echo [2] Decompiling APK...
java -jar tools\apktool.jar d working\current.apk -o working\decompiled -f
echo [OK] Decompiled
echo.

:: 3. Apply patches
echo [3] Applying patches...
cd working\decompiled

:: Block ads
echo    - Blocking ads...
patch -N -p1 < ..\..\patches\ads.patch 2>nul

:: Unlock premium
echo    - Unlocking premium...
patch -N -p1 < ..\..\patches\premium.patch 2>nul

:: Disable updates
echo    - Disabling updates...
patch -N -p1 < ..\..\patches\updates.patch 2>nul

:: Block telemetry
echo    - Blocking telemetry...
patch -N -p1 < ..\..\patches\telemetry.patch 2>nul

cd ..\..
echo [OK] Patches applied
echo.

:: 4. Recompile APK
echo [4] Recompiling APK...
java -jar tools\apktool.jar b working\decompiled -o working\patched.apk
echo [OK] Recompiled
echo.

:: 5. Sign APK
echo [5] Signing APK...
java -jar tools\uber-apk-signer.jar --apks working\patched.apk --out working\ --allowResign
del working\patched.apk
ren working\*-aligned-debugSigned.apk patched-signed.apk
echo [OK] Signed
echo.

:: 6. Install on phone
echo [6] Installing patched Spotify...
adb uninstall com.spotify.music
adb install working\patched-signed.apk
echo [OK] Installed
echo.

echo ========================================
echo    SPOTHUB INSTALLED ON PHONE!
echo    No ads. Premium unlocked.
echo ========================================
pause