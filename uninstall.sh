#!/bin/sh
# Run on the TV as root: sh uninstall.sh
# Removes the boot script and the patched file, and puts LG's volume bar back.
F=/usr/lib/qml/WebOSCompositor/views/volume/StarfishVolume.qml
rm -f /var/lib/webosbrew/init.d/40-osd-volume
if grep -q " $F " /proc/mounts; then
  umount "$F"
  systemctl restart surface-manager-daemon.service
fi
rm -rf /home/root/osd-patch
grep -q StarfishVolume /proc/mounts && echo "Still mounted somewhere, a reboot will clear it." || echo "Done, LG's volume bar is back."
