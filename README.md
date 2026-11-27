# Home Server

Self-hosted services on **rootless Podman** (Quadlet + systemd user units).
Each service starts at boot and restarts if it crashes. Only the one-time host
setup needs sudo.

| Service | What | URL | Also |
|---|---|---|---|
| [pihole](services/pihole) | Ad-blocking DNS + Unbound resolver | http://pihole.home | `<SERVER_IP>:8080/admin` |
| [youtrack](services/youtrack) | Issue tracker | http://youtrack.home | `<SERVER_IP>:8081` |
| [jellyfin](services/jellyfin) | Media server | http://jellyfin.home | `<SERVER_IP>:8096` |
| [immich](services/immich) | Photo backup | http://immich.home | `<SERVER_IP>:2283` |
| [paperless](services/paperless) | Document scanning, OCR and search | http://paperless.home | `<SERVER_IP>:8000` |
| [caddy](services/caddy) | Gives the services the names above | | |

## Quick start
```bash
./homeserver setup                    # once, needs sudo, then reboot
cp .env.example .env && nano .env     # one settings file for all services
./homeserver install all              # or: ./homeserver install pihole immich
```
Changed `.env` or want to update? Run `./homeserver install <service>` again.

The names work at home and over Tailscale: Pi-hole points every `*.home` name
(`HOME_DOMAIN` in `.env`) to the server, and [Caddy](services/caddy) sends each
name to its service.

## Remote access (Tailscale)
`./homeserver setup` installs Tailscale and shares the home network (`LAN_SUBNET`)
with your Tailscale devices. The `*.home` names point to the LAN IP, so the same
addresses work everywhere: direct on home Wi-Fi, through Tailscale away.

One-time steps in the admin console (https://login.tailscale.com/admin):
1. **Access controls**: add the blocks from
   [scripts/tailscale-policy.hujson](scripts/tailscale-policy.hujson) to the policy
   file (before `./homeserver setup`). The server is then tagged `tag:server`:
   its login **never expires** and its subnet route is approved automatically.
2. **DNS** > **Nameservers** > **Add nameserver** > **Custom** > `SERVER_IP`
   (the LAN IP, not the 100.x one: Pi-hole only listens there), turn on
   **Restrict to domain (Split DNS)** with domain `home`, and leave
   **Override DNS servers** OFF. Only `*.home` names then go through Tailscale,
   so if the tunnel drops, normal internet keeps working. (No Pi-hole ad blocking
   away from home.)

Server asks to log in again? It's not tagged yet. Run `./homeserver setup` again.

On each phone or laptop: install Tailscale and log in. Linux laptops also need
`sudo tailscale set --accept-routes`.

Test away from home (e.g. phone on mobile data, Tailscale on): open http://pihole.home.

Notes:
- Give your home network an unusual subnet in the router (e.g. `192.168.77.0/24`).
  If a network you visit uses the same one as home (often `192.168.0.x`/`192.168.1.x`), the server can't be reached.
  After changing it, run `./homeserver setup` and `./homeserver install pihole` again.
- Don't forward port 53 to this server in your router.
- "Relay server timed out" on the phone: Tailscale couldn't connect directly and
  the relay failed. Forward **UDP 41641** in the router to `SERVER_IP` (or turn on
  UPnP) so phones connect directly, and use Ethernet for the server if you can.

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
| Desktop off / on | `./homeserver desktop off` / `on` / `status` (see below) |

## Desktop off (saves RAM)
The server doesn't need a desktop. Turning it off frees RAM and CPU for the
services, which keep running either way.

```bash
./homeserver desktop off      # from the next reboot: text login only
./homeserver desktop on       # desktop back, right away and after reboots
./homeserver desktop status   # which one is set
```
Before turning it off, make sure you can log in over SSH (or Tailscale SSH) from
another computer. At the server itself you get a text login instead of the
desktop. Log in there and run `./homeserver desktop on` to get the desktop back.

## Backups
`./homeserver backup all` saves each service to `BACKUP_DIR/<service>/`:

| Service | What is saved |
|---|---|
| pihole | `etc-pihole-<date>.tar.gz` (all settings) |
| youtrack | copy of YouTrack's own backups |
| jellyfin | `config-<date>.tar.gz` (settings, not media; stops Jellyfin for a moment) |
| immich | all photos, videos and Immich's daily database backups (only new files) |
| paperless | Paperless's own export: all documents, tags, settings, users (only new files) |

## Layout
```
.
├── homeserver          the one command for everything
├── .env.example        settings for all services (copy to .env)
├── scripts/
│   ├── setup-host.sh   one-time host setup (sudo)
│   ├── desktop.sh      turn the desktop off or on (sudo)
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
- Data: `~/.local/share/<service>/` (Immich and the Paperless consume folder: set in `.env`)
- Needs Podman 4.4+ (`podman --version`).
