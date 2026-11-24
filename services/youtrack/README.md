# YouTrack

Issue tracker by JetBrains.

## Install
```bash
./homeserver install youtrack
```
Open `http://<SERVER_IP>:8081` and finish the Configuration Wizard.

## Upgrade
Change `YOUTRACK_VERSION` in `.env`, run `./homeserver install youtrack`.

## Backup and restore
- YouTrack saves its own backups to `~/.local/share/youtrack/backups/`.
  `./homeserver backup youtrack` copies them to `BACKUP_DIR/youtrack/`.
- Restore: copy the backup file into `~/.local/share/youtrack/backups/`, install,
  and pick it in the Configuration Wizard. Use the same or a newer YouTrack version.
