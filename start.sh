#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Enable IP forwarding so macOS will route VPN client traffic to the internet.
sudo sysctl -w net.inet.ip.forwarding=1 >/dev/null

# Ensure OrbStack (Docker) is allowed through the macOS Application Firewall
# so inbound UDP 1194 can reach the VPN container.
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/OrbStack.app/Contents/MacOS/OrbStack 2>/dev/null || true
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /Applications/OrbStack.app/Contents/MacOS/OrbStack 2>/dev/null || true

docker compose up -d

# OpenVPN AS requires specific configurations to bypass Mac/OrbStack UDP NAT dropping bugs
echo "[*] Waiting for container to be ready..."
sleep 5

# OpenVPN AS does not add the NAT masquerade rule automatically in this container
# environment. Without it VPN clients can connect but cannot reach the internet.
docker exec openvpn-as iptables -t nat -C POSTROUTING -s 172.27.224.0/20 -o eth0 -j MASQUERADE 2>/dev/null || \
  docker exec openvpn-as iptables -t nat -A POSTROUTING -s 172.27.224.0/20 -o eth0 -j MASQUERADE

# Disable kernel DCO optimization bypasses so the software proxy handles OrbStack interfaces cleanly
docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli -k vpn.server.dco -v false ConfigPut

# Force OpenVPN AS to push a route dropping DNS queries from the VPN tunnel to bypass the Mac UDP corruption
docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli -k vpn.client.config_text -v "route 8.8.8.8 255.255.255.255 net_gateway
route 8.8.4.4 255.255.255.255 net_gateway" ConfigPut

# Tell OpenVPN AS that the public TCP port is 8443
docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli -k vpn.daemon.tcp.port -v 8443 ConfigPut 2>/dev/null || true
docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli -k vpn.server.daemon.tcp.port -v 8443 ConfigPut 2>/dev/null || true
docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli -k vpn.server.port_share.port -v 8443 ConfigPut 2>/dev/null || true

docker exec openvpn-as /usr/local/openvpn_as/scripts/sacli start >/dev/null 2>&1


echo "[+] Bugfixes and NAT rule applied."

echo "[+] OpenVPN AS is running. Open https://localhost:943/admin"
