#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║     kerem-hyprland-dots — Arch Kurulum Scripti                     ║
# ║     Sıfır Arch → Hyprland + Caelestia Shell                        ║
# ║                                                                    ║
# ║     Sistem: Arch Linux                                             ║
# ║     GPU:    NVIDIA + Intel (Optimus/hybrid)                        ║
# ║     Disk:   btrfs + swapfile (ayrı Linux SSD)                     ║
# ║     Boot:   GRUB (dual boot — Windows ayrı SSD'de)                ║
# ║                                                                    ║
# ║     KULLANIM:                                                      ║
# ║     AŞAMA 1 — Arch ISO'dan: ./arch-install.sh chroot              ║
# ║     AŞAMA 2 — chroot içinde: ./arch-install.sh system             ║
# ║     AŞAMA 3 — ilk boot sonrası: ./arch-install.sh desktop         ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── RENKLER ───────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()   { echo -e "${BLUE}[-->]${RESET} $*"; }
ok()     { echo -e "${GREEN}[ ✓ ]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[ ! ]${RESET} $*"; }
error()  { echo -e "${RED}[ERR]${RESET} $*" >&2; }
header() { echo -e "\n${BOLD}${CYAN}━━━━━━ $* ━━━━━━${RESET}"; }
die()    { error "$*"; exit 1; }

confirm() {
    echo -en "${YELLOW}[?]${RESET} $1 ${BOLD}[e/h]${RESET}: "
    read -r ans; [[ "$ans" =~ ^[Ee]$ ]]
}

ask() {
    echo -en "${CYAN}[>]${RESET} $1: "
    read -r REPLY; echo "$REPLY"
}

# ════════════════════════════════════════════════════════════════════════
# KONFİGÜRASYON — BURAYA BAK
# ════════════════════════════════════════════════════════════════════════
# Bu değerleri kendi sistemine göre doldur.
# Disk adını bulmak için: lsblk

DISK=""            # Linux SSD — örn: /dev/nvme1n1 veya /dev/sdb
                   # Windows SSD'ye DOKUNMA
HOSTNAME="kerem-arch"
USERNAME="kerem"
TIMEZONE="Europe/Istanbul"
LOCALE="tr_TR.UTF-8"
KEYMAP="trq"       # Türkçe Q klavye için Arch console keymap

SWAP_SIZE="8G"     # 16GB RAM için 8GB swap yeterli
BTRFS_OPTS="noatime,compress=zstd:1,space_cache=v2"

REPO_URL="https://github.com/hkrclng/kerem-hyprland-dots"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ════════════════════════════════════════════════════════════════════════
banner() {
    echo -e "${BOLD}${CYAN}"
    echo "  ┌─────────────────────────────────────────────────────┐"
    echo "  │   Arch Linux Kurulum Scripti — kerem-hyprland-dots  │"
    echo "  │   GPU: NVIDIA+Intel Hybrid  │  FS: btrfs  │  GRUB   │"
    echo "  └─────────────────────────────────────────────────────┘"
    echo -e "${RESET}"
}

