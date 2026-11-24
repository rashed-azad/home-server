#!/usr/bin/env bash
# Add curated Hagezi blocklists via the Pi-hole API, then rebuild gravity.
# Safe to run again: skips lists that are already present. No sudo.
source "$(dirname "$0")/../../scripts/lib.sh"
load_env
API="http://$SERVER_IP:$PIHOLE_WEB_PORT/api"

# url|comment
LISTS=(
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt|Hagezi Ultimate: ads, trackers, malware, phishing, scams"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/nsfw.txt|Hagezi NSFW: adult content"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt|Hagezi TIF: threat intelligence feeds"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/gambling.txt|Hagezi Gambling: gambling sites"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/anti.piracy.txt|Hagezi Anti-Piracy: piracy/torrent sites"
)

SID=""
TMP="$(mktemp)"
cleanup() {
  rm -f "$TMP"
  [ -n "$SID" ] && curl -s -X DELETE "$API/auth" -H "X-FTL-SID: $SID" >/dev/null || true
}
trap cleanup EXIT

AUTH="$(curl -s -X POST "$API/auth" -H "Content-Type: application/json" -d "{\"password\":\"$PIHOLE_PASSWORD\"}")"
SID="$(grep -oP '"sid"\s*:\s*"[^"]+' <<<"$AUTH" | sed 's/.*"//')"
if [ -z "$SID" ]; then
  echo "Login failed. Does PIHOLE_PASSWORD in .env match the Web UI password?"
  echo "Response: $AUTH"
  exit 1
fi

EXISTING="$(curl -s "$API/lists" -H "X-FTL-SID: $SID")"
for entry in "${LISTS[@]}"; do
  url="${entry%%|*}"; comment="${entry#*|}"
  if grep -qF "\"$url\"" <<<"$EXISTING"; then
    echo "Already present: $url"; continue
  fi
  echo "Adding: $comment"
  # type=block must be a query param - the API rejects it in the JSON body
  status="$(curl -s -o "$TMP" -w '%{http_code}' -X POST "$API/lists?type=block" \
    -H "X-FTL-SID: $SID" -H "Content-Type: application/json" \
    -d "{\"address\":\"$url\",\"comment\":\"$comment\",\"enabled\":true}")"
  [ "$status" = "201" ] || echo "  warning: HTTP $status - $(cat "$TMP")"
done

echo "Rebuilding gravity..."
curl -s -X POST "$API/action/gravity" -H "X-FTL-SID: $SID" | tail -5
echo "Done. Review in Web UI > Adlists."
