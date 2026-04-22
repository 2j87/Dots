#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║          kerem-hyprland-dots — Kurulum Scripti v1.0.0              ║
# ║          Hyprland + Caelestia Shell :: Arch Linux                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Kullanım:
#   ./install.sh           → tam kurulum (paketler + config)
#   ./install.sh --update  → sadece config dosyalarını güncelle
#   ./install.sh --deps    → sadece paketleri kur
#   ./install.sh --help    → bu yardım mesajı

set -euo pipefail

# ── RENKLER ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()   { echo -e "${BLUE}[INFO]${RESET}  $*"; }
ok()     { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()  { echo -e "${RED}[HATA]${RESET}  $*" >&2; }
header() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }
die()    { error "$*"; exit 1; }

confirm() {
    echo -en "${YELLOW}[?]${RESET}    $1 ${BOLD}[e/h]${RESET}: "
    read -r ans
    [[ "$ans" =~ ^[Ee]$ ]]
}

# ── DEĞİŞKENLER ───────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
MODE="full"

for arg in "$@"; do
    case "$arg" in
        --update) MODE="update" ;;
        --deps)   MODE="deps"   ;;
        --help|-h)
            echo "Kullanım: ./install.sh [--update|--deps|--help]"
            echo "  (argümansız)  Tam kurulum (paketler + config)"
            echo "  --update      Sadece config dosyalarını güncelle"
            echo "  --deps        Sadece paketleri kur"
            exit 0 ;;
        *) warn "Bilinmeyen argüman: $arg — yoksayılıyor" ;;
    esac
done

# ── BANNER ────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ██╗  ██╗██╗   ██╗██████╗ ██████╗     ██████╗  ██████╗ ████████╗███████╗"
echo "  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝"
echo "  ███████║ ╚████╔╝ ██████╔╝██████╔╝    ██║  ██║██║   ██║   ██║   ███████╗"
echo "  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗    ██║  ██║██║   ██║   ██║   ╚════██║"
echo "  ██║  ██║   ██║   ██║     ██║  ██║    ██████╔╝╚██████╔╝   ██║   ███████║"
echo "  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝"
echo ""
echo "  Hyprland + Caelestia Shell :: Arch Linux Kurulum Scripti"
echo -e "${RESET}"
echo -e "  Mod: ${BOLD}$MODE${RESET} | Repo: ${BOLD}$REPO_DIR${RESET}"
echo ""

# Arch kontrolü
command -v pacman &>/dev/null || die "Bu script sadece Arch Linux için yazılmıştır."
[[ $EUID -eq 0 ]] && die "Root olarak çalıştırma. Normal kullanıcı olarak çalıştır."

# ════════════════════════════════════════════════════════════════════════
install_deps() {
    header "Sistem Paketleri Kuruluyor"

    local pacman_pkgs=(
        hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        hyprpicker hypridle hyprlock hyprpaper
        pipewire pipewire-pulse wireplumber
        networkmanager nm-connection-editor
        brightnessctl ddcutil lm-sensors
        libcava libqalculate libnotify
        grim slurp swappy
        wl-clipboard cliphist fuzzel glib2
        fish inotify-tools trash-cli jq
        polkit-gnome
        qt6-base qt6-declarative
        foot thunar pavucontrol mpv
        btop fastfetch starship
        eza bat
        adw-gtk-theme papirus-icon-theme
        base-devel git cmake ninja
    )

    info "Pacman güncellemesi..."
    sudo pacman -Syu --noconfirm

    local to_install=()
    for pkg in "${pacman_pkgs[@]}"; do
        pacman -Qi "$pkg" &>/dev/null && ok "$pkg zaten kurulu" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
        ok "Pacman paketleri kuruldu"
    fi

    # yay
    header "AUR Helper (yay)"
    if ! command -v yay &>/dev/null; then
        info "yay derleniyor..."
        local tmp; tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        cd "$tmp/yay" && makepkg -si --noconfirm && cd "$REPO_DIR"
        rm -rf "$tmp"
        ok "yay kuruldu"
    else
        ok "yay zaten mevcut"
    fi

    # AUR paketleri — SIRA KRİTİK
    header "AUR Paketleri (sırayla)"
    local aur_pkgs=(
        quickshell-git
        caelestia-shell
        caelestia-cli
        ttf-material-symbols-variable-git
        ttf-caskaydia-cove-nerd
        papirus-folders
        gpu-screen-recorder
        app2unit
        aubio
    )

    for pkg in "${aur_pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            info "AUR: $pkg kuruluyor..."
            yay -S --noconfirm --needed "$pkg"
            ok "$pkg kuruldu"
        else
            ok "$pkg zaten kurulu"
        fi
    done
}

