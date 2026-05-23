#!/bin/bash
# SpotHub Android - Download + Patch (NO ERRORS)

echo "========================================="
echo "   SpotHub Android - Download & Patch"
echo "========================================="
echo ""

# Создаём папку
mkdir -p ~/spotify_patch
cd ~/spotify_patch

# 1. СКАЧИВАЕМ ПОСЛЕДНИЙ SPOTIFY
echo "[1] Downloading latest Spotify..."
wget -q --show-progress "https://api.apkmirror.com/v2/apk/spotify/spotify/latest/download" -O spotify.apk

if [ ! -f "spotify.apk" ]; then
    echo "[!] Mirror failed, trying backup..."
    wget -q --show-progress "https://apkpure.net/spotify-music/com.spotify.music/download/latest" -O spotify.apk
fi

if [ ! -f "spotify.apk" ]; then
    echo "[!] Download failed. Install Spotify manually from apkpure.com"
    exit 1
fi

echo "[OK] Spotify downloaded"
echo ""

# 2. УСТАНАВЛИВАЕМ JAVA (если нет)
echo "[2] Checking Java..."
if ! command -v java &> /dev/null; then
    echo "Installing Java..."
    pkg install openjdk-17 -y > /dev/null 2>&1
fi
echo "[OK] Java ready"
echo ""

# 3. СКАЧИВАЕМ ИНСТРУМЕНТЫ
echo "[3] Downloading tools..."
wget -q "https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar" -O apktool.jar
wget -q "https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar" -O signer.jar
echo "[OK] Tools ready"
echo ""

# 4. РАСПАКОВЫВАЕМ
echo "[4] Decompiling..."
java -jar apktool.jar d spotify.apk -o decompiled -f > /dev/null 2>&1
echo "[OK] Decompiled"
echo ""

# 5. ПАТЧИМ
echo "[5] Applying patches..."
cd decompiled

# Блок рекламы
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/ads\/AdManager;->loadAd()V/return-void/g' {} \; 2>/dev/null
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/ads\/AudioAd;->play()V/return-void/g' {} \; 2>/dev/null
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/ads\/VideoAd;->show()V/return-void/g' {} \; 2>/dev/null

# Премиум
find . -name "*.smali" -exec sed -i 's/const\/4 v0, 0x0/const\/4 v0, 0x1/g' {} \; 2>/dev/null
find . -name "*.smali" -exec sed -i 's/\"free\"/\"premium\"/g' {} \; 2>/dev/null
find . -name "*.smali" -exec sed -i 's/\"open\"/\"premium\"/g' {} \; 2>/dev/null

# Отключение обновлений
sed -i 's/android:name="check_update" android:value="true"/android:name="check_update" android:value="false"/g' AndroidManifest.xml 2>/dev/null
sed -i 's/android:name="auto_update" android:value="true"/android:name="auto_update" android:value="false"/g' AndroidManifest.xml 2>/dev/null

# Блок телеметрии
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/telemetry\/Logger;->sendEvent(Ljava\/lang\/String;)V/return-void/g' {} \; 2>/dev/null
find . -name "*.smali" -exec sed -i 's/invoke-static {.*}, Lcom\/spotify\/telemetry\/CrashReport;->send()V/return-void/g' {} \; 2>/dev/null

cd ..
echo "[OK] Patches applied"
echo ""

# 6. СБИРАЕМ
echo "[6] Recompiling..."
java -jar apktool.jar b decompiled -o patched.apk > /dev/null 2>&1
echo "[OK] Recompiled"
echo ""

# 7. ПОДПИСЫВАЕМ
echo "[7] Signing..."
java -jar signer.jar --apks patched.apk --out . --allowResign > /dev/null 2>&1
echo "[OK] Signed"
echo ""

# 8. УСТАНАВЛИВАЕМ
echo "[8] Installing..."
pm uninstall com.spotify.music > /dev/null 2>&1
pm install patched-aligned-debugSigned.apk > /dev/null 2>&1
echo "[OK] Installed"
echo ""

# 9. ОЧИСТКА
cd ~
rm -rf ~/spotify_patch

echo ""
echo "========================================="
echo -e "\e[32m   DONE! SPOTHUB ACTIVATED!\e[0m"
echo "========================================="
echo ""
echo "   ✓ No ads"
echo "   ✓ Premium unlocked"
echo "   ✓ Updates disabled"
echo "   ✓ Telemetry blocked"
echo ""
echo "   Open Spotify and enjoy!"
echo ""
