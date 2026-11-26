# Caddy reverse proxy. Used by ./homeserver (see the top of that file).
NAME="Caddy"
URL="http://pihole.$HOME_DOMAIN"
UNITS=(caddy)
DATA=(~/.config/caddy ~/.local/share/caddy)

check() { require HOME_DOMAIN; }

prepare() { render "$SVC_DIR/Caddyfile.in" ~/.config/caddy/Caddyfile; }

ready() {
  sleep 3
  curl -s -o /dev/null -H "Host: pihole.$HOME_DOMAIN" "http://$SERVER_IP/" ||
    die "Caddy is not answering. Check: ./homeserver logs caddy"
  echo "Caddy is running. Addresses:"
  grep -o "^http://[^ ]*" ~/.config/caddy/Caddyfile | sed 's/^/  /'
}

# Nothing to back up: the config comes from this repo