# ════════════════════════════════════════════════════════════════════════
backup_existing() {
    header "Mevcut Config Yedekleniyor"
    local backed_up=false

    for dir in hypr caelestia; do
        local target="$CONFIG_HOME/$dir"
        if [[ -d "$target" ]]; then
            [[ "$backed_up" == false ]] && mkdir -p "$BACKUP_DIR" && backed_up=true
            cp -r "$target" "$BACKUP_DIR/$dir"
            ok "$target → $BACKUP_DIR/$dir"
        fi
    done

    [[ "$backed_up" == false ]] && info "Yedeklenecek mevcut config yok"
}

# ════════════════════════════════════════════════════════════════════════
install_configs() {
    header "Config Dosyaları Yerleştiriliyor"

    # Hyprland
    mkdir -p "$CONFIG_HOME/hypr"
    cp -r "$REPO_DIR/hypr/." "$CONFIG_HOME/hypr/"
    ok "~/.config/hypr güncellendi"

    # scheme/current.conf — yedek varsa koru (caelestia'nın ayarı)
    if [[ -f "$BACKUP_DIR/hypr/scheme/current.conf" ]]; then
        mkdir -p "$CONFIG_HOME/hypr/scheme"
        cp "$BACKUP_DIR/hypr/scheme/current.conf" "$CONFIG_HOME/hypr/scheme/current.conf"
        ok "scheme/current.conf korundu"
    fi

    # Caelestia
    mkdir -p "$CONFIG_HOME/caelestia"

    for f in shell.json cli.json; do
        local src="$REPO_DIR/caelestia/$f"
        local dst="$CONFIG_HOME/caelestia/$f"
        if [[ -f "$src" ]]; then
            if [[ -f "$dst" && "$MODE" == "update" ]]; then
                warn "$f zaten var — --update modunda korunuyor"
                warn "Farkları görmek için: diff $src $dst"
            else
                cp "$src" "$dst"
                ok "$f yerleştirildi"
            fi
        fi
    done

    # hypr-user.conf — yoksa boş oluştur
    local user_conf="$CONFIG_HOME/caelestia/hypr-user.conf"
    if [[ ! -f "$user_conf" ]]; then
        if [[ -f "$REPO_DIR/caelestia/hypr-user.conf" ]]; then
            cp "$REPO_DIR/caelestia/hypr-user.conf" "$user_conf"
        else
            cat > "$user_conf" << 'EOF'
# ~/.config/caelestia/hypr-user.conf
# Caelestia üzerinden Hyprland'a eklenen kişisel tweakler.
# Upstream hyprland config'i bu dosyayı source eder.
#
# Örnek: ekran titremesi için
# misc {
#     vrr = 0
# }
EOF
        fi
        ok "hypr-user.conf oluşturuldu"
    else
        ok "hypr-user.conf zaten var — korunuyor"
    fi

    # Starship
    if [[ -f "$REPO_DIR/starship.toml" ]]; then
        if [[ -f "$HOME/.config/starship.toml" && "$MODE" == "update" ]]; then
            warn "starship.toml zaten var — --update modunda korunuyor"
            warn "Farkları görmek için: diff $REPO_DIR/starship.toml $HOME/.config/starship.toml"
        else
            cp "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
            ok "starship.toml yerleştirildi"
        fi
    fi

    # Fastfetch
    if [[ -d "$REPO_DIR/fastfetch" ]]; then
        mkdir -p "$CONFIG_HOME/fastfetch"
        # Mevcut backup varsa koru
        [[ -f "$CONFIG_HOME/fastfetch/config.jsonc" ]] && \
            cp "$CONFIG_HOME/fastfetch/config.jsonc" "$CONFIG_HOME/fastfetch/config.jsonc.backup" 2>/dev/null || true
        cp -r "$REPO_DIR/fastfetch/." "$CONFIG_HOME/fastfetch/"
        ok "fastfetch config yerleştirildi"
    fi

    # Fish — caelestia entegrasyonu
    if [[ -d "$REPO_DIR/fish" ]]; then
        mkdir -p "$CONFIG_HOME/fish/conf.d"
        cp -r "$REPO_DIR/fish/." "$CONFIG_HOME/fish/"
        ok "fish/conf.d/caelestia.fish yerleştirildi"
    fi

    # Script izinleri
    chmod +x "$CONFIG_HOME/hypr/scripts/"*.sh 2>/dev/null || true
    ok "Script izinleri ayarlandı"

    # Wallpaper dizini
    mkdir -p "$HOME/Pictures/Wallpapers"
    ok "~/Pictures/Wallpapers hazır"

    [[ ! -f "$HOME/.face" ]] && \
        warn "~/.face bulunamadı — Dashboard profil resmi için: cp resim.jpg ~/.face"
}

