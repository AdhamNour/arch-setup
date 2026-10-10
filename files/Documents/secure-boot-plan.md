# Re-enable Secure Boot (Arch + GRUB, own keys via sbctl)


## Context
Secure Boot was disabled during the Arch install. The goal is to turn it back on in the Acer BIOS while keeping the current boot chain working: GRUB with the steins-gate theme → Plymouth → SDDM → Hyprland.

**Current state (checked 2026-09-25, read-only):**
- **Machine:** Acer Aspire A515-45G, InsydeH2O BIOS V1.13, TPM present.
- **Secure Boot:** `SecureBoot=0`, `SetupMode=0`, meaning the Acer/Microsoft factory keys are still enrolled.
- **Boot entry:** single `Boot0002 GRUB → \EFI\GRUB\grubx64.efi`. The ESP is `/boot` (vfat), and there is no fallback `BOOTX64.EFI`.
- **GRUB 2.14** was installed with the default **shim_lock** verifier. With Secure Boot on and no shim, it refuses to boot kernels, so it **must be reinstalled**.
- **Signing tools:** none installed. `sbctl 0.18` is available in `extra`.
- **Kernel:** no DKMS/out-of-tree modules. The kernel's lockdown is `[none]`, so modules don't need signing. Only **GRUB and the kernel** do.

**Approach:** our own Secure Boot keys, created and managed by `sbctl`, with **Microsoft's keys kept alongside them** (`-m`). No shim.
- Microsoft keys stay because firmware option ROMs (e.g. the Radeon dGPU's) are signed by Microsoft. Removing them can leave a laptop with no display.
- GRUB is reinstalled with `--disable-shim-lock` and all needed modules built in, because Secure Boot stops GRUB loading modules from disk.

## Step 0: Safety net (Linux, Secure Boot still off)
- Take a btrfs snapshot: `sudo btrfs subvolume snapshot -r / /.snapshots/pre-secureboot-$(date +%Y%m%d-%H%M)`
- Back up the ESP: `sudo cp -a /boot /root/boot-backup-pre-secureboot`
- Make sure a **bootable Arch USB** is available, as a rescue path in case of the worst.

## Step 1: BIOS, enter Setup Mode (F2 at power-on)
Menu names vary slightly between Acer versions. These are the usual InsydeH2O ones.
1. **Security → Set Supervisor Password.** Acer hides the Secure Boot key options until one is set. **Write it down.** A forgotten Acer supervisor password needs Acer support to clear.
2. **Boot → Boot Mode:** confirm it's **UEFI**. Leave **Secure Boot: Disabled** for now.
3. **Security → Erase all Secure Boot Settings → Yes.** This clears PK/KEK/db, which is **Setup Mode**. The option may appear only once Secure Boot is set to Enabled. If so, enable it, erase the settings, then set it back to Disabled.
4. **F10** to save and exit, then boot Arch normally (GRUB still works, since Secure Boot is off).

## Step 2: Keys and signing (Linux)
```
sudo pacman -S sbctl
sbctl status                     # expect: Setup Mode ✓ Enabled, Secure Boot ✗ Disabled
sudo sbctl create-keys           # stored in /var/lib/sbctl (part of the btrfs root; covered by snapshots)
sudo sbctl enroll-keys -m        # -m = keep Microsoft keys (option ROMs); do NOT skip
sbctl status                     # expect: Setup Mode ✗ Disabled (our keys are now enrolled)
```
Reinstall GRUB without shim_lock and with every module the config uses built in (theme, fonts, PNG, btrfs+zstd for `unicode.pf2`, the firmware-settings entry, and `tpm` so lockdown's verifier chain is satisfied):
```
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --disable-shim-lock \
  --modules="tpm part_gpt part_msdos fat btrfs zstd search search_fs_uuid search_fs_file search_label \
  normal configfile linux boot echo test true cat ls sleep reboot halt minicmd regexp loadenv gettext \
  all_video video efi_gop font gfxterm gfxterm_background gfxmenu png jpeg efifwsetup keystatus"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
Sign, and register the files with sbctl's database (`-s`), so the pacman hook re-signs them on every kernel update:
```
sudo sbctl sign -s /boot/EFI/GRUB/grubx64.efi
sudo sbctl sign -s /boot/vmlinuz-linux
sbctl verify                     # both files: ✓ signed
```

## Step 3: Test boot with Secure Boot still OFF
Reboot once *before* turning Secure Boot on. This proves the rebuilt GRUB image works, including the theme, Plymouth and SDDM. If anything is missing (e.g. `unknown command` or a plain-text menu), fix it by adding the missing module to `--modules`, then re-running Step 2's `grub-install` and `sbctl sign`.

## Step 4: BIOS, turn Secure Boot on
F2 → **Boot → Secure Boot: Enabled** → F10. Boot Arch.

## Verification
- `sbctl status`: Installed ✓, Setup Mode ✗ Disabled, **Secure Boot ✓ Enabled**.
- `bootctl status | grep -i secure`: `Secure Boot: enabled (user)`.
- `od -An -t u1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-*`: `1`.
- The full chain looks as before: GRUB theme → splash → SDDM → Hyprland.
- `journalctl -b -p err` shows no new verification errors.

## Keeping it working
- **Kernel updates:** sbctl's pacman hook (`/usr/share/libalpm/hooks/zz-sbctl.hook`) re-signs every file registered with `-s`. Check once after the next `linux` update with `sbctl verify`.
- **Re-running `grub-install`** (e.g. after a GRUB update) overwrites the signed image. Use the same flags and module list, then `sudo sbctl sign-all`.
- **Signing keys:** back up `/var/lib/sbctl` (it's in the root snapshots). Losing it only means you can't sign new images. The fix is Setup Mode plus new keys.

## Rollback (if it won't boot with Secure Boot on)
1. F2 → **Secure Boot: Disabled** → boots exactly as today (the signed files still work without Secure Boot).
2. To return to factory keys: Security → **Restore Secure Boot to Factory Default**.
3. **Worst case:** boot the Arch USB, mount the ESP, restore `/root/boot-backup-pre-secureboot`, or roll back to the btrfs snapshot.
