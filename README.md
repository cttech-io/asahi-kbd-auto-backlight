# asahi-kbd-auto-backlight

Automatic keyboard backlight for Apple Silicon MacBooks running [Asahi Linux](https://asahilinux.org/). It reads the built-in ambient light sensor and turns the backlight up in a dark room and off in daylight, like macOS does.

## The problem

Asahi exposes both pieces of hardware. The keyboard backlight is `/sys/class/leds/kbd_backlight` and the ambient light sensor is `aop-sensors-als` via IIO and `iio-sensor-proxy`. Nothing connects them, though. GNOME's "Automatic Screen Brightness" uses the light sensor for the display only, so the keyboard backlight stays wherever you last left it.

## The fix

A small Python user service:

- Every 3 s it reads `LightLevel` (lux) from `iio-sensor-proxy` over D-Bus and takes the median of the last ~15 s of readings, so passing shadows and screen glare don't make it flicker.
- It maps lux to a brightness level and fades to it through UPower's `KbdBacklight` interface. That's the same API GNOME uses, so it doesn't need root or a udev rule.
- Each level boundary has a 30% buffer, so it doesn't keep switching when the light is borderline.
- If the backlight changes from somewhere else (the keyboard keys or GNOME), auto mode pauses for 30 minutes and then takes over again.

Default levels (brightness out of 255):

| Ambient light | Lux    | Backlight |
|---------------|--------|-----------|
| Dark room     | < 5    | 110       |
| Dim lamp      | 5–25   | 60        |
| Normal indoor | 25–80  | 25        |
| Bright / day  | ≥ 80   | off       |

## Requirements

- Asahi Linux (tested on Fedora Asahi Remix, M1 MacBook Air, GNOME)
- `iio-sensor-proxy` and `upower` (both come with Fedora Asahi's GNOME install)
- `python3-gobject`

Check that the sensor works:

```bash
monitor-sensor --light
```

## Install

```bash
./install.sh
```

This copies the script to `~/.local/bin`, installs the systemd user unit, enables it for your graphical session, and prints its status.

## Verify

```bash
journalctl --user -u kbd-auto-backlight -f
cat /sys/class/leds/kbd_backlight/brightness
```

Every level change shows up in the log, for example `lux=3 -> brightness 110`.

## Tuning

The constants at the top of `kbd-auto-backlight` control the behaviour:

- `LEVELS`: lux thresholds and brightness values
- `HYSTERESIS`: how far past a boundary the light has to go before the level changes
- `POLL_SECONDS` / `WINDOW`: how often it reads the sensor and how many readings it takes the median of
- `OVERRIDE_PAUSE`: how long a manual change keeps auto mode paused

After editing, run `./install.sh` again or `systemctl --user restart kbd-auto-backlight`.

## Uninstall

```bash
systemctl --user disable --now kbd-auto-backlight
rm ~/.local/bin/kbd-auto-backlight ~/.config/systemd/user/kbd-auto-backlight.service
systemctl --user daemon-reload
```

## Notes

- GNOME dims the keyboard backlight when the screen blanks for idle. The script counts that as a manual change, so it can stay paused for up to 30 minutes after you wake the screen.
- The light sensor sits near the camera. Bright screen content or a lamp pointed straight at it can make the reading a little high.