# ════════════════════════════════════════════════════════════════════════
# AŞAMA 1: CHROOT HAZIRLIĞI
# Arch ISO'dan çalıştırılır. Diski hazırlar, base sistemi kurar, chroot'a girer.
# ════════════════════════════════════════════════════════════════════════
stage_chroot() {
    banner
    header "AŞAMA 1: Disk Hazırlığı ve Base Kurulum"

    # DISK kontrolü
    if [[ -z "$DISK" ]]; then
        echo "Mevcut diskler:"
        lsblk -d -o NAME,SIZE,MODEL
        echo ""
        DISK=$(ask "Linux SSD'nin adını gir (örn: /dev/nvme1n1)")
    fi

    [[ -b "$DISK" ]] || die "$DISK bulunamadı veya geçerli bir disk değil"
    warn "DİKKAT: $DISK üzerindeki TÜM VERİ SİLİNECEK!"
    warn "Windows SSD'sine DOKUNULMUYOR."
    confirm "Devam etmek istiyor musun?" || die "İptal edildi."

    # ── BÖLÜMLEME ─────────────────────────────────────────────────────
    header "Disk Bölümleme: $DISK"
    # GPT tablosu
    # /dev/Xp1 → EFI  (512MB)
    # /dev/Xp2 → root (kalan tüm alan, btrfs)

    info "GPT partition tablosu oluşturuluyor..."
    parted -s "$DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 513MiB \
        set 1 esp on \
        mkpart root btrfs 513MiB 100%

    # Partition adlarını belirle (nvme ve sata farklı)
    if [[ "$DISK" == *nvme* ]]; then
        EFI="${DISK}p1"
        ROOT="${DISK}p2"
    else
        EFI="${DISK}1"
        ROOT="${DISK}2"
    fi

    partprobe "$DISK"
    sleep 2
    ok "Bölümleme tamamlandı: EFI=$EFI  ROOT=$ROOT"

    # ── FORMAT ────────────────────────────────────────────────────────
    header "Formatlama"
    info "EFI formatlıyor (FAT32)..."
    mkfs.fat -F32 -n "EFI" "$EFI"

    info "Root formatlıyor (btrfs)..."
    mkfs.btrfs -L "archlinux" -f "$ROOT"
    ok "Formatlama tamamlandı"

    # ── BTRFS SUBVOLUME'LAR ───────────────────────────────────────────
    header "btrfs Subvolume Yapısı"
    # Modern btrfs layout — @ ana, @home, @var, @snapshots, @swap
    mount "$ROOT" /mnt

    info "Subvolume'lar oluşturuluyor..."
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@swap

    umount /mnt

    # ── MOUNT ─────────────────────────────────────────────────────────
    header "Mount Noktaları"
    info "Root mount ediliyor..."
    mount -o "$BTRFS_OPTS,subvol=@" "$ROOT" /mnt

    mkdir -p /mnt/{home,var,.snapshots,swap,boot/efi}

    mount -o "$BTRFS_OPTS,subvol=@home"      "$ROOT" /mnt/home
    mount -o "$BTRFS_OPTS,subvol=@var"       "$ROOT" /mnt/var
    mount -o "$BTRFS_OPTS,subvol=@snapshots" "$ROOT" /mnt/.snapshots

    # Swap subvolume — CoW KAPALI (btrfs swapfile için zorunlu)
    mount -o "noatime,subvol=@swap" "$ROOT" /mnt/swap
    chattr +C /mnt/swap   # Copy-on-Write devre dışı

    mount "$EFI" /mnt/boot/efi

    ok "Mount tamamlandı"
    lsblk "$DISK"

    # ── SWAPFILE ──────────────────────────────────────────────────────
    header "Swapfile ($SWAP_SIZE)"
    info "Swapfile oluşturuluyor..."
    btrfs filesystem mkswapfile --size "$SWAP_SIZE" /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
    ok "Swapfile aktif"

    # ── PACSTRAP ──────────────────────────────────────────────────────
    header "Base Sistem Kurulumu (pacstrap)"

    info "Mirror listesi güncelleniyor..."
    reflector --country Turkey,Germany --age 12 --protocol https \
              --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || \
        warn "reflector başarısız — varsayılan mirrorlar kullanılacak"

    info "Base paketler kuruluyor..."
    pacstrap -K /mnt \
        base base-devel linux linux-firmware linux-headers \
        btrfs-progs grub efibootmgr os-prober \
        networkmanager network-manager-applet \
        intel-ucode \
        sudo vim nano git curl wget \
        pipewire pipewire-pulse wireplumber \
        reflector

    ok "Base sistem kuruldu"

    # ── FSTAB ─────────────────────────────────────────────────────────
    header "fstab Oluşturuluyor"
    genfstab -U /mnt >> /mnt/etc/fstab
    ok "fstab oluşturuldu"
    cat /mnt/etc/fstab

    # ── SCRIPT'İ CHROOT'A KOPYALA ─────────────────────────────────────
    cp "$0" /mnt/root/arch-install.sh
    chmod +x /mnt/root/arch-install.sh

    info "Config'leri kopyalıyorum..."
    # Eğer repo klonlandıysa tüm repoyu kopyala
    if [[ -d "$SCRIPT_DIR/hypr" ]]; then
        cp -r "$SCRIPT_DIR" /mnt/root/kerem-hyprland-dots
    fi

    # ── CHROOT'A GEÇ ──────────────────────────────────────────────────
    header "chroot'a geçiliyor..."
    echo ""
    echo -e "${BOLD}${GREEN}  Şimdi chroot içinde çalışacaksın.${RESET}"
    echo -e "  Aşama 2'yi başlatmak için:"
    echo -e "  ${BOLD}  ./arch-install.sh system${RESET}"
    echo ""

    arch-chroot /mnt /root/arch-install.sh system
}

