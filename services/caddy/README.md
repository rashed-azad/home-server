# Caddy

Gives every service a name instead of `IP:port`, at home and over Tailscale:

| Address | Service |
|---|---|
| http://pihole.home | Pi-hole |
| http://youtrack.home | YouTrack |
| http://jellyfin.home | Jellyfin |
| http://immich.home | Immich |
| http://paperless.home | Paperless-ngx |

(`home` is `HOME_DOMAIN` in `.env`.)

## Install
```bash
./homeserver install pihole caddy   # Pi-hole answers *.home with the server's IP
```
Your devices must use Pi-hole as DNS (router at home, Tailscale DNS away).

## Add a service
Add a block to [Caddyfile.in](Caddyfile.in), then `./homeserver install caddy`:
```
http://myapp.@HOME_DOMAIN@ {
	reverse_proxy @SERVER_IP@:1234
}
```

## Notes
- Plain http only. `.home` names can't get public HTTPS certificates.
- The old `http://<SERVER_IP>:<port>` addresses still work.
- Apps (Immich, Jellyfin): use `http://immich.home` / `http://jellyfin.home` as the server address.