# ════════════════════════════════════════════════════════════════════════
install_sddm() {
    header "SDDM + sddm-astronaut-theme Kuruluyor"

    # SDDM bağımlılıkları
    local sddm_pkgs=(sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg)
    local to_install=()
    for pkg in "${sddm_pkgs[@]}"; do
        pacman -Qi "$pkg" &>/dev/null && ok "$pkg zaten kurulu" || to_install+=("$pkg")
    done
    [[ ${#to_install[@]} -gt 0 ]] && sudo pacman -S --noconfirm --needed "${to_install[@]}"

    # sddm-astronaut-theme kur
    local theme_dir="/usr/share/sddm/themes/sddm-astronaut-theme"
    if [[ ! -d "$theme_dir" ]]; then
        info "sddm-astronaut-theme indiriliyor..."
        sudo git clone -b master --depth 1 \
            https://github.com/Keyitdev/sddm-astronaut-theme.git \
            "$theme_dir"
        ok "sddm-astronaut-theme kuruldu"
    else
        info "sddm-astronaut-theme güncelleniyor..."
        sudo git -C "$theme_dir" pull
        ok "sddm-astronaut-theme güncellendi"
    fi

    # Fontları kopyala
    sudo cp -r "$theme_dir/Fonts/"* /usr/share/fonts/ 2>/dev/null || true
    ok "Tema fontları kopyalandı"

    # Özelleştirilmiş black_hole temasını kopyala
    if [[ -f "$REPO_DIR/sddm/theme.conf" ]]; then
        sudo cp "$REPO_DIR/sddm/theme.conf" "$theme_dir/Themes/black_hole.conf"
        ok "Özelleştirilmiş black_hole.conf yerleştirildi"
    fi

    # metadata.desktop — black_hole temasını aktifleştir
    echo "ConfigFile=Themes/black_hole.conf" | \
        sudo tee -a "$theme_dir/metadata.desktop" > /dev/null
    ok "black_hole teması aktifleştirildi"

    # SDDM konfigürasyonları
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$REPO_DIR/sddm/sddm.conf"     /etc/sddm.conf
    sudo cp "$REPO_DIR/sddm/virtualkbd.conf" /etc/sddm.conf.d/virtualkbd.conf
    ok "SDDM konfigürasyonları yerleştirildi"

    # SDDM servisini etkinleştir
    sudo systemctl enable sddm
    ok "SDDM servisi etkinleştirildi"

    warn "Önizleme için (Hyprland içinden):"
    warn "  sddm-greeter-qt6 --test-mode --theme $theme_dir"
}

configure_services() {
    header "Servisler Yapılandırılıyor"

    systemctl is-enabled --quiet NetworkManager 2>/dev/null || \
        sudo systemctl enable --now NetworkManager
    ok "NetworkManager aktif"

    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
        warn "Pipewire servisleri — oturumu yeniden başlatınca otomatik başlar"
    ok "Ses servisleri yapılandırıldı"

    if command -v papirus-folders &>/dev/null; then
        local sf="/etc/sudoers.d/papirus-folders"
        if [[ ! -f "$sf" ]] && confirm "papirus-folders için sudoers ayarı yapılsın mı?"; then
            echo "$USER ALL=(ALL) NOPASSWD: $(which papirus-folders)" | sudo tee "$sf" > /dev/null
            sudo chmod 440 "$sf"
            ok "papirus-folders sudoers ayarlandı"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════
post_install_check() {
    header "Son Kontrol"

    local issues=0
    chk_cmd() { command -v "$1" &>/dev/null && ok "$1 ✓" || { warn "$1 ✗"; ((issues++)) || true; }; }
    chk_file() { [[ -f "$1" ]] && ok "$1 ✓" || { warn "$1 eksik ✗"; ((issues++)) || true; }; }

    echo "Komutlar:"
    for cmd in hyprland caelestia qs fish foot hypridle hyprlock hyprpaper \
               brightnessctl grim slurp fuzzel cliphist; do
        chk_cmd "$cmd"
    done

    echo ""
    echo "Config dosyaları:"
    for f in \
        "$CONFIG_HOME/hypr/hyprland.conf" \
        "$CONFIG_HOME/hypr/core/env.conf" \
        "$CONFIG_HOME/hypr/input/binds.conf" \
        "$CONFIG_HOME/hypr/visual/decoration.conf" \
        "$CONFIG_HOME/caelestia/shell.json" \
        "$CONFIG_HOME/caelestia/cli.json"; do
        chk_file "$f"
    done

    echo ""
    echo "Fontlar:"
    fc-list | grep -qi "material symbols" && ok "Material Symbols ✓" || { warn "Material Symbols ✗ — ikonlar bozuk görünecek"; ((issues++)) || true; }
    fc-list | grep -qi "caskaydia"        && ok "CaskaydiaCove NF ✓"  || { warn "CaskaydiaCove NF ✗"; ((issues++)) || true; }

    echo ""
    [[ $issues -eq 0 ]] \
        && ok "Tüm kontroller geçti — kurulum başarılı! 🎉" \
        || warn "$issues sorun var — yukarıdaki uyarıları incele"
}

# ════════════════════════════════════════════════════════════════════════
print_next_steps() {
    echo ""
    echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Kurulum tamamlandı! Sıradaki adımlar:${RESET}"
    echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════${RESET}"
    cat << EOF

  1. Monitörü tanımla:
       hyprctl monitors
       # Çıktıdaki ismi ~/.config/hypr/core/monitor.conf'a yaz

  2. Hyprland'ı başlat:
       Hyprland

  3. Wallpaper ve tema:
       caelestia wallpaper -f ~/Pictures/Wallpapers/resim.jpg
       caelestia scheme set -n dynamic

  4. Foot terminal teması (caelestia kendi config'ini sağlar):
       git clone https://github.com/caelestia-dots/caelestia.git /tmp/caelestia
       cp -r /tmp/caelestia/foot ~/.config/foot

  5. Profil resmi (dashboard için):
       cp resim.jpg ~/.face

  5. Sorun giderme:
       RELEASE_NOTES.md dosyasını oku
       journalctl --user -xe | grep caelestia

EOF
}

# ════════════════════════════════════════════════════════════════════════
main() {
    case "$MODE" in
        full)
            install_deps
            backup_existing
            install_configs
            install_sddm
            configure_services
            post_install_check
            print_next_steps
            ;;
        update)
            backup_existing
            install_configs
            post_install_check
            ok "--update tamamlandı. Paketler güncellenmedi."
            ;;
        deps)
            install_deps
            ok "--deps tamamlandı. Config dosyaları kopyalanmadı."
            ;;
    esac
}

main
