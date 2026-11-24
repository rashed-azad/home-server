# YouTrack. Used by ./homeserver (see the top of that file).
NAME="YouTrack"
URL="http://$SERVER_IP:$YOUTRACK_PORT"
UNITS=(youtrack)
DATA=(~/.local/share/youtrack/{data,conf,logs,backups})

# YouTrack makes its own backups (Administration > Database Backup);
# this copies them off the server.
backup() {
  rsync -rt --info=progress2 ~/.local/share/youtrack/backups/ "$1/"
}
