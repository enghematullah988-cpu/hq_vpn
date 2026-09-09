# iOS/macOS Network Extension setup

Apple does not allow an ordinary Flutter app to silently create a packet tunnel. The
app must contain a signed Packet Tunnel Provider target and the required entitlements.

## iOS

1. Open the generated `ios/Runner.xcworkspace` in Xcode on a Mac.
2. Add a **Network Extension → Packet Tunnel Provider** target named `WGExtension`.
3. Use bundle ID `com.hqvpn.app.WGExtension` for the extension.
4. Enable the Network Extensions capability for the extension.
5. Enable the same App Group on the main app and extension: `group.com.hqvpn.app`.
6. Add the WireGuardKit/Go bridge required by `wireguard_flutter_plus` according to its
   package setup guide.
7. Use the included `ios/WGExtension/PacketTunnelProvider.swift` as the provider source
   starting point, then let the package's native integration own the WireGuard engine.
8. Set a real Apple Development Team and provisioning profiles.
9. Test on a physical iPhone; VPN Network Extensions are not equivalent to a simulator.

## macOS

Use the same architecture with a Packet Tunnel Provider/System Extension as required by
your macOS deployment target. Configure the App Group and signing in Xcode.

The Dart engine already uses:

- App Group: `group.com.hqvpn.app`
- Extension bundle ID: `com.hqvpn.app.WGExtension`

## Why this cannot be completely signed inside the ZIP

Apple signing identities, Team IDs, provisioning profiles, entitlements and App Store
certificates belong to the developer account and cannot be safely embedded in a shared
source archive. Those values must be added on the Mac that owns the Apple Developer
account.
