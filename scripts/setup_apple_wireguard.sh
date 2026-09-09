#!/usr/bin/env bash
set -euo pipefail

# Run on macOS from the HQ_VPN root after `flutter pub get`.
# It fetches the open-source WireGuard Apple components required by the
# Network Extension setup instead of embedding third-party source in this ZIP.

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'This script must run on macOS.' >&2
  exit 1
fi
command -v flutter >/dev/null || { echo 'Flutter not found.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Git not found.' >&2; exit 1; }
command -v go >/dev/null || { echo 'Go not found. Install Go first.' >&2; exit 1; }

flutter pub get
mkdir -p third_party
if [[ ! -d third_party/wireguard-apple ]]; then
  git clone --depth 1 https://github.com/WireGuard/wireguard-apple.git third_party/wireguard-apple
fi

# The package repository contains a working example Network Extension target.
# Copy it into the app only if the target directory is still the placeholder.
PKG_ROOT=$(python3 - <<'PY'
import json
from pathlib import Path
cfg=json.loads(Path('.dart_tool/package_config.json').read_text())
for p in cfg['packages']:
    if p['name'] == 'wireguard_flutter_plus':
        print(Path(p['rootUri'].replace('file://','')).resolve())
        break
PY
)

if [[ -d "$PKG_ROOT/example/ios/WGExtension" ]]; then
  rm -rf ios/WGExtension
  cp -R "$PKG_ROOT/example/ios/WGExtension" ios/WGExtension
fi

cat <<MSG

Apple source is prepared. Now open ios/Runner.xcworkspace in Xcode and complete:
- Main app bundle id: com.hqvpn.app
- Extension bundle id: com.hqvpn.app.WGExtension
- App Group: group.com.hqvpn.app
- Network Extension / Packet Tunnel capability on both targets
- Apple Development Team and provisioning
- WireGuardKitGo / WireGuardGoBridge dependency and build target

Follow docs/APPLE_NETWORK_EXTENSION.md and the package's ios_setup_readme.md.
MSG
