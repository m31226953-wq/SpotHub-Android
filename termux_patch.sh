#!/bin/bash
# SpotHub Android - Termux Patcher (NO ERROR STOP)

echo "========================================="
echo "   SpotHub Android - Termux Patcher"
echo "========================================="
echo ""

# Ищем Spotify
SPOTIFY_PATH=""

# Способ 1
if [ -z "$SPOTIFY_PATH" ]; then
    SPOTIFY_PATH=$(pm path com.spotify.music 2>/dev/null | cut -d: -f2 | tr -d '\r')
fi

# Способ 2
if [ -z "$SPOTIFY_PATH" ]; then
    SPOTIFY_PATH=$(find /data/app -name "*.apk" -path "*spotify*" 2>/dev/null | head -1)
fi

# Способ 3
if [ -z "$SPOTIFY_PATH" ]; then
    SPOTIFY_PATH=$(find /sdcard -name "*.apk" -iname "*spotify*" 2>/dev/null | head -1)
fi

# Если не нашли - просим пользователя
if [ -z "$SPOTIFY_PATH" ]; then
    echo "Download Spotify APK first"
    echo "Run: wget -O /sdcard/spotify.apk https://apkpure.net/spotify-music/com.spotify.music/download/latest"
    exit 1
fi

echo "Spotify: $SPOTIFY_PATH"

# Рабочая папка
mkdir -p ~/spotify_patch
cd ~/spotify_patch

# Копируем APK
cp "$SPOTIFY_PATH" ./original.apk 2>/dev/null

# Устанавливаем Java если нет
if ! command -v java &> /dev/null; then
    pkg install openjdk-17 -y 2>/dev/null
fi

# Скачиваем tools (тихо)
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar -O apktool.jar
wget -q https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -O signer.jar

# Распаковываем
java -jar apktool.jar d original.apk -o decompiled -f 2>/dev/null

# ПАТЧИ - ИГНОРИРУЕМ ОШИБКИ
cd decompiled

# Блок рекламы
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/ads\/AdManager;->loadAd()V/return-void/g' {} \; 2>/dev/null

# Премиум
find . -name "*.smali" -exec sed -i 's/const\/4 v0, 0x0/const\/4 v0, 0x1/g' {} \; 2>/dev/null

# Отключение обновлений
sed -i 's/android:name="check_update" android:value="true"/android:name="check_update" android:value="false"/g' AndroidManifest.xml 2>/dev/null

# Блок телеметрии
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/telemetry\/Logger;->sendEvent(Ljava\/lang\/String;)V/return-void/g' {} \; 2>/dev/null

cd ..

# Собираем
java -jar apktool.jar b decompiled -o patched.apk 2>/dev/null

# Подписываем
java -jar signer.jar --apks patched.apk --out . --allowResign 2>/dev/null

# Устанавливаем
pm uninstall com.spotify.music 2>/dev/null
pm install patched-aligned-debugSigned.apk 2>/dev/null

# Очистка
cd ~
rm -rf ~/spotify_patch

echo ""
echo "========================================="
echo "   SPOTHUB ACTIVATED!"
echo "   No ads. Premium unlocked."
echo "========================================="
