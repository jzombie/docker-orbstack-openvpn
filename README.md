# OrbStack OpenVPN (OpenVPN Access Server)

Using a Mac as a VPN server.

Literally _"works on my machine."_  No clue if it will work without modification on yours.

## Start / stop

```bash
# Start
./start.sh

# Stop
docker compose down

# View logs
docker compose logs -f
```

The container restarts automatically on reboot (Docker Desktop must be set to launch at login).

---

## Set the admin password (first time only)

```bash
docker exec -it openvpn-as \
  /usr/local/openvpn_as/scripts/sacli \
  --user openvpn --new_pass 'YourStrongPassword' SetLocalPassword
```

---

## Access the Admin UI

Port 8443 is exposed externally for TCP VPN tunneling, while port 943 (the Admin UI) only listens on `127.0.0.1` for security.

**If you are on this machine** — open directly in your browser:

```
https://localhost:943/admin
```

**If you are on a different machine** — forward the port over SSH first:

```bash
ssh -L 943:127.0.0.1:943 <user>@<this-machine-ip>
```

Then open `https://localhost:943/admin` in your browser. Keep that terminal open while you use the UI.

Log in with username `openvpn` and the password you set above. Accept the self-signed certificate warning.

---

## Connect a VPN client

1. In the Admin UI, go to **User Management → User Permissions** and create a user for yourself.
2. Open the User Portal at `https://localhost:943` (or via SSH tunnel if remote), log in as that user, and click **Download** to get your `.ovpn` profile.
3. Install [OpenVPN Connect](https://openvpn.net/client/) on the device you want to connect from.
4. Import the `.ovpn` file and connect.

The VPN uses **port 8443/TCP** (or **1194/UDP** optionally, but UDP requires custom routes to bypass macOS network dropping).

---

## Update

```bash
docker compose pull && ./start.sh
```