# ════════════════════════════════════════════════════════════════════════
# AŞAMA 2: SİSTEM YAPILANDIRMASI
# chroot içinde çalışır. Locale, kullanıcı, GRUB, NVIDIA kurulur.
# ════════════════════════════════════════════════════════════════════════
stage_system() {
    banner
    header "AŞAMA 2: Sistem Yapılandırması (chroot)"

    # ── ZAMAN DİLİMİ ──────────────────────────────────────────────────
    header "Zaman Dilimi"
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc
    ok "Zaman dilimi: $TIMEZONE"

    # ── LOCALE ────────────────────────────────────────────────────────
    header "Locale"
    sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
    sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    locale-gen

    echo "LANG=$LOCALE" > /etc/locale.conf
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    ok "Locale: $LOCALE"

    # ── HOSTNAME ──────────────────────────────────────────────────────
    header "Hostname"
    echo "$HOSTNAME" > /etc/hostname
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    ok "Hostname: $HOSTNAME"

    # ── ROOT ŞİFRESİ ──────────────────────────────────────────────────
    header "Root Şifresi"
    echo "Root şifresi belirle:"
    passwd

    # ── KULLANICI ─────────────────────────────────────────────────────
    header "Kullanıcı: $USERNAME"
    useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "$USERNAME"
    echo "$USERNAME şifresi belirle:"
    passwd "$USERNAME"

    # sudo — wheel grubuna izin ver
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    ok "Kullanıcı $USERNAME oluşturuldu (wheel grubu)"

    # ── mkinitcpio ────────────────────────────────────────────────────
    header "mkinitcpio"
    # btrfs modülü eklendi
    sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    ok "initramfs oluşturuldu"

    # ── NVIDIA DRIVER ─────────────────────────────────────────────────
    header "NVIDIA Driver (Optimus/hybrid)"
    info "NVIDIA paketleri kuruluyor..."
    pacman -S --noconfirm \
        nvidia nvidia-utils nvidia-settings \
        lib32-nvidia-utils \
        intel-media-driver \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        vulkan-icd-loader lib32-vulkan-icd-loader

    # NVIDIA DRM kernel parameter — Hyprland için zorunlu
    # mkinitcpio'ya nvidia modülleri ekle
    sed -i 's/^MODULES=(btrfs)/MODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
        /etc/mkinitcpio.conf

    # /etc/modprobe.d/nvidia.conf
    cat > /etc/modprobe.d/nvidia.conf << 'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

    # NVIDIA suspend/resume servisleri
    systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate 2>/dev/null || true

    mkinitcpio -P
    ok "NVIDIA driver yapılandırıldı"

    # ── GRUB ──────────────────────────────────────────────────────────
    header "GRUB (Dual Boot)"
    info "GRUB kuruluyor..."

    # os-prober'i etkinleştir (Windows'u bulsun)
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' \
        /etc/default/grub

    # NVIDIA DRM parametreleri GRUB'a ekle
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' \
        /etc/default/grub

    # GRUB install
    grub-install --target=x86_64-efi \
                 --efi-directory=/boot/efi \
                 --bootloader-id="Arch Linux" \
                 --recheck

    # os-prober çalıştır (Windows SSD'deki EFI'yi bulsun)
    os-prober

    # GRUB config oluştur
    grub-mkconfig -o /boot/grub/grub.cfg
    ok "GRUB kuruldu ve yapılandırıldı"

    # ── SERVİSLER ─────────────────────────────────────────────────────
    header "Sistem Servisleri"
    systemctl enable NetworkManager
    systemctl enable fstrim.timer    # SSD trim
    ok "Servisler etkinleştirildi"

    # ── YAY HAZIRLIĞI ─────────────────────────────────────────────────
    header "AUR Helper (yay) Hazırlığı"
    # yay'ı kullanıcı dizinine indir, aşama 3'te kurulacak
    su - "$USERNAME" -c "
        cd /home/$USERNAME
        git clone https://aur.archlinux.org/yay.git
    " || warn "yay clone başarısız — aşama 3'te tekrar denenecek"

    # ── TAMAMLANDI ────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${GREEN}  ════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${GREEN}  Aşama 2 tamamlandı!${RESET}"
    echo -e "${BOLD}${GREEN}  ════════════════════════════════════════════${RESET}"
    echo ""
    echo "  Şimdi şunları yap:"
    echo "  1. exit           (chroot'tan çık)"
    echo "  2. umount -R /mnt (mount noktalarını kapat)"
    echo "  3. reboot         (sistemi yeniden başlat)"
    echo ""
    echo "  İlk boot sonrası terminalde:"
    echo -e "  ${BOLD}~/kerem-hyprland-dots/arch-install.sh desktop${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# AŞAMA 3: MASAÜSTÜ KURULUMU
# İlk boot sonrası normal kullanıcı olarak çalıştırılır.
# Hyprland, Caelestia, SDDM ve tüm config dosyaları kurulur.
# ════════════════════════════════════════════════════════════════════════
stage_desktop() {
    banner
    header "AŞAMA 3: Masaüstü Kurulumu"

    [[ $EUID -eq 0 ]] && die "Bu aşamayı normal kullanıcı olarak çalıştır: $USERNAME"

    # ── YAY ───────────────────────────────────────────────────────────
    header "yay (AUR Helper)"
    if ! command -v yay &>/dev/null; then
        if [[ -d "$HOME/yay" ]]; then
            cd "$HOME/yay" && makepkg -si --noconfirm
            cd ~
        else
            info "yay klonlanıyor..."
            git clone https://aur.archlinux.org/yay.git "$HOME/yay"
            cd "$HOME/yay" && makepkg -si --noconfirm
            cd ~
        fi
        ok "yay kuruldu"
    else
        ok "yay zaten kurulu"
    fi

    # ── PACMAN PAKETLERİ ──────────────────────────────────────────────
    header "Sistem Paketleri"

    sudo pacman -Syu --noconfirm

    local pacman_pkgs=(
        # Hyprland ekosistemi
        hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        hyprpicker hypridle hyprlock hyprpaper

        # Ses
        pipewire pipewire-pulse wireplumber

        # Ağ
        networkmanager nm-connection-editor

        # Parlaklık
        brightnessctl ddcutil lm-sensors

        # Caelestia bağımlılıkları
        libcava libqalculate libnotify

        # Screenshot ve kayıt
        grim slurp swappy

        # Pano
        wl-clipboard cliphist fuzzel glib2

        # Sistem araçları
        fish inotify-tools trash-cli jq polkit-gnome

        # Qt6
        qt6-base qt6-declarative

        # SDDM
        sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg

        # Uygulamalar
        foot thunar pavucontrol mpv
        btop fastfetch starship
        eza bat

        # Tema
        adw-gtk-theme papirus-icon-theme

        # Geliştirme
        cmake ninja

        # NVIDIA Wayland
        egl-wayland
    )

    local to_install=()
    for pkg in "${pacman_pkgs[@]}"; do
        pacman -Qi "$pkg" &>/dev/null && ok "$pkg ✓" || to_install+=("$pkg")
    done

    [[ ${#to_install[@]} -gt 0 ]] && \
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
    ok "Pacman paketleri tamamlandı"

    # ── AUR PAKETLERİ ─────────────────────────────────────────────────
    header "AUR Paketleri (sıra kritik)"

    local aur_pkgs=(
        quickshell-git      # önce bu
        caelestia-shell     # sonra bu
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

    # ── NVIDIA ORTAM DEĞİŞKENLERİ ─────────────────────────────────────
    header "NVIDIA Ortam Ayarları"
    # env.conf'ta NVIDIA için gerekli değişkenler zaten mevcut
    # Ek olarak /etc/environment'a da ekle (SDDM için)
    cat | sudo tee -a /etc/environment << 'EOF'

# NVIDIA Optimus/Wayland
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
GBM_BACKEND=nvidia-drm
WLR_NO_HARDWARE_CURSORS=0
EOF
    ok "NVIDIA ortam değişkenleri ayarlandı"

    # ── REPO KOPYALA / ÇEKME ──────────────────────────────────────────
    header "Dotfiles"
    local dots_dir="$HOME/kerem-hyprland-dots"

    if [[ ! -d "$dots_dir" ]]; then
        info "Dotfiles repo klonlanıyor..."
        git clone "$REPO_URL" "$dots_dir"
    else
        info "Dotfiles güncelleniyor..."
        git -C "$dots_dir" pull
    fi
    ok "Dotfiles hazır: $dots_dir"

    # ── CONFIG DOSYALARINI YERLEŞTİR ──────────────────────────────────
    header "Config Dosyaları Yerleştiriliyor"
    local config="$HOME/.config"
    mkdir -p "$config"

    # Hyprland
    cp -r "$dots_dir/hypr" "$config/"
    ok "hypr config yerleştirildi"

    # Caelestia
    mkdir -p "$config/caelestia"
    for f in shell.json cli.json hypr-user.conf; do
        [[ -f "$dots_dir/caelestia/$f" ]] && \
            cp "$dots_dir/caelestia/$f" "$config/caelestia/$f" && ok "$f"
    done

    # Starship
    cp "$dots_dir/starship.toml" "$config/starship.toml" 2>/dev/null && ok "starship.toml"

    # Fastfetch
    mkdir -p "$config/fastfetch"
    cp -r "$dots_dir/fastfetch/." "$config/fastfetch/" 2>/dev/null && ok "fastfetch"

    # Fish
    mkdir -p "$config/fish/conf.d" "$config/fish/functions"
    cp -r "$dots_dir/fish/." "$config/fish/" 2>/dev/null && ok "fish"

    # Script izinleri
    chmod +x "$config/hypr/scripts/"*.sh 2>/dev/null || true

    # Dizinler
    mkdir -p "$HOME/Pictures/Wallpapers"
    ok "Dizinler oluşturuldu"

    # Caelestia foot config
    info "Caelestia foot config alınıyor..."
    git clone --depth 1 https://github.com/caelestia-dots/caelestia.git /tmp/caelestia 2>/dev/null || true
    [[ -d /tmp/caelestia/foot ]] && cp -r /tmp/caelestia/foot "$config/" && ok "foot config"

    # ── SDDM ──────────────────────────────────────────────────────────
    header "SDDM + sddm-astronaut-theme"

    local theme_dir="/usr/share/sddm/themes/sddm-astronaut-theme"

    if [[ ! -d "$theme_dir" ]]; then
        sudo git clone -b master --depth 1 \
            https://github.com/Keyitdev/sddm-astronaut-theme.git \
            "$theme_dir"
    else
        sudo git -C "$theme_dir" pull
    fi

    # Fontları kopyala
    sudo cp -r "$theme_dir/Fonts/"* /usr/share/fonts/ 2>/dev/null || true

    # Özelleştirilmiş tema
    [[ -f "$dots_dir/sddm/theme.conf" ]] && \
        sudo cp "$dots_dir/sddm/theme.conf" "$theme_dir/Themes/black_hole.conf"

    # metadata — black_hole aktif et
    sudo sed -i 's/ConfigFile=.*/ConfigFile=Themes\/black_hole.conf/' \
        "$theme_dir/metadata.desktop"

    # sddm.conf
    sudo cp "$dots_dir/sddm/sddm.conf" /etc/sddm.conf
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$dots_dir/sddm/virtualkbd.conf" /etc/sddm.conf.d/virtualkbd.conf

    sudo systemctl enable sddm
    ok "SDDM yapılandırıldı"

    # ── SERVİSLER ─────────────────────────────────────────────────────
    header "Servisler"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    sudo systemctl enable --now NetworkManager
    ok "Servisler etkinleştirildi"

    # papirus-folders sudoers
    if command -v papirus-folders &>/dev/null; then
        echo "$USER ALL=(ALL) NOPASSWD: $(which papirus-folders)" | \
            sudo tee /etc/sudoers.d/papirus-folders > /dev/null
        sudo chmod 440 /etc/sudoers.d/papirus-folders
        ok "papirus-folders sudoers"
    fi

    # ── VARSAYILAN SHELL ──────────────────────────────────────────────
    header "Varsayılan Shell"
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which fish)" ]]; then
        chsh -s "$(which fish)"
        ok "Varsayılan shell: fish"
    else
        ok "Varsayılan shell zaten fish"
    fi

    # ── SON KONTROL ───────────────────────────────────────────────────
    header "Son Kontrol"
    local issues=0

    chk() { command -v "$1" &>/dev/null && ok "$1 ✓" || { warn "$1 ✗"; ((issues++)) || true; }; }
    chkf() { [[ -f "$1" ]] && ok "$1 ✓" || { warn "$1 eksik"; ((issues++)) || true; }; }

    echo "Komutlar:"
    for cmd in hyprland caelestia qs fish foot sddm brightnessctl grim; do chk "$cmd"; done

    echo ""
    echo "Config dosyaları:"
    chkf "$config/hypr/hyprland.conf"
    chkf "$config/caelestia/shell.json"
    chkf "$config/starship.toml"

    echo ""
    echo "Fontlar:"
    fc-list | grep -qi "material symbols" && ok "Material Symbols ✓" || { warn "Material Symbols ✗"; ((issues++)) || true; }
    fc-list | grep -qi "caskaydia"        && ok "CaskaydiaCove NF ✓" || { warn "CaskaydiaCove NF ✗"; ((issues++)) || true; }

    # ── TAMAMLANDI ────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${GREEN}  ════════════════════════════════════════════════${RESET}"
    [[ $issues -eq 0 ]] \
        && echo -e "${BOLD}${GREEN}  Kurulum tamamlandı! 🎉${RESET}" \
        || echo -e "${BOLD}${YELLOW}  Kurulum tamamlandı ($issues uyarı)${RESET}"
    echo -e "${BOLD}${GREEN}  ════════════════════════════════════════════════${RESET}"
    echo ""
    echo "  Sıradaki adımlar:"
    echo "  1. reboot"
    echo "  2. SDDM ile giriş yap"
    echo "  3. Hyprland açılır → wallpaper ayarla:"
    echo "     caelestia wallpaper -f ~/Pictures/Wallpapers/resim.jpg"
    echo "     caelestia scheme set -n dynamic"
    echo "  4. ~/.config/hypr/core/monitor.conf güncelle:"
    echo "     hyprctl monitors"
    echo "  5. ~/.face için profil resmi koy:"
    echo "     cp resim.jpg ~/.face"
    echo ""
    echo "  SDDM önizleme için:"
    echo "    sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/"
    echo ""
    echo "  NVIDIA hybrid GPU — Wayland'da sorun yaşarsan:"
    echo "    ~/.config/hypr/core/env.conf dosyasını kontrol et"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# ANA AKIŞ
# ════════════════════════════════════════════════════════════════════════
case "${1:-help}" in
    chroot)  stage_chroot  ;;
    system)  stage_system  ;;
    desktop) stage_desktop ;;
    help|*)
        banner
        echo "  Kullanım:"
        echo ""
        echo "  AŞAMA 1 — Arch ISO'dan (root olarak):"
        echo "    ./arch-install.sh chroot"
        echo ""
        echo "  AŞAMA 2 — chroot içinde (otomatik başlar):"
        echo "    ./arch-install.sh system"
        echo ""
        echo "  AŞAMA 3 — İlk boot sonrası (normal kullanıcı):"
        echo "    ./arch-install.sh desktop"
        echo ""
        echo "  BAŞLAMADAN ÖNCE:"
        echo "    1. DISK değişkenini doldur (şu an: '${DISK:-BOŞ}')"
        echo "    2. USERNAME değişkenini kontrol et (şu an: '$USERNAME')"
        echo "    3. HOSTNAME değişkenini kontrol et (şu an: '$HOSTNAME')"
        echo ""
        echo "  Disk listesi için: lsblk"
        ;;
esac
