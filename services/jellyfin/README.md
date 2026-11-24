# Jellyfin

Media server with Intel hardware video conversion.

## Install
```bash
./homeserver install jellyfin    # needs JELLYFIN_MEDIA_DIR in .env
```
1. Open `http://<SERVER_IP>:8096`, finish the setup wizard, add libraries from `/media/...`.
2. Dashboard > API Keys > `+`. Put the key in `.env` as `JELLYFIN_API_KEY`.
3. Install again. This applies the best-quality settings.

Install again after adding a new library.

## Upgrade
1. `./homeserver backup jellyfin` (new versions can't go back).
2. Change `JELLYFIN_VERSION` in `.env`, run `./homeserver install jellyfin`.

Your media is mounted read-only and is never touched, not even by `--purge`.
