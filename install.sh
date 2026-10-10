#!/usr/bin/env bash
# Tokyo Night × Steins;Gate rice installer — automates the recipe in this directory.
#
# Usage:  ./install.sh [--dry-run] [stage ...]
#   stages: packages dotfiles wallpaper theming services sddm boot   (or: all = everything except boot)
#   no stage given → "all"
#
#   ./install.sh --dry-run all      # show what would happen, change nothing
#   ./install.sh all                # desktop rice
#   ./install.sh boot               # GRUB theme + Plymouth splash (separately, after a snapshot)
#
# Run as your normal user; sudo is used only where needed. Existing files are backed up
# as <file>.bak-<timestamp> before being replaced.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$HERE/files"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0

# ------------------------------------------------------------------ helpers
c_blue=$'\e[38;2;122;162;247m'; c_orange=$'\e[38;2;255;158;100m'; c_red=$'\e[38;2;247;118;142m'
c_green=$'\e[38;2;158;206;106m'; c_dim=$'\e[38;2;86;95;137m'; c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_blue" "$*" "$c_off"; }
info() { printf '%s  · %s%s\n' "$c_dim" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_orange" "$*" "$c_off"; }
die()  { printf '%s  ✗ %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }
ok()   { printf '%s  ✓ %s%s\n' "$c_green" "$*" "$c_off"; }

# run a command, or just print it in dry-run mode
run() {
    if [ "$DRY" = 1 ]; then printf '%s    $ %s%s\n' "$c_dim" "$*" "$c_off"; else "$@"; fi
}
have() { command -v "$1" >/dev/null 2>&1; }

# copy one file into place, backing up a different existing file first
install_file() {   # src dest [mode]
    local src=$1 dest=$2 mode=${3:-}
    if [ -e "$dest" ] && cmp -s "$src" "$dest"; then return 0; fi
    if [ -e "$dest" ]; then run cp -a "$dest" "$dest.bak-$STAMP"; info "backed up $dest"; fi
    run mkdir -p "$(dirname "$dest")"
    run cp "$src" "$dest"
    [ -n "$mode" ] && run chmod "$mode" "$dest"
    return 0
}

# ------------------------------------------------------------------ stages
stage_packages() {
    step "Packages (pacman)"
    local pkgs=(
        # session
        hyprland waybar kitty wofi xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        polkit-kde-agent pipewire pipewire-pulse pipewire-alsa wireplumber hyprpaper
        brightnessctl network-manager-applet pavucontrol thunar playerctl grim slurp
        ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji python librsvg
        # rice
        papirus-icon-theme qt6ct kvantum nwg-look hyprlock hypridle swaync cliphist
        wl-clipboard fastfetch eza bat btop tmux starship
        # bluetooth
        bluez bluez-utils blueman
        # login + boot
        sddm xorg-server plymouth
        # build tools for yay
        base-devel git
    )
    run sudo pacman -S --needed "${pkgs[@]}"

    step "AUR helper (yay)"
    if have yay; then ok "yay already installed"
    else
        local tmp; tmp=$(mktemp -d)
        run git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        if [ "$DRY" = 1 ]; then info "(dry-run) would build yay in $tmp/yay"
        else (cd "$tmp/yay" && makepkg -si --noconfirm); fi
    fi

    step "AUR packages"
    run yay -S --needed tokyonight-gtk-theme-git bibata-cursor-theme-bin papirus-folders wlogout

    step "Verifying"
    if [ "$DRY" = 0 ]; then
        local missing=()
        for p in "${pkgs[@]}" tokyonight-gtk-theme-git bibata-cursor-theme-bin papirus-folders wlogout; do
            pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p")
        done
        [ ${#missing[@]} -eq 0 ] && ok "all packages installed" || die "not installed: ${missing[*]}"
    fi
}

stage_dotfiles() {
    step "Dotfiles → $HOME"
    [ -d "$FILES" ] || die "missing $FILES"
    local n=0 rel dest
    while IFS= read -r -d '' src; do
        rel=${src#"$FILES"/}
        case "$rel" in Documents/*) continue ;; esac      # plans are reference only
        dest="$HOME/$rel"
        install_file "$src" "$dest"
        n=$((n + 1))
    done < <(find "$FILES" -type f -print0)
    ok "$n files in place"

    # files were captured on a machine where HOME=/home/adham; fix paths for other users
    if [ "$HOME" != /home/adham ]; then
        step "Rewriting /home/adham → $HOME in copied files"
        local f
        while IFS= read -r f; do run sed -i "s|/home/adham|$HOME|g" "$f"; info "$f"; done < <(
            grep -rl /home/adham "$HOME/.config" "$HOME/.local/share/boot-theme" "$HOME/.local/share/sddm-themes" \
                "$HOME/.local/bin" "$HOME/.bashrc" 2>/dev/null || true)
    fi

    step "Making scripts executable"
    run chmod +x "$HOME/.local/bin/screenshot" "$HOME/.local/bin/minimized" "$HOME/.local/bin/emulator" \
        "$HOME/.config/waybar/scripts/kb-layout.py" "$HOME/.config/swaync/scripts/"*.sh \
        "$HOME/.local/share/boot-theme/"*.sh

    step "Linking libadwaita (GTK4) to Tokyonight-Dark"
    local f
    for f in gtk.css gtk-dark.css assets; do
        run ln -sfn "/usr/share/themes/Tokyonight-Dark/gtk-4.0/$f" "$HOME/.config/gtk-4.0/$f"
    done
}

stage_wallpaper() {
    step "Wallpaper (divergence meter)"
    local W="$HOME/Pictures/wallpapers"
    have rsvg-convert || die "rsvg-convert missing (pacman -S librsvg)"
    run mkdir -p "$W/src"
    if [ "$DRY" = 1 ]; then info "(dry-run) would render $W/steins-gate-divergence.png"
    else
        python3 "$W/src/divergence.py" > "$W/src/divergence.svg"
        rsvg-convert -w 1920 -h 1080 "$W/src/divergence.svg" -o "$W/steins-gate-divergence.png"
    fi
    ok "$W/steins-gate-divergence.png"

    step "Reusing it for SDDM and the Chrome new tab page"
    run mkdir -p "$HOME/.local/share/sddm-themes/steins-gate" "$HOME/.local/share/chrome-themes/tokyo-night-steins-gate/images"
    run cp "$W/steins-gate-divergence.png" "$HOME/.local/share/sddm-themes/steins-gate/background.png"
    run cp "$W/steins-gate-divergence.png" "$HOME/.local/share/chrome-themes/tokyo-night-steins-gate/images/ntp_background.png"
}

stage_theming() {
    step "GTK / icons / cursor / fonts (gsettings)"
    run gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'
    run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    run gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    run gsettings set org.gnome.desktop.interface cursor-size 24
    run gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
    run gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    step "Papirus folder colour (indigo)"
    if have papirus-folders; then run sudo papirus-folders -C indigo --theme Papirus-Dark
    else warn "papirus-folders not installed — skipped"; fi

    step "Fontconfig (Arabic → Noto Naskh)"
    run fc-cache -f

    step "bat Tokyo Night theme"
    run mkdir -p "$HOME/.config/bat/themes"
    run curl -fsSL -o "$HOME/.config/bat/themes/tokyonight_night.tmTheme" \
        https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
    run bat cache --build

    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        step "Applying to the running Hyprland session"
        run hyprctl setcursor Bibata-Modern-Ice 24
        run hyprctl reload
        if [ "$DRY" = 0 ]; then
            if [ -z "$(hyprctl configerrors)" ]; then ok "hyprctl configerrors: none"
            else warn "config errors: $(hyprctl configerrors)"; fi
        fi
    else
        info "Hyprland not running — changes apply at next login"
    fi
}

stage_services() {
    step "Bluetooth"
    run sudo systemctl enable --now bluetooth
    run gsettings set org.blueman.general plugin-list "['!StatusNotifierItem']"   # no duplicate tray icon
}

stage_sddm() {
    step "SDDM login theme"
    local T="$HOME/.local/share/sddm-themes/steins-gate"
    [ -f "$T/background.png" ] || warn "no background.png yet — run the 'wallpaper' stage first"
    run sudo cp -r "$T" /usr/share/sddm/themes/
    run sudo install -Dm644 "$HOME/.local/share/sddm-themes/10-steins-gate.conf" /etc/sddm.conf.d/10-steins-gate.conf
    run sudo systemctl enable sddm
    ok "SDDM enabled — takes effect on next boot (rollback: Ctrl+Alt+F2 → sudo systemctl disable sddm)"
}

stage_boot() {
    step "Boot theming (GRUB + Plymouth)"
    warn "This edits /etc/default/grub and /etc/mkinitcpio.conf and rebuilds the initramfs."
    if [ "$DRY" = 0 ]; then
        read -r -p "  Continue? [y/N] " a; [[ $a =~ ^[Yy]$ ]] || { info "skipped"; return 0; }
    fi
    local B="$HOME/.local/share/boot-theme" G="$HOME/.local/share/boot-theme/grub/steins-gate"
    local scratch; scratch=$(mktemp -d)

    step "Safety net: backup + btrfs snapshot"
    if findmnt -no FSTYPE / | grep -q btrfs && [ -d /.snapshots ]; then
        run sudo bash "$B/1-backup.sh"
    else
        warn "root is not btrfs or /.snapshots missing — copying boot files only"
        run sudo mkdir -p "/root/boot-backup-$STAMP"
        run sudo cp -a /etc/default/grub /etc/mkinitcpio.conf /boot/grub/grub.cfg "/root/boot-backup-$STAMP/"
    fi

    step "GRUB theme assets"
    run mkdir -p "$G"
    if [ "$DRY" = 0 ]; then
        python3 "$HOME/Pictures/wallpapers/src/divergence.py" --no-caption --y-shift=-170 > "$scratch/bg.svg"
        rsvg-convert -w 1920 -h 1080 "$scratch/bg.svg" -o "$G/background.png"
        local F=/usr/share/fonts/TTF/JetBrainsMonoNerdFont
        local R='0x20-0x7E,0xA0-0xFF,0x2010-0x2027,0x2190-0x21FF,0x2500-0x257F,0x25A0-0x25FF'
        grub-mkfont -r "$R" -s 16 -o "$G/jbm-regular-16.pf2" "$F-Regular.ttf" 2>/dev/null
        grub-mkfont -r "$R" -s 24 -o "$G/jbm-regular-24.pf2" "$F-Regular.ttf" 2>/dev/null
        grub-mkfont -r "$R" -s 24 -o "$G/jbm-bold-24.pf2"    "$F-Bold.ttf"    2>/dev/null
        local fill="fill='#7aa2f7' fill-opacity='0.18' stroke='#7aa2f7' stroke-opacity='0.85' stroke-width='2'"
        echo "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='48'><path d='M16,1 H15 A14,14 0 0 0 1,15 V33 A14,14 0 0 0 15,47 H16' $fill/></svg>" > "$scratch/w.svg"
        echo "<svg xmlns='http://www.w3.org/2000/svg' width='8' height='48'><rect x='0' y='1' width='8' height='46' fill='#7aa2f7' fill-opacity='0.18'/><line x1='0' y1='1' x2='8' y2='1' stroke='#7aa2f7' stroke-opacity='0.85' stroke-width='2'/><line x1='0' y1='47' x2='8' y2='47' stroke='#7aa2f7' stroke-opacity='0.85' stroke-width='2'/></svg>" > "$scratch/c.svg"
        echo "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='48'><path d='M0,1 H1 A14,14 0 0 1 15,15 V33 A14,14 0 0 1 1,47 H0' $fill/></svg>" > "$scratch/e.svg"
        for s in w c e; do rsvg-convert "$scratch/$s.svg" -o "$G/select_$s.png"; done
    else info "(dry-run) would render background.png, 3 pf2 fonts, select_{w,c,e}.png"; fi

    step "Plymouth theme assets"
    run python3 "$B/plymouth/render_assets.py"

    step "Installing themes"
    run sudo rm -rf /boot/grub/themes/steins-gate /usr/share/plymouth/themes/steins-gate
    run sudo cp -r "$G" /boot/grub/themes/
    run sudo cp -r "$B/plymouth/steins-gate" /usr/share/plymouth/themes/
    run sudo install -Dm644 "$B/etc/plymouthd.conf" /etc/plymouth/plymouthd.conf

    step "Editing /etc/default/grub (in place)"
    run sudo sed -i -E '/^GRUB_CMDLINE_LINUX_DEFAULT=/{ /splash/! s/"$/ splash"/; /plymouth\.use-simpledrm/! s/"$/ plymouth.use-simpledrm"/ }' /etc/default/grub
    run sudo sed -i -E 's/^#?GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
    if grep -q '^GRUB_THEME=' /etc/default/grub; then
        run sudo sed -i -E 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/steins-gate/theme.txt"|' /etc/default/grub
    else
        run sudo sh -c 'printf "\n# Tokyo Night × Steins;Gate\nGRUB_THEME=\"/boot/grub/themes/steins-gate/theme.txt\"\n" >> /etc/default/grub'
    fi

    step "Adding the plymouth hook to /etc/mkinitcpio.conf"
    if grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then ok "already present"
    elif grep -qE '^HOOKS=\(.*\bsystemd\b' /etc/mkinitcpio.conf; then
        run sudo sed -i -E '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' /etc/mkinitcpio.conf
    else
        run sudo sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
    fi

    step "Rebuilding initramfs + grub.cfg"
    run sudo mkinitcpio -P
    run sudo grub-mkconfig -o /boot/grub/grub.cfg

    step "Verifying"
    if [ "$DRY" = 0 ]; then
        grub-script-check /boot/grub/grub.cfg && ok "grub.cfg syntax"
        grep -q 'set theme=' /boot/grub/grub.cfg && ok "grub.cfg loads a theme" || warn "no theme line in grub.cfg"
        grep -q 'splash' /boot/grub/grub.cfg && ok "kernel cmdline has splash" || warn "splash missing"
        [ "$(plymouth-set-default-theme)" = steins-gate ] && ok "plymouth theme: steins-gate" || warn "plymouth theme not set"
        lsinitcpio /boot/initramfs-linux.img | grep -q 'plymouth/themes/steins-gate/steins-gate.script' \
            && ok "theme is inside the initramfs" || warn "theme missing from initramfs"
    fi
    rm -rf "$scratch"
    ok "Reboot to see GRUB → splash → SDDM. Rollback: restore /root/boot-backup-* and rebuild."
}

# ------------------------------------------------------------------ main
[ "$(id -u)" -ne 0 ] || die "run as your normal user (sudo is used where needed)"
[ -f /etc/arch-release ] || warn "this doesn't look like Arch Linux"

stages=()
for a in "$@"; do
    case "$a" in
        --dry-run|-n) DRY=1 ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        all) stages+=(packages dotfiles wallpaper theming services sddm) ;;
        packages|dotfiles|wallpaper|theming|services|sddm|boot) stages+=("$a") ;;
        *) die "unknown stage '$a' (see --help)" ;;
    esac
done
[ ${#stages[@]} -gt 0 ] || stages=(packages dotfiles wallpaper theming services sddm)
[ "$DRY" = 1 ] && warn "DRY RUN — nothing will be changed"

for s in "${stages[@]}"; do "stage_$s"; done

step "Done"
cat <<EOF
  Still manual (see the chapters):
  · Monitors: hyprland.lua uses eDP-1 / HDMI-A-1 — check yours with: hyprctl monitors all   (07)
  · Chrome theme: chrome://extensions → Developer mode → Load unpacked →
      $HOME/.local/share/chrome-themes/tokyo-night-steins-gate                              (04)
  · Boot theming is separate: ./install.sh boot                                              (09)
  · Log out and back in (or reboot) to load everything.
EOF
