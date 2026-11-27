#!/usr/bin/env bash
# Turn the desktop (graphical login screen) off or on.
# Off saves RAM and CPU for the services. The services keep running either way.
# Needs sudo. Run: ./homeserver desktop off|on|status
set -euo pipefail

case "${1:-status}" in
  off)
    sudo systemctl set-default multi-user.target
    echo "Desktop is OFF from the next reboot (text login and SSH only)."
    echo "To turn it off right now (closes your desktop session!):"
    echo "  sudo systemctl isolate multi-user.target"
    ;;
  on)
    sudo systemctl set-default graphical.target
    sudo systemctl isolate graphical.target
    echo "Desktop is ON, now and after every reboot."
    ;;
  status)
    if [ "$(systemctl get-default)" = "multi-user.target" ]; then
      echo "Desktop: OFF at boot. Turn on: ./homeserver desktop on"
    else
      echo "Desktop: ON at boot. Turn off: ./homeserver desktop off"
    fi
    ;;
  *)
    echo "Usage: ./homeserver desktop off|on|status" >&2
    exit 1
    ;;
esac
