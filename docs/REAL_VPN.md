# HQ VPN — Real VPN mode

HQ VPN is now wired to the native WireGuard engine through `wireguard_flutter_plus`.
The Connect button does **not** fake a connection. It calls the WireGuard engine and
reads the native tunnel state/traffic counters.

## What you must provide

A VPN app cannot create internet service by itself. You need at least one reachable
WireGuard server and a unique client profile for each device/server pair.

A client profile looks like:

```ini
[Interface]
PrivateKey = <unique-client-private-key>
Address = 10.66.0.2/32
DNS = 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = <server-public-key>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = vpn.example.com:51820
PersistentKeepalive = 25
```

Never reuse one private key across users/devices.

## Server

`server/ubuntu_wireguard_server.sh` installs a WireGuard server on Ubuntu and enables
forwarding/NAT. After running it, add a peer for each device.

## Client

In HQ VPN, select a server and press Connect. If its profile is missing, the app opens
a profile editor. Paste the real `.conf` content and save it. The profile is stored in
platform secure storage; it is not written to the Flutter source tree.

## Important platform notes

- Android: the WireGuard Flutter package provides the native tunnel backend.
- Windows: run the app elevated when the platform requests it.
- iOS/macOS: Apple requires a Network Extension target, App Group, signing, and the
  provider bundle ID configured in Xcode. See `docs/APPLE_NETWORK_EXTENSION.md`.
- A real VPN requires a real server. `YOUR_SERVER_IP:51820` is intentionally rejected.
