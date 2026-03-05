#!/usr/bin/env bash
# UFW firewall lockdown for OpenVPN Access Server
#
# USAGE:
#   1. Replace YOUR_ADMIN_IP below with your actual public IP address.
#      You can find it by running: curl -s https://ifconfig.me
#   2. Run as root: sudo bash firewall-setup.sh
#
# Ports:
#   22   - SSH          (admin IP only — do not remove or you'll be locked out)
#   943  - Admin Web UI (admin IP only)
#   443  - Client Web UI / TCP VPN (admin IP only)
#   1194 - UDP VPN Tunnel (open to all — required for VPN clients to connect)

set -euo pipefail

# ---------------------------------------------------------------
# CONFIGURATION — change this to your actual public IP address
# ---------------------------------------------------------------
ADMIN_IP="YOUR_ADMIN_IP"
# ---------------------------------------------------------------

if [[ "$ADMIN_IP" == "YOUR_ADMIN_IP" ]]; then
  echo "ERROR: Edit this script and set ADMIN_IP to your public IP first."
  echo "       Run: curl -s https://ifconfig.me"
  exit 1
fi

echo "[*] Resetting UFW to defaults..."
ufw --force reset

echo "[*] Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

echo "[*] Allowing SSH from $ADMIN_IP only..."
ufw allow from "$ADMIN_IP" to any port 22 proto tcp comment "SSH - admin only"

echo "[*] Allowing OpenVPN Admin UI (943) from $ADMIN_IP only..."
ufw allow from "$ADMIN_IP" to any port 943 proto tcp comment "OpenVPN Admin UI - admin only"

echo "[*] Allowing OpenVPN Client UI / TCP VPN (443) from $ADMIN_IP only..."
ufw allow from "$ADMIN_IP" to any port 443 proto tcp comment "OpenVPN Client UI + TCP tunnel - admin only"

echo "[*] Allowing OpenVPN UDP tunnel (1194) from anywhere..."
ufw allow 1194/udp comment "OpenVPN UDP tunnel - all clients"

echo "[*] Enabling UFW..."
ufw --force enable

echo ""
echo "[+] Firewall rules applied:"
ufw status verbose
