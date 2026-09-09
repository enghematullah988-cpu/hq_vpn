# HQ VPN architecture

```text
Flutter UI
   |
   v
HQVpnController
   |
   v
HqVpnEngine
   |
   v
wireguard_flutter_plus
   |
   +--> Android WireGuard backend / VpnService
   +--> Windows WireGuard backend
   +--> iOS Network Extension
   +--> macOS Network Extension/System Extension
   |
   v
WireGuard server(s) on VPS / bare metal
```

The app does not proxy traffic through a custom Node server. WireGuard carries the user
traffic directly to the selected VPN endpoint. A future control plane can issue profiles,
server health and account data without ever storing reusable client private keys.
