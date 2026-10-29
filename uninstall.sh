#!/bin/sh
# Run on the TV as root: sh uninstall.sh
# Removes the boot script and the patched file, and puts LG's volume bar back.
F=/usr/lib/qml/WebOSCompositor/views/volume/StarfishVolume.qml
rm -f /var/lib/webosbrew/init.d/40-osd-volume
# Restarting surface-manager here, with the TV on, would hide the Magic Remote pointer
# until a reboot, so leave the reboot to you.
if grep -q " $F " /proc/mounts; then umount "$F"; fi
rm -rf /home/root/osd-patch
echo "Done. Restart the TV (hold the power button) to get LG's volume bar back."
