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

echo
echo "Done. Reboot once, then: cp .env.example .env && nano .env && ./homeserver install all"
