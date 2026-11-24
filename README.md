# Home Server

Self-hosted services on **rootless Podman** (Quadlet + systemd user units).
Each service starts at boot and restarts if it crashes. Only the one-time host
setup needs sudo.

| Service | What | URL |
|---|---|---|
| [pihole](services/pihole) | Ad-blocking DNS + Unbound resolver | `http://<SERVER_IP>:8080/admin` |
| [youtrack](services/youtrack) | Issue tracker | `http://<SERVER_IP>:8081` |
| [jellyfin](services/jellyfin) | Media server | `http://<SERVER_IP>:8096` |
| [immich](services/immich) | Photo backup | `http://<SERVER_IP>:2283` |

## Quick start
```bash
./homeserver setup                    # once, needs sudo, then reboot
cp .env.example .env && nano .env     # one settings file for all services
./homeserver install all              # or: ./homeserver install pihole immich
```
Changed `.env` or want to update? Run `./homeserver install <service>` again.

## Commands
| Task | Command |
|---|---|
| Install / update | `./homeserver install <service\|all>` |
| Remove | `./homeserver uninstall <service>` (`--purge` also deletes its data) |
| Backup | `./homeserver backup all` (to `BACKUP_DIR`, or `--to /media/$USER/USB`) |
| Status | `./homeserver status all` |
| Logs | `./homeserver logs <service>` |
| Restart | `./homeserver restart <service\|all>` |
| List services | `./homeserver list` |

## Backups
`./homeserver backup all` saves each service to `BACKUP_DIR/<service>/`:

| Service | What is saved |
|---|---|
| pihole | `etc-pihole-<date>.tar.gz` (all settings) |
| youtrack | copy of YouTrack's own backups |
| jellyfin | `config-<date>.tar.gz` (settings, not media; stops Jellyfin for a moment) |
| immich | all photos, videos and Immich's daily database backups (only new files) |

## Layout
```
.
├── homeserver          the one command for everything
├── .env.example        settings for all services (copy to .env)
├── scripts/
│   ├── setup-host.sh   one-time host setup (sudo)
│   └── lib.sh          shared helpers
└── services/<name>/
    ├── service.sh      units, data folders, and service-specific steps
    ├── README.md       first-time steps for this service
    └── *.container(.in) Podman Quadlet units (.in = template filled from .env)
```
To add a service: create `services/<name>/` with a `service.sh` and its unit
files. See the comment at the top of [homeserver](homeserver).

## Where things live
- Generated units: `~/.config/containers/systemd/`
- Data: `~/.local/share/<service>/` (Immich: folders set in `.env`)
- Needs Podman 4.4+ (`podman --version`).
