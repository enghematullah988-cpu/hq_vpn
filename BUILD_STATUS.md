# HQ VPN V6 — FlutLab Android build fix

Fixed the Android release Gradle dependency resolution failure:
- Added Flutter's official engine Maven repository: https://storage.googleapis.com/download.flutter.io
- Keeps wireguard_flutter_plus pinned to 1.0.1 for FlutLab Dart 3.8.1 compatibility.
- Keeps the existing HQ VPN UI and WireGuard engine.

The previous failure was `Could not find io.flutter:armeabi_v7a_release` / `flutter_embedding_release` because the Flutter engine repository was missing from dependencyResolutionManagement while PREFER_SETTINGS was enabled.
