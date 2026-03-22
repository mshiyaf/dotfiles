# USB Device Notifications (udev)

Zero-daemon USB connect/disconnect notifications for Wayland desktops.
No background process — only fires on USB events via udev rules.

## Files

- `99-usb-notify.rules` — udev rule that triggers on USB block device add/remove
- `usb-notify.sh` — notification script using `notify-send`

## Dependencies

- `libnotify` (for `notify-send`)
- `udisks2` (for `udisksctl` mount/unmount/eject)

## Installation

```bash
# Copy the notification script
sudo cp usb-notify.sh /usr/local/bin/usb-notify.sh
sudo chmod +x /usr/local/bin/usb-notify.sh

# Copy the udev rule
sudo cp 99-usb-notify.rules /etc/udev/rules.d/

# Reload udev rules (no reboot needed)
sudo udevadm control --reload-rules
```

## Eject a USB Drive

```bash
udisksctl unmount -b /dev/sdX1
udisksctl power-off -b /dev/sdX
```
