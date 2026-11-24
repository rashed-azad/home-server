# Immich

Photo and video backup (low RAM: no machine learning container).

## Install
```bash
./homeserver install immich      # needs IMMICH_DB_PASSWORD and folders in .env
```
1. Open `http://<SERVER_IP>:2283` and create the admin account.
2. Administration > Settings:
   - **Machine Learning: off** (there is no ML container)
   - **Storage Template: on** (files saved as `2026/11/IMG_1234.HEIC`)
   - **Job settings: concurrency 1**
3. Phone: install the Immich app, server `http://<SERVER_IP>:2283`, pick albums to back up.

## Folders
```
IMMICH_PHOTOS_DIR/       <- this is what gets backed up
  library/               original photos and videos
  upload/                new uploads
  backups/               Immich's daily database backups
  thumbs/, encoded-video/  rebuilt by Immich if lost
IMMICH_DB_DIR/           live database: never copy while running
```
Don't move or delete files in `IMMICH_PHOTOS_DIR` by hand. Delete in the app.

## Backup to USB
```bash
./homeserver backup immich --to /media/$USER/<usb-name>   # only copies new files
```

## Upgrade
1. Back up to USB.
2. Read the release notes for breaking changes.
3. Change `IMMICH_VERSION` in `.env`, run `./homeserver install immich`.

`./homeserver uninstall immich --purge` DELETES all photos and the database (asks first).
