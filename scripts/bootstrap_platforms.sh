#!/usr/bin/env bash
set -euo pipefail

# The Flutter CLI owns the generated platform boilerplate. This script creates
# any missing Android/iOS/macOS/Windows runners without replacing lib/ or docs.
# Run from the HQ_VPN project root after installing Flutter.

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter was not found in PATH.' >&2
  exit 1
fi

mkdir -p .hqvpn_backup
cp -f pubspec.yaml .hqvpn_backup/pubspec.yaml
cp -rf lib .hqvpn_backup/lib
cp -rf assets .hqvpn_backup/assets

flutter create --platforms=android,ios,macos,windows .

rm -rf lib assets
cp -rf .hqvpn_backup/lib lib
cp -rf .hqvpn_backup/assets assets
cp .hqvpn_backup/pubspec.yaml pubspec.yaml

flutter pub get

echo 'Platform runners generated. Now follow docs/APPLE_NETWORK_EXTENSION.md for iOS/macOS.'
