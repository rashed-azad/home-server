# Pi-hole + Unbound

Network-wide ad blocking. Pi-hole blocks bad domains; allowed lookups go to
**Unbound**, which asks each domain's own servers directly (no Cloudflare/Google)
and checks DNSSEC locally.

## Install
```bash
./homeserver install pihole             # needs PIHOLE_PASSWORD in .env
./services/pihole/add-blocklists.sh     # optional: adds the Hagezi lists below
```
- Web UI: `http://<SERVER_IP>:8080/admin` (LAN IP only, not `localhost`)
- In your router: give this server a fixed IP and set it as the DNS server.
- Restore old settings: Web UI > Settings > Teleporter > Import `.zip`.

## Blocklists (`add-blocklists.sh`)
Hagezi Ultimate (ads/trackers/malware), NSFW, TIF (threats), Gambling, Anti-Piracy.
They apply to every device on the network. If a site breaks, check the Query Log
and disable that one list in Web UI > Adlists.

## Tests
- `dig @<SERVER_IP> doubleclick.net` should return `0.0.0.0`
- `dig @<SERVER_IP> dnssec-failed.org` should return `SERVFAIL`

## Notes
- Unbound runs inside Pi-hole's network and listens on `127.0.0.1:5335` there, so
  only Pi-hole can reach it (not the host, not the LAN). Config in
  [unbound/unbound.conf](unbound/unbound.conf). Restarting Pi-hole restarts Unbound too.
- Unbound logs: `journalctl --user -u unbound` (errors only, `verbosity: 1`).
- To use Cloudflare instead of Unbound: set `FTLCONF_dns_upstreams=1.1.1.1;1.0.0.1`
  in [pihole.container.in](pihole.container.in) and install again.
- IPv6: the host has it disabled (`setup-host.sh`) and Pi-hole never returns AAAA answers.
