# Paperless-ngx. Used by ./homeserver (see the top of that file).
NAME="Paperless-ngx"
URL="http://$SERVER_IP:$PAPERLESS_WEB_PORT"
UNITS=(paperless-redis paperless-postgres paperless-tika paperless-gotenberg paperless-webserver)
DATA=(~/.local/share/paperless/{data,media,export,database,redis} "$PAPERLESS_CONSUME_DIR"
      ~/.config/paperless)

check() {
  require PAPERLESS_DB_PASSWORD PAPERLESS_CONSUME_DIR PAPERLESS_OCR_LANGUAGE
  [[ $PAPERLESS_CONSUME_DIR != *" "* ]] || die "PAPERLESS_CONSUME_DIR must not contain spaces."
}

prepare() {
  local key=~/.config/paperless/secret-key
  # Random key for logins, made once and kept
  [ -s "$key" ] || ( umask 077; head -c 48 /dev/urandom | base64 | tr -d '/+=\n' > "$key" )

  # Passwords, readable only by me
  ( umask 077
    printf 'POSTGRES_PASSWORD=%s\n' "$PAPERLESS_DB_PASSWORD" > ~/.config/paperless/db.env
    printf 'PAPERLESS_DBPASS=%s\nPAPERLESS_SECRET_KEY=%s\n' \
      "$PAPERLESS_DB_PASSWORD" "$(cat "$key")" > ~/.config/paperless/paperless.env )
}

ready() {
  wait_for "http://localhost:$PAPERLESS_WEB_PORT/accounts/login/" Paperless-ngx
  echo "Paperless-ngx is running: $URL"
}

# Paperless's own export: every document plus all tags, settings and users.
# Works across versions and is the official way to restore. Only copies new and
# changed files; never deletes anything at the destination.
backup() {
  podman exec paperless-webserver document_exporter /usr/src/paperless/export \
    --compare-checksums --delete --no-progress-bar
  rsync -rt --info=progress2 ~/.local/share/paperless/export/ "$1/"
}
