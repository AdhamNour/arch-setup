#!/usr/bin/env bash
# Phase 5 follow-up: rewritten Plymouth script, early splash (plymouth.use-simpledrm),
# longer DeviceTimeout. Rebuilds initramfs + grub.cfg and verifies the results.
set -euo pipefail
B=/home/adham/.local/share/boot-theme

install -m644 "$B/plymouth/steins-gate/steins-gate.script" /usr/share/plymouth/themes/steins-gate/steins-gate.script
install -Dm644 "$B/etc/plymouthd.conf" /etc/plymouth/plymouthd.conf
install -m644 "$B/etc/grub" /etc/default/grub

echo ">> rebuilding initramfs"
mkinitcpio -P
echo ">> regenerating grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "== Verification"
ok=1
check() { if eval "$2"; then echo "  ok    $1"; else echo "  FAIL  $1"; ok=0; fi; }

check "grub.cfg syntax"                        "grub-script-check /boot/grub/grub.cfg"
check "kernel cmdline has splash + simpledrm"  "grep -q 'quiet splash plymouth.use-simpledrm' /boot/grub/grub.cfg"
check "grub.cfg loads the theme"               "grep -q 'set theme=(\$root)/grub/themes/steins-gate/theme.txt' /boot/grub/grub.cfg"
check "plymouth default theme is steins-gate"  "[ \"\$(plymouth-set-default-theme)\" = steins-gate ]"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$tmp" && lsinitcpio -x /boot/initramfs-linux.img >/dev/null 2>&1) || true
check "initramfs: script matches staged copy"  "cmp -s '$tmp/usr/share/plymouth/themes/steins-gate/steins-gate.script' '$B/plymouth/steins-gate/steins-gate.script'"
check "initramfs: plymouthd.conf matches"      "cmp -s '$tmp/etc/plymouth/plymouthd.conf' '$B/etc/plymouthd.conf'"
check "initramfs: script plugin + drm renderer" "[ -f '$tmp/usr/lib/plymouth/script.so' ] && [ -f '$tmp/usr/lib/plymouth/renderers/drm.so' ]"
check "initramfs: all 15 theme images present" "[ \$(ls '$tmp/usr/share/plymouth/themes/steins-gate/'*.png | wc -l) -eq 15 ]"

echo
if [ "$ok" = 1 ]; then echo "All checks passed. Reboot when ready."; else echo "Some checks FAILED — don't reboot yet, paste this output."; exit 1; fi
