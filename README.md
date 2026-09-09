# HQ VPN — Real WireGuard Client

A polished cross-platform Flutter VPN client with the HQ VPN UI and a real WireGuard
connection engine. The client uses `wireguard_flutter_plus` and secure storage for
WireGuard profiles.

## Platforms

- Android
- iOS
- Windows
- macOS

## Start

```bash
flutter pub get
flutter run
```

If the platform runner folders are incomplete in your checkout, run:

```bash
bash scripts/bootstrap_platforms.sh
```

On Windows PowerShell:

```powershell
.\scripts\bootstrap_platforms.ps1
```

## Real VPN setup

1. Deploy a WireGuard server using `server/ubuntu_wireguard_server.sh` or your own
   hardened WireGuard infrastructure.
2. Create a unique client keypair and peer on the server.
3. Put the matching client `.conf` into HQ VPN using the server profile dialog.
4. Select that server and press Connect.
5. The app will request the operating system VPN permission when needed.

No fake timer or fake traffic is used. Connection state and RX/TX counters come from
the native WireGuard engine.

## UI

The UI keeps the requested dark navy / blue mobile design and the desktop dashboard:
connection state, timer, server card, ping bars, traffic cards, server selector,
settings, recent connections and desktop statistics panels.

## Security

- Client WireGuard profiles are stored with `flutter_secure_storage`.
- Real server endpoints are required; placeholder endpoints are rejected.
- Never commit real private keys, provisioning profiles, or server secrets.
- Use one peer/key per device.
- Keep server OS, WireGuard and firewall packages patched.

## Production checklist

- [ ] Real servers in multiple regions
- [ ] Per-device key provisioning
- [ ] Server health/ping API
- [ ] Account/authentication service
- [ ] Subscription/billing if required
- [ ] DNS strategy and leak testing
- [ ] IPv6 strategy and leak testing
- [ ] Kill-switch policy per OS
- [ ] Crash/telemetry policy with privacy review
- [ ] Apple Network Extension signing
- [ ] Android release signing and Play policy review
- [ ] Windows code signing

See `docs/REAL_VPN.md` and `docs/APPLE_NETWORK_EXTENSION.md`.


### FlutLab build note
FlutLab's current Dart SDK is 3.8.1. This project pins `wireguard_flutter_plus` to 1.0.1 because 1.0.2 and newer require Dart 3.9+. Upgrade the FlutLab Flutter/Dart SDK before moving to a newer plugin version.
