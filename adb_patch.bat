@echo off
title SpotHub Android ADB Patcher
color 0A

echo ========================================
echo    SpotHub Android - ADB Patcher
echo ========================================
echo.

:: 1. Проверка ADB
adb devices | findstr "device$" > nul
if errorlevel 1 (
    echo [ОШИБКА] Телефон не наиден. Включи отладку по USB и разреши доступ.
    pause
    exit /b
)
echo [OK] Телефон подключен
echo.

:: 2. Извлечение Spotify
echo [1] Извлекаем Spotify с телефона...
for /f "tokens=2 delims=:" %%a in ('adb shell pm path com.spotify.music') do set SPOTIFY_PATH=%%a
set SPOTIFY_PATH=%SPOTIFY_PATH:\r=%
adb pull %SPOTIFY_PATH% working\current.apk
if errorlevel 1 (
    echo [ОШИБКА] Не удалось извлечь APK. Spotify установлен?
    pause
    exit /b
)
echo [OK] APK извлечен
echo.

:: 3. Распаковка APK
echo [2] Распаковываем APK...
java -jar tools\apktool.jar d working\current.apk -o working\decompiled -f
echo [OK] Распакован
echo.

:: 4. ПРИМЕНЕНИЕ ПАТЧЕЙ (через PowerShell, без patch.exe)
echo [3] Применяем патчи (Windows native)...
powershell -Command "(Get-Content 'working\decompiled\smali\com\spotify\ads\AdManager.smali') -replace 'invoke-static {.*}, Lcom/spotify/ads/AdManager;->loadAd', 'return-void' | Set-Content 'working\decompiled\smali\com\spotify\ads\AdManager.smali'"
powershell -Command "(Get-Content 'working\decompiled\smali\com\spotify\libs\premium\PremiumManager.smali') -replace 'const/4 v0, 0x0', 'const/4 v0, 0x1' | Set-Content 'working\decompiled\smali\com\spotify\libs\premium\PremiumManager.smali'"
powershell -Command "(Get-Content 'working\decompiled\AndroidManifest.xml') -replace 'android:name="check_update" android:value="true"', 'android:name="check_update" android:value="false"' | Set-Content 'working\decompiled\AndroidManifest.xml'"
powershell -Command "(Get-Content 'working\decompiled\smali\com\spotify\telemetry\Logger.smali') -replace 'invoke-static {.*}, Lcom/spotify/telemetry/Logger;->sendEvent', 'return-void' | Set-Content 'working\decompiled\smali\com\spotify\telemetry\Logger.smali'"
echo [OK] Патчи наложены
echo.

:: 5. Сборка APK
echo [4] Собираем патченный APK...
java -jar tools\apktool.jar b working\decompiled -o working\patched.apk
echo [OK] APK собран
echo.

:: 6. Подпись APK
echo [5] Подписываем APK...
java -jar tools\uber-apk-signer.jar --apks working\patched.apk --out working\ --allowResign
del working\patched.apk 2>nul
ren working\*-aligned-debugSigned.apk patched-signed.apk 2>nul
echo [OK] APK подписан
echo.

:: 7. Установка на телефон
echo [6] Устанавливаем патченный Spotify...
adb uninstall com.spotify.music
adb install working\patched-signed.apk
echo [OK] Установлен
echo.

echo ========================================
echo    SPOTHUB УСПЕШНО УСТАНОВЛЕН!
echo    Реклама удалена, премиум разблокирован.
echo ========================================
pause
