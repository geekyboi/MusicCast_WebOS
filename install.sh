#!/bin/sh
# Run on the TV as root: sh install.sh <amp IP address>
# Patches a copy of LG's volume bar with your amp's address, installs the boot script
# and turns it on. Run it again to change the address.
set -e
cd "$(dirname "$0")"
AMP="$1"
F=/usr/lib/qml/WebOSCompositor/views/volume/StarfishVolume.qml
DIR=/home/root/osd-patch
HOOK=/var/lib/webosbrew/init.d/40-osd-volume
ORIG_MD5=808fd0cd00451235b098876477276ad1

echo "$AMP" | grep -Eq '^[A-Za-z0-9.-]+$' || { echo "usage: sh install.sh <amp IP address, e.g. 192.168.1.50>"; exit 1; }
[ -d /var/lib/webosbrew/init.d ] || { echo "No /var/lib/webosbrew/init.d. Is the Homebrew Channel installed?"; exit 1; }

# Re-running: take the old patch off first so we're patching LG's file, not ours.
if grep -q " $F " /proc/mounts; then umount "$F"; fi

if [ "$(md5sum < "$F" | cut -d' ' -f1)" != "$ORIG_MD5" ]; then
  echo "Your TV's StarfishVolume.qml isn't the one this patch was made for"
  echo "(different firmware?). Not touching it."
  exit 1
fi

if command -v patch >/dev/null 2>&1; then PATCH=patch
elif busybox patch --help >/dev/null 2>&1; then PATCH="busybox patch"
else echo "No 'patch' command on this TV. See the README for patching on your computer instead."; exit 1
fi

mkdir -p "$DIR"
cp "$F" "$DIR/StarfishVolume.qml.new"
$PATCH "$DIR/StarfishVolume.qml.new" < StarfishVolume.qml.diff
sed -i "s/\"AMP_IP\"/\"$AMP\"/" "$DIR/StarfishVolume.qml.new"
mv "$DIR/StarfishVolume.qml.new" "$DIR/StarfishVolume.qml"
rm -f "$DIR/disable"

cp 40-osd-volume "$HOOK"
chmod +x "$HOOK"
echo "Applying it now. The screen goes blank for a second or two."
sh "$HOOK"
cat /tmp/osd-patch.log 2>/dev/null | tail -n 1
