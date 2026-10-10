#!/usr/bin/env bash
# Phase 5: install GRUB + Plymouth steins-gate themes and rebuild boot files.
set -euo pipefail
B=/home/adham/.local/share/boot-theme

# GRUB theme
rm -rf /boot/grub/themes/steins-gate
cp -r "$B/grub/steins-gate" /boot/grub/themes/
install -m644 "$B/etc/grub" /etc/default/grub

# Plymouth theme
rm -rf /usr/share/plymouth/themes/steins-gate
cp -r "$B/plymouth/steins-gate" /usr/share/plymouth/themes/
install -Dm644 "$B/etc/plymouthd.conf" /etc/plymouth/plymouthd.conf
install -m644 "$B/etc/mkinitcpio.conf" /etc/mkinitcpio.conf

echo ">> rebuilding initramfs"
mkinitcpio -P
echo ">> regenerating grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "Checks:"
plymouth-set-default-theme
grep -m1 -o 'splash' /boot/grub/grub.cfg && echo "  splash in kernel cmdline"
grep -m1 'theme=' /boot/grub/grub.cfg || grep -m1 'set theme' /boot/grub/grub.cfg
lsinitcpio /boot/initramfs-linux.img | grep -c 'plymouth/themes/steins-gate' | sed 's/^/  theme files in initramfs: /'
