$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter was not found in PATH.' }
New-Item -ItemType Directory -Force .hqvpn_backup | Out-Null
Copy-Item pubspec.yaml .hqvpn_backup/pubspec.yaml -Force
Copy-Item lib .hqvpn_backup/lib -Recurse -Force
Copy-Item assets .hqvpn_backup/assets -Recurse -Force
flutter create --platforms=android,ios,macos,windows .
Remove-Item lib, assets -Recurse -Force
Copy-Item .hqvpn_backup/lib lib -Recurse -Force
Copy-Item .hqvpn_backup/assets assets -Recurse -Force
Copy-Item .hqvpn_backup/pubspec.yaml pubspec.yaml -Force
flutter pub get
Write-Host 'Platform runners generated. Follow docs/APPLE_NETWORK_EXTENSION.md for iOS/macOS.'
