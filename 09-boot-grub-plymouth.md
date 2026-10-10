# 09 · Boot: GRUB theme + Plymouth splash

Everything is staged in `~/.local/share/boot-theme/` and installed by three scripts. **Take the snapshot first.**

## Packages in this chapter

| Package | Role |
|---|---|
| `grub` | The bootloader. Shows the themed menu. `grub-mkfont` converts the font; `grub-mkconfig` / `grub-script-check` build and check `grub.cfg` |
| `plymouth` | The animated boot splash. Its `script` plugin runs `steins-gate.script` |
| `mkinitcpio` | Builds the initramfs. The `plymouth` hook puts the splash inside it (`lsinitcpio` lists the contents) |
| `btrfs-progs` | `btrfs subvolume snapshot` for the safety snapshot before touching boot files |
| `librsvg`, `python` | Render the GRUB background, the highlight images and the Plymouth tube images |

## 0. Safety net

```bash
sudo bash ~/.local/share/boot-theme/1-backup.sh
```
This copies `/etc/default/grub`, `/etc/mkinitcpio.conf`, `/boot/grub/grub.cfg` and the initramfs to `/root/boot-backup-<date>`, then takes a read-only btrfs snapshot `/.snapshots/pre-boot-theme-<date>`.

The ESP (`/boot`, vfat) isn't part of btrfs snapshots, which is why the copies are needed.

## 1. GRUB theme (`/boot/grub/themes/steins-gate`)

Build the assets:
```bash
G=~/.local/share/boot-theme/grub/steins-gate; mkdir -p $G; cd $G
cp ~/arch-setup/files/.local/share/boot-theme/grub/steins-gate/theme.txt .
python3 ~/Pictures/wallpapers/src/divergence.py --no-caption --y-shift=-170 > /tmp/grub-bg.svg
rsvg-convert -w 1920 -h 1080 /tmp/grub-bg.svg -o background.png
F=/usr/share/fonts/TTF/JetBrainsMonoNerdFont
R='0x20-0x7E,0xA0-0xFF,0x2010-0x2027,0x2190-0x21FF,0x2500-0x257F,0x25A0-0x25FF'   # keeps fonts ~19 KB instead of ~770 KB
grub-mkfont -r $R -s 16 -o jbm-regular-16.pf2 $F-Regular.ttf
grub-mkfont -r $R -s 24 -o jbm-regular-24.pf2 $F-Regular.ttf
grub-mkfont -r $R -s 24 -o jbm-bold-24.pf2   $F-Bold.ttf
```
Selection highlight (9-slice): `select_w.png`, `select_c.png`, `select_e.png`, each 48 px tall. These are rendered from small SVGs: a rounded rectangle, `#7aa2f7` at 18% fill with an 85% stroke.

`theme.txt`:
- The menu is centred below the meter (`left = 50%-380`, `top = 54%`, width 760, item height 48).
- Font names must match the names stored inside the `.pf2` files: `JetBrainsMono NF Regular 24` and so on.
- A `__timeout__` label reads "converging on worldline in %d s", with a key-hint line below it.

## 2. Plymouth theme (`/usr/share/plymouth/themes/steins-gate`)

```bash
python3 ~/.local/share/boot-theme/plymouth/render_assets.py   # tube-0..9, tube-dot, tube-off, base, captions
```
The script `steins-gate.script` animates eight tubes. They scramble, lock onto **1.048596** left to right (finishing at 2.4 s), then "STEINS GATE" fades in, and the tubes flicker occasionally afterwards.

The script deliberately uses **only syntax that Plymouth's own example theme uses** (`/usr/share/plymouth/themes/script/script.script`):
- no `%`
- no `else if`
- no `++` outside `for` headers
- no number-to-string concatenation

A parse error would leave a black screen, so this keeps it safe. The background is solid `#1a1b26`, because a subtle gradient showed a visible band.

## 3. System config changes (staged in `boot-theme/etc/`)

| File | Change |
|---|---|
| `/etc/default/grub` | `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash plymouth.use-simpledrm"`, `GRUB_GFXMODE=1920x1080,auto`, `GRUB_THEME="/boot/grub/themes/steins-gate/theme.txt"` |
| `/etc/mkinitcpio.conf` | `HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)` |
| `/etc/plymouth/plymouthd.conf` | `Theme=steins-gate`, `ShowDelay=0`, `DeviceTimeout=15` |

Why `plymouth.use-simpledrm`: on this laptop **amdgpu only becomes ready ~7.8 s into boot** (it takes ~4.5 s to load). By default Plymouth waits for it, which meant ~6 s of black screen and a ~2.6 s splash. With simpledrm the splash starts at ~1.5 s on the firmware framebuffer. You'll see one brief blink when amdgpu takes over.

## 4. Install and verify

```bash
sudo bash ~/.local/share/boot-theme/2-install.sh   # copy themes + configs, mkinitcpio -P, grub-mkconfig
sudo bash ~/.local/share/boot-theme/3-update.sh    # (follow-up) rewritten script, simpledrm, timeout; runs 8 checks
```
`3-update.sh` ends with **"All checks passed"**, which covers:
- `grub.cfg` syntax and the theme line
- the kernel command line
- the default Plymouth theme
- the script and `plymouthd.conf` inside the initramfs, compared byte-for-byte with the staged copies
- the `script.so` plugin, the DRM renderer, and all 15 theme images

Checks that were done during review:
- Every `theme.txt` property name exists in `/boot/grub/x86_64-efi/gfxmenu.mod`. An unknown global property makes GRUB drop the whole theme. "id" and "top" only show up as the tail ends of longer strings in the module, which is expected.
- `grub-script-check` passes on `/boot/grub/grub.cfg`.
- The PNGs are 8-bit and non-interlaced, which GRUB can load.
- SDDM is ordered after `plymouth-quit.service`, so the two don't fight over the display.

## Rollback

Copy the files from `/root/boot-backup-<date>` back to where they came from, then run `sudo mkinitcpio -P && sudo grub-mkconfig -o /boot/grub/grub.cfg`. Alternatively, boot the btrfs snapshot.
