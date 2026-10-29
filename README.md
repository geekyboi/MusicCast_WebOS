# Amp volume on the LG volume bar

Makes my LG TV's own volume bar show my Yamaha amp's real level (in dB) when the sound
goes out over HDMI ARC, instead of the useless up/down arrows.

My amp (a Yamaha RX-V679) doesn't report its volume back to the TV over HDMI-CEC, so
the TV gives up and just shows arrows. But the amp has a MusicCast web API on the
network that happily tells you its volume. So this patches the TV's volume bar to ask
the amp, and draw the normal bar with the amp's level and a `-44.5 dB` style number.

It's a sister project to [web-OSome](https://github.com/geekyboi/web-osome), my
replacement home screen for the same TV. You don't need one to use the other.

Built for my LG OLED55A2 (webOS 9.2.2, firmware 23.25.55). **It needs a rooted TV.**
It'll probably work with other MusicCast amps, but I've only tried mine.

## What it does

- When the sound output is HDMI ARC and the TV isn't getting the level over CEC, it asks
  the amp `GET http://<amp>/YamahaExtendedControl/v1/main/getStatus` each time you
  change the volume, and again 250 ms and 700 ms later (the amp is a beat behind the TV).
- The bar fills to `volume / max`. The max comes from the amp once (`system/getFeatures`).
- The number is the amp's dB, or `MUTE`.
- If the amp is off, unreachable, or answers with anything odd (800 ms timeout), you
  just get LG's arrows back.
- Everything else is untouched: TV speakers, other outputs, the mute pop-up, key
  handling. Spoken audio guidance still reads the TV's own number.

## How it works

It changes one file, `StarfishVolume.qml`, the volume bar the TV's system UI
(surface-manager) draws. `/usr` is read-only, so the install script copies LG's file to
`/home/root/osd-patch/`, applies `StarfishVolume.qml.diff` to it, puts your amp's
address in, and bind-mounts it over the original.

A boot script (`40-osd-volume`) goes in the Homebrew Channel's
`/var/lib/webosbrew/init.d/` and redoes the mount at every start-up. It's careful:

- it does nothing if LG's file isn't exactly the one this was made for (checked by
  md5), so a firmware update just turns it off rather than breaking your volume bar;
- it does nothing if `/home/root/osd-patch/disable` exists;
- surface-manager reads the file only when it starts, so it needs one restart. Doing
  that during start-up, with an app on screen, can crash LG's web app manager, and the
  TV then switches itself off. So the script waits for the first time the TV goes to
  standby after a boot and restarts it then, with the screen off. Until then you see
  LG's normal bar;
- restarting it under LG's running web app manager leaves the Magic Remote pointer
  invisible (it still moves and selects), so the script stops the web app manager first
  and starts it again afterwards, still in standby;
- if that restart is ever followed by a reboot, it doesn't try again until you delete
  `/home/root/osd-patch/restart-pending`;
- it logs to `/home/root/osd-patch/log`.

LG's original file isn't in this repo (it's LG's code), only the diff.

## Before you start: root the TV

You need root and the Homebrew Channel. webOS Brew's
[rooting guide](https://www.webosbrew.org/rooting/) tells you which method works for
your TV and firmware, so follow that rather than me. You'll also want SSH on, which is
a switch in the Homebrew Channel's settings.

You need your amp's IP address too (the MusicCast app shows it, or check your router).
Give it a fixed one so it doesn't wander off.

## Install

SSH into the TV as root, then:

```sh
cd /home/root
curl -L https://github.com/geekyboi/MusicCast_WebOS/archive/refs/heads/main.tar.gz | tar xz
cd MusicCast_WebOS-main
sh install.sh 192.168.1.50     # your amp's address
```

The screen goes blank for a second, then turn the volume up or down with the sound
on HDMI ARC. Run `install.sh` again any time to change the address.

No `patch` on your TV? Copy `/usr/lib/qml/WebOSCompositor/views/volume/StarfishVolume.qml`
to your computer, run `patch StarfishVolume.qml < StarfishVolume.qml.diff`, swap
`AMP_IP` for your amp's address, and copy it back to
`/home/root/osd-patch/StarfishVolume.qml`. Then copy `40-osd-volume` into
`/var/lib/webosbrew/init.d/`, `chmod +x` it and run it.

## Turn it off for a bit

Keeps everything installed, just stops using it:

```sh
touch /home/root/osd-patch/disable
umount /usr/lib/qml/WebOSCompositor/views/volume/StarfishVolume.qml
```

Then restart the TV (hold the power button).

To turn it back on: `rm /home/root/osd-patch/disable`, then restart the TV or run
`sh /var/lib/webosbrew/init.d/40-osd-volume`.

## Uninstall

```sh
sh uninstall.sh
```

That removes the boot script and the patched file. Restart the TV afterwards to put
LG's bar back. (A reboot
after removing just `/var/lib/webosbrew/init.d/40-osd-volume` does the same, minus the
tidying up.)

## After a firmware update

The boot script spots that LG's file changed and leaves it alone, so you're back to
arrows. If the diff still applies to the new file, update the md5 in `install.sh` and
`40-osd-volume` and run `install.sh` again. If it doesn't, the patch needs redoing for
the new firmware.

## Messing with it

Edit the patched copy at `/home/root/osd-patch/StarfishVolume.qml` with `cat >` (that
keeps the same file, so the existing mount sees it), then
`systemctl stop webapp-mgr.service; systemctl restart surface-manager-daemon.service; sleep 3; systemctl start webapp-mgr.service`
(stopping the web app manager first keeps the pointer working). The changes are all marked
`osd-patch` / `amp` in the file.

## Licence

MIT, see [LICENSE](LICENSE). That covers my patch and scripts, not LG's file. No
warranty: it's a patch to your TV's system UI, so if it breaks, an `umount` or a reboot
with the boot script removed gets you back to stock.
