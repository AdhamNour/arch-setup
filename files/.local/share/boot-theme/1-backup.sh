#!/usr/bin/env bash
# Phase 5 safety net: copy boot files (ESP isn't in btrfs snapshots), then snapshot /.
set -euo pipefail
stamp=$(date +%Y%m%d-%H%M)
dir=/root/boot-backup-$stamp
mkdir -p "$dir"
cp -a /etc/default/grub /etc/mkinitcpio.conf /boot/grub/grub.cfg /boot/initramfs-linux.img "$dir"/
[ -f /etc/plymouth/plymouthd.conf ] && cp -a /etc/plymouth/plymouthd.conf "$dir"/
btrfs subvolume snapshot -r / "/.snapshots/pre-boot-theme-$stamp"
echo
echo "Backup:   $dir"
echo "Snapshot: /.snapshots/pre-boot-theme-$stamp"
ls -la "$dir"
