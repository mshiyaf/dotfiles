#!/bin/bash
# USB connect/disconnect notification script (triggered by udev)
# Zero-daemon approach: only runs on USB events, no background process

USER_NAME=$(loginctl list-sessions --no-legend | while read session rest; do
    if loginctl show-session "$session" -p Type --value 2>/dev/null | grep -q wayland; then
        loginctl show-session "$session" -p Name --value 2>/dev/null
        break
    fi
done)

[ -z "$USER_NAME" ] && exit 0

USER_ID=$(id -u "$USER_NAME" 2>/dev/null)
[ -z "$USER_ID" ] && exit 0

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_ID}/bus"

SEND="/usr/bin/notify-send"

case "$ACTION" in
    add)
        DEV_MODEL="${ID_MODEL//\_/ }"
        DEV_VENDOR="${ID_VENDOR//\_/ }"
        DEV_LABEL="$ID_FS_LABEL"
        DEV_SIZE=$(lsblk -dnro SIZE "$DEVNAME" 2>/dev/null)

        BODY=""
        [ -n "$DEV_VENDOR" ] && BODY="$DEV_VENDOR"
        [ -n "$DEV_MODEL" ] && BODY="$BODY $DEV_MODEL"
        [ -n "$DEV_LABEL" ] && BODY="$BODY\nLabel: $DEV_LABEL"
        [ -n "$DEV_SIZE" ] && BODY="$BODY\nSize: $DEV_SIZE"
        BODY="$BODY\nDevice: $DEVNAME"

        sudo -u "$USER_NAME" \
            DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
            $SEND -u normal -i drive-removable-media \
            -a "USB Manager" \
            "📀 USB Device Connected" "$BODY"
        ;;
    remove)
        sudo -u "$USER_NAME" \
            DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
            $SEND -u normal -i drive-removable-media-usb \
            -a "USB Manager" \
            "⏏ USB Device Removed" "Device disconnected: $DEVNAME"
        ;;
esac
