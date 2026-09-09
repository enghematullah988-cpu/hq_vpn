#!/usr/bin/env bash
set -euo pipefail

# HQ VPN — Ubuntu WireGuard server bootstrap.
# Run as root on a fresh Ubuntu 22.04/24.04 VPS.
# This script installs WireGuard, enables IPv4/IPv6 forwarding, creates wg0,
# and prints the server public key. Client peers are intentionally added only
# after you assign each user a unique address/key pair.

WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_NET="${WG_NET:-10.66.0.0/24}"
SERVER_ADDR="${SERVER_ADDR:-10.66.0.1/24}"
WAN_IF="${WAN_IF:-$(ip route show default | awk '/default/ {print $5; exit}') }"
WAN_IF="$(echo "$WAN_IF" | xargs)"

if [[ $EUID -ne 0 ]]; then echo 'Run as root.' >&2; exit 1; fi
if [[ -z "$WAN_IF" ]]; then echo 'Could not detect WAN interface. Set WAN_IF=eth0.' >&2; exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard iptables qrencode resolvconf

install -d -m 700 /etc/wireguard
umask 077
if [[ ! -f /etc/wireguard/server_private.key ]]; then
  wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
fi

SERVER_PRIVATE=$(cat /etc/wireguard/server_private.key)
SERVER_PUBLIC=$(cat /etc/wireguard/server_public.key)

cat > /etc/sysctl.d/99-hqvpn.conf <<SYSCTL
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.src_valid_mark=1
SYSCTL
sysctl --system >/dev/null

cat > /etc/wireguard/${WG_IF}.conf <<WGCONF
[Interface]
Address = ${SERVER_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE}
SaveConfig = true
PostUp = iptables -A FORWARD -i ${WG_IF} -j ACCEPT; iptables -A FORWARD -o ${WG_IF} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WAN_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_IF} -j ACCEPT; iptables -D FORWARD -o ${WG_IF} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WAN_IF} -j MASQUERADE
WGCONF

systemctl enable --now wg-quick@${WG_IF}
ufw allow ${WG_PORT}/udp 2>/dev/null || true

echo
printf 'HQ VPN WireGuard server is ready.\n'
printf 'Interface: %s\nPort: %s\nWAN: %s\nServer public key: %s\n' "$WG_IF" "$WG_PORT" "$WAN_IF" "$SERVER_PUBLIC"
printf '\nNext: create one unique peer per device and add it with `wg set` or to /etc/wireguard/%s.conf.\n' "$WG_IF"
