#!/usr/bin/env bash
set -e

echo "=== 1. Checking Flutter SDK on Cloudflare Pages ==="
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found. Installing portable Flutter stable..."
  if [ ! -d "$HOME/flutter" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
fi

echo "=== 2. Flutter Version ==="
flutter --version

echo "=== 3. Building Flutter Web Release ==="
flutter build web --release --base-href "/"

echo "=== 4. Copying SQLite Web Worker Binaries & Cloudflare Config ==="
cp -f web/sqflite_sw.js build/web/
cp -f web/sqlite3.wasm build/web/
cp -f web/_headers build/web/
cp -f web/_redirects build/web/

echo "=== 5. Verification of build/web ==="
ls -la build/web/
echo "=== Cloudflare Build Ready ==="
