# Shared helpers, sourced by ./homeserver and service scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUADLET_DIR=~/.config/containers/systemd

die() { echo "Error: $*" >&2; exit 1; }

# Load the shared .env (create it from .env.example on first run)
load_env() {
  if [ ! -f "$ROOT/.env" ]; then
    cp "$ROOT/.env.example" "$ROOT/.env"
    chmod 600 "$ROOT/.env"
    die "Created $ROOT/.env - edit it, then run again."
  fi
  set -a; source "$ROOT/.env"; set +a

  # Auto-detect the LAN IP if SERVER_IP is empty
  if [ -z "${SERVER_IP:-}" ]; then
    SERVER_IP="$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')"
  fi
  [ -n "$SERVER_IP" ] || die "Could not detect LAN IP. Set SERVER_IP in .env"
}

# require VAR...: stop if a setting is empty or still "change-me"
require() {
  local var
  for var in "$@"; do
    [ -n "${!var:-}" ] && [ "${!var}" != "change-me" ] || die "Set $var in .env first."
  done
}

# render TEMPLATE OUTPUT: replace every @VAR@ with the value of $VAR
render() {
  local line var
  while IFS= read -r line || [ -n "$line" ]; do
    while [[ $line =~ @([A-Z_][A-Z0-9_]*)@ ]]; do
      var="${BASH_REMATCH[1]}"
      line="${line//@$var@/${!var}}"
    done
    printf '%s\n' "$line"
  done < "$1" > "$2"
}

# wait_for URL TEXT: wait until the page at URL contains TEXT
wait_for() {
  echo "Waiting for $1 (first start can take a few minutes)"
  until curl -s "$1" | grep -q "$2"; do sleep 5; done
}
