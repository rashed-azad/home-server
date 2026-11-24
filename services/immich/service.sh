# Immich. Used by ./homeserver (see the top of that file).
NAME="Immich"
URL="http://$SERVER_IP:$IMMICH_PORT"
UNITS=(immich-redis immich-postgres immich-server)
DATA=("$IMMICH_PHOTOS_DIR" "$IMMICH_DB_DIR" ~/.config/immich)

check() { require IMMICH_DB_PASSWORD IMMICH_PHOTOS_DIR IMMICH_DB_DIR; }

prepare() {
  # Database password, readable only by me
  ( umask 077; printf 'DB_PASSWORD=%s\nPOSTGRES_PASSWORD=%s\n' \
      "$IMMICH_DB_PASSWORD" "$IMMICH_DB_PASSWORD" > ~/.config/immich/db.env )
}

ready() {
  wait_for "http://localhost:$IMMICH_PORT/api/server/ping" pong
  echo "Immich is running: $URL"
}

# Photos, videos and Immich's own daily database backups.
# Only copies new and changed files; never deletes anything at the destination.
backup() {
  rsync -rt --info=progress2 "$IMMICH_PHOTOS_DIR/" "$1/"
}
