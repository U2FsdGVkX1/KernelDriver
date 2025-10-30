#!/bin/sh
# Init script for Linux Driver Development SDK

# Mount essential filesystems
PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Load kernel modules
echo "Loading drivers..."
for ko in /lib/modules/*.ko; do
  [ -f "$ko" ] && insmod "$ko" && echo "Loaded: $(basename $ko)"
done

# Welcome message
echo "Welcome to Linux Driver Development SDK"

# Start shell
exec /bin/sh
