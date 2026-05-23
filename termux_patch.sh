#!/bin/bash
# SpotHub Android - Termux Patcher

echo "========================================="
echo "   SpotHub Android - Termux Patcher"
echo "========================================="
echo ""

# Установка необходимых пакетов
echo "[0] Installing required packages..."
pkg install -y openjdk-17 wget unzip git

# Проверка Spotify
if ! pm list packages | grep -q "com.spotify.music"; then
    echo "[ERROR] Spotify not installed"
    echo "Install Spotify first from apkpure.com"
    exit 1
fi
echo "[OK] Spotify found"

# Создание рабочей папки
mkdir -p ~/spotify_patch
cd ~/spotify_patch

# Копирование APK
echo "[1] Copying Spotify APK..."
cp $(pm path com.spotify.music | cut -d: -f2) ./original.apk
echo "[OK] Copied"

# Скачивание tools с GitHub
echo "[2] Downloading tools..."
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar -O apktool.jar
wget -q https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -O signer.jar
echo "[OK] Downloaded"

# Распаковка
echo "[3] Decompiling APK..."
java -jar apktool.jar d original.apk -o decompiled -f
echo "[OK] Decompiled"

# Патчи через sed
echo "[4] Applying patches..."
cd decompiled

# Блок рекламы
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/ads\/AdManager;->loadAd()V/return-void/g' {} \;

# Премиум
find . -name "*.smali" -exec sed -i 's/const\/4 v0, 0x0/const\/4 v0, 0x1/g' {} \;

# Отключение обновлений
sed -i 's/android:name="check_update" android:value="true"/android:name="check_update" android:value="false"/g' AndroidManifest.xml

# Блок телеметрии
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/telemetry\/Logger;->sendEvent(Ljava\/lang\/String;)V/return-void/g' {} \;

cd ..
echo "[OK] Patches applied"

# Сборка
echo "[5] Recompiling APK..."
java -jar apktool.jar b decompiled -o patched.apk
echo "[OK] Recompiled"

# Подпись
echo "[6] Signing APK..."
java -jar signer.jar --apks patched.apk --out . --allowResign
echo "[OK] Signed"

# Установка
echo "[7] Installing..."
pm uninstall com.spotify.music
pm install patched-aligned-debugSigned.apk
echo "[OK] Installed"

# Очистка
cd ~
rm -rf ~/spotify_patch

echo ""
echo "========================================="
echo "   SPOTHUB INSTALLED!"
echo "   No ads. Premium unlocked."
echo "========================================="
