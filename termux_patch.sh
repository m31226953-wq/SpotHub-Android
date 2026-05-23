#!/bin/bash
# SpotHub Android - Termux Patcher (Fixed)

echo "========================================="
echo "   SpotHub Android - Termux Patcher"
echo "========================================="
echo ""

# Method 1: Try pm path
SPOTIFY_PATH=$(pm path com.spotify.music 2>/dev/null | cut -d: -f2)

# Method 2: Try find (if rooted)
if [ -z "$SPOTIFY_PATH" ]; then
    echo "[!] pm path failed, trying find..."
    SPOTIFY_PATH=$(find /data/app -name "*spotify*" -type d 2>/dev/null | head -1)
    if [ -n "$SPOTIFY_PATH" ]; then
        SPOTIFY_PATH="$SPOTIFY_PATH/base.apk"
    fi
fi

# Method 3: Ask user
if [ -z "$SPOTIFY_PATH" ]; then
    echo "[!] Cannot find Spotify automatically"
    echo "Install Spotify first or provide APK path:"
    read -p "APK path: " SPOTIFY_PATH
fi

if [ ! -f "$SPOTIFY_PATH" ]; then
    echo "[ERROR] Spotify APK not found"
    exit 1
fi

echo "[OK] Spotify found at: $SPOTIFY_PATH"

# Rest of the script...
