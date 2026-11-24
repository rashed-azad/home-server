# Jellyfin. Used by ./homeserver (see the top of that file).
NAME="Jellyfin"
URL="http://$SERVER_IP:8096"
UNITS=(jellyfin)
DATA=(~/.local/share/jellyfin/{config,cache})

check() { require JELLYFIN_MEDIA_DIR; }

# After start: apply best-quality settings, once JELLYFIN_API_KEY is set
ready() {
  local api=http://localhost:8096
  wait_for "$api/health" Healthy
  echo "Jellyfin is running: $URL"

  if [ -z "${JELLYFIN_API_KEY:-}" ]; then
    echo "Next: finish the setup wizard, then Dashboard > API Keys > +,"
    echo "put the key in .env as JELLYFIN_API_KEY and run install again."
    return
  fi

  get()  { curl -s -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" "$api$1"; }
  save() { curl -s -X POST -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
                -H "Content-Type: application/json" -d "$2" "$api$1"; }

  echo "Settings: video conversion (Intel QSV)"
  save /System/Configuration/encoding "$(get /System/Configuration/encoding | jq '
    .HardwareAccelerationType = "qsv"
    | .VaapiDevice = "/dev/dri/renderD128"
    | .EnableHardwareEncoding = true
    | .AllowHevcEncoding = true
    | .HardwareDecodingCodecs = ["h264", "hevc", "mpeg2video", "vc1"]
    | .EnableDecodingColorDepth10Hevc = false
    | .EncodingThreadCount = -1
    | .EnableThrottling = true
    | .EnableSegmentDeletion = true
  ')"

  echo "Settings: each library"
  local id
  for id in $(get /Library/VirtualFolders | jq -r '.[].ItemId'); do
    save /Library/VirtualFolders/LibraryOptions "$(get /Library/VirtualFolders | jq --arg id "$id" '
      .[] | select(.ItemId == $id) | {
        Id: .ItemId,
        LibraryOptions: (.LibraryOptions
          | .EnableTrickplayImageExtraction = true
          | .EnableChapterImageExtraction = true
          | .EnableRealtimeMonitor = true)
      }')"
  done
  echo "Settings applied."
}

# Settings only (media is yours already). Stops Jellyfin briefly for a clean copy.
backup() {
  local f="$1/config-$(date +%F).tar.gz" rc=0
  systemctl --user stop jellyfin
  podman unshare tar -czf "$f" -C ~/.local/share/jellyfin config || rc=$?
  systemctl --user start jellyfin
  [ $rc -eq 0 ] && echo "Saved $f"
  return $rc
}
