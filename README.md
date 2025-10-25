# Battery Threshold Service

A systemd service to automatically manage battery charge limits on ASUS laptops.

## The Problem

**The ASUS Vivobook 18 M1807HA has critical issues with battery charge limit management:**

1. **Non-persistent settings**: The laptop forgets the battery charge limit settings after each reboot or sleep/wake cycle.

2. **Limited accepted values**: The laptop sometimes refuses to accept charge limit values unless they are exactly 50 or 100. It is unknown if all laptops have this issue or if it's specific to certain units/firmware versions.

The Linux kernel provides the ability to set battery charge thresholds through `/sys/class/power_supply/BAT0/charge_control_end_threshold`, which helps extend battery lifespan by preventing it from constantly charging to 100%. However, on the ASUS Vivobook 18 M1807HA, this setting is not persistent and gets reset, requiring manual intervention after every reboot or suspend. Additionally, the hardware may reject arbitrary threshold values, limiting the flexibility of battery management.

## The Solution

Keeping a lithium-ion battery constantly at 100% charge significantly reduces its lifespan. By maintaining the charge between 50-80% during normal use, you can extend your battery's health by years. This is especially important for laptops that remain plugged in most of the time.

This service provides an automated workaround by:
- Running every minute via a systemd timer
- Monitoring the current battery capacity
- Automatically adjusting the charge threshold based on battery level
- Implementing a hysteresis mechanism to prevent constant charging/discharging cycles

## How It Works

The service uses a naive algorithm to manage battery health:

1. **When battery is LOW** (< 60%): Set charge limit to 100% to allow full charging
2. **When battery is HIGH** (> 70%): Set charge limit to 50% to preserve battery health
3. **When battery is in-between** (60-70%): No changes to avoid oscillation

This creates a hysteresis effect that keeps your battery in the optimal range for longevity while ensuring you have enough charge when needed.

## Configuration

All thresholds are configurable through environment variables in `battery-threshold.service`:

| Variable | Default | Description |
|----------|---------|-------------|
| `LOW_CAPACITY` | 60 | Below this %, charge to HIGH_THRESHOLD |
| `HIGH_CAPACITY` | 70 | Above this %, charge to LOW_THRESHOLD |
| `HIGH_THRESHOLD` | 100 | Max charge when battery is low |
| `LOW_THRESHOLD` | 50 | Max charge when battery is high |
| `DEBUG` | 0 | Set to 1 to enable debug logging |

### Customizing Thresholds

Edit `/etc/systemd/system/battery-threshold.service` and modify the `Environment` values:

```ini
Environment=LOW_CAPACITY=60
Environment=HIGH_CAPACITY=80
Environment=HIGH_THRESHOLD=100
Environment=LOW_THRESHOLD=50
```

Then reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart battery-threshold.timer
```

## Installation

```bash
# Install and start the service
make install
```

## Checking Status

```bash
# Check timer status
sudo systemctl status battery-threshold.timer

# Check service logs (live tail)
sudo journalctl -u battery-threshold.service -f

# Check last 10 log entries from the last 24 hours
sudo journalctl -u battery-threshold.service -n 10 --since "24 hours ago"

# Enable debug mode for detailed logging
sudo systemctl edit battery-threshold.service
# Add: Environment=DEBUG=1
sudo systemctl daemon-reload
sudo systemctl restart battery-threshold.timer
```

## Viewing Current Battery Info

```bash
# Current battery capacity
cat /sys/class/power_supply/BAT0/capacity

# Current charge threshold
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

## Uninstall

```bash
make uninstall
```

## Alternative Solution

### asusctl Utility

An alternative approach is to use the `asusctl` utility, which is part of the [asusctl/supergfxctl](https://gitlab.com/asus-linux/asusctl) project designed for ASUS laptops.

Example command to set battery charge limit:

```bash
# Set battery charge limit to 80%
asusctl -c 80
```

**Limitations:**

**Static threshold only**: While `asusctl` is a powerful utility for managing ASUS laptop features, it supports just a fixed charge limit (e.g., 80%) that remains constant regardless of battery level. 

This systemd service complements or replaces `asusctl` by providing automated, dynamic threshold management with hysteresis behavior.

## Files

- `battery-threshold.sh` - Main script that adjusts battery thresholds
- `battery-threshold.service` - Systemd service unit
- `battery-threshold.timer` - Systemd timer (runs every minute)
- `makefile` - Installation and uninstallation commands

## Compatibility

Designed for the particular ASUS Vivobook 18 M1807HA laptop model running Linux with kernel support for battery charge control. Requires root access to modify system files.

## Author

Written by Pauel in 2025.

## License

This is free and unencumbered software released into the public domain.

See the [LICENSE](LICENSE) file for full details.

