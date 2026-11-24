# Pi-hole + Unbound. Used by ./homeserver (see the top of that file).
NAME="Pi-hole"
URL="http://$SERVER_IP:$PIHOLE_WEB_PORT/admin"
UNITS=(unbound pihole)
DATA=(~/.local/share/pihole/etc-pihole ~/.config/pihole)

check() { require PIHOLE_PASSWORD; }

prepare() {
  ( umask 077; echo "FTLCONF_webserver_api_password=$PIHOLE_PASSWORD" > ~/.config/pihole/pihole.env )
  # --pull gets the newest Alpine with security fixes
  podman build --pull -t localhost/pihole-unbound:latest "$SVC_DIR/unbound"
}

ready() {
  echo "Waiting for Pi-hole to start..."
  sleep 15
  dig +short +time=3 @"$SERVER_IP" google.com | grep -q . ||
    die "DNS test failed. Check: ./homeserver logs pihole"
  echo "Pi-hole is running: $URL   DNS: $SERVER_IP"
}

backup() {
  podman unshare tar -czf "$1/etc-pihole-$(date +%F).tar.gz" -C ~/.local/share/pihole etc-pihole
  echo "Saved $1/etc-pihole-$(date +%F).tar.gz"
}
