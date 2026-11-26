#!/usr/bin/env bash
# One-time host setup for all services. The ONLY script that needs sudo.
# Safe to run again. Reboot once afterwards.
set -euo pipefail

echo "1. Install tools"
sudo apt update
sudo apt install -y podman crun aardvark-dns netavark jq curl rsync bind9-dnsutils

echo "2. Start my services at boot, even when I'm not logged in"
sudo loginctl enable-linger "$USER"

echo "3. Jellyfin: allow me to use the Intel graphics chip"
sudo usermod -aG render,video "$USER"

echo "4. Jellyfin: allow RAM and CPU limits for my containers"
sudo mkdir -p /etc/systemd/system/user@.service.d
printf '[Service]\nDelegate=cpu cpuset io memory pids\n' |
  sudo tee /etc/systemd/system/user@.service.d/delegate.conf >/dev/null

echo "5. Jellyfin: use crun (needed for graphics chip access)"
mkdir -p ~/.config/containers
printf '[engine]\nruntime = "crun"\n' > ~/.config/containers/containers.conf

echo "6. Pi-hole: allow normal users to open port 53, disable IPv6 on this host"
#    Remove /etc/sysctl.d/99-pihole.conf and run 'sudo sysctl --system' to undo.
sudo tee /etc/sysctl.d/99-pihole.conf >/dev/null <<'EOF'
net.ipv4.ip_unprivileged_port_start=53
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
sudo sysctl --system >/dev/null

echo "7. Tailscale: reach the home network from anywhere (subnet router)"
#    Remove /etc/sysctl.d/99-tailscale.conf and run 'sudo apt remove tailscale' to undo.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$ROOT/.env" ] && { set -a; source "$ROOT/.env"; set +a; }
if [ -z "${LAN_SUBNET:-}" ]; then   # e.g. 192.168.1.0/24, from the main network card
  iface="$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')"
  LAN_SUBNET="$(ip -4 route show dev "$iface" proto kernel scope link | awk '{print $1; exit}')"
fi
[ -n "$LAN_SUBNET" ] || { echo "Could not detect LAN subnet. Set LAN_SUBNET in .env" >&2; exit 1; }
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
# Forward packets between Tailscale and the LAN
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null
sudo sysctl --system >/dev/null
# tag:server: tagged devices never expire (needs scripts/tailscale-policy.hujson
#   in your Tailscale policy first). --accept-dns=false: the server keeps its own
#   DNS (it IS the DNS server).
ts_json() { tailscale status --json 2>/dev/null | jq -r "$1"; }
if [ "$(ts_json .BackendState)" = "Running" ] &&
   [ "$(ts_json '.Self.Tags // [] | index("tag:server") != null')" = "true" ]; then
  sudo tailscale set --advertise-routes="$LAN_SUBNET" --accept-dns=false
else
  echo "   Add the blocks from scripts/tailscale-policy.hujson to your policy file:"
  echo "   https://login.tailscale.com/admin/acls/file"
  read -r -p "   Press Enter when done. "
  echo "   If a link appears, open it to log this server in:"
  sudo tailscale up --advertise-tags=tag:server --advertise-routes="$LAN_SUBNET" \
    --accept-dns=false --force-reauth
fi
if [ "$(ts_json '.Self.KeyExpiry // empty')" ]; then
  echo "   Warning: this server's login still expires. Check README.md > Remote access." >&2
else
  echo "   Tailscale login never expires (tag:server)."
fi
echo "   Sharing $LAN_SUBNET over Tailscale. Finish the DNS step in README.md > Remote access."

echo
echo "Done. Reboot once, then: cp .env.example .env && nano .env && ./homeserver install all"
