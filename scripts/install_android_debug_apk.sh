#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:-artifacts/memory-board-debug-apk/app-debug.apk}"

if [[ ! -f "${apk_path}" ]]; then
  echo "APK not found: ${apk_path}"
  echo "Run scripts/download_android_apk.sh first."
  exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "Android adb was not found in PATH."
  echo "Install Android Platform Tools or transfer ${apk_path} to the phone manually."
  exit 1
fi

adb devices
adb install -r "${apk_path}"

echo "Installed ${apk_path}"
