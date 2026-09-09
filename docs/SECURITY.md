# HQ VPN security baseline

1. Use WireGuard with unique keys per device.
2. Store client private keys only in platform secure storage.
3. Never put production keys in Git, assets, logs, screenshots or analytics.
4. Use HTTPS for any future control-plane API.
5. Authenticate device provisioning with short-lived enrollment tokens.
6. Rotate/revoke peers when a device is lost or compromised.
7. Restrict the VPN server firewall to the WireGuard UDP port plus required management
   access.
8. Disable password SSH where practical and use keys/MFA for administration.
9. Test IPv4, IPv6, DNS, reconnect, sleep/wake and network handoff on every release.
10. Do not claim “no logs” unless the complete infrastructure has been audited to match
    that claim.
