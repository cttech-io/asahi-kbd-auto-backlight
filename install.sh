#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

install -Dm755 kbd-auto-backlight "$HOME/.local/bin/kbd-auto-backlight"
install -Dm644 kbd-auto-backlight.service "$HOME/.config/systemd/user/kbd-auto-backlight.service"

systemctl --user daemon-reload
systemctl --user enable kbd-auto-backlight
systemctl --user restart kbd-auto-backlight

sleep 2
systemctl --user --no-pager status kbd-auto-backlight | head -5
journalctl --user -u kbd-auto-backlight --no-pager -n 5
