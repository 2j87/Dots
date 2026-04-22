# ~/.config/fish/config.fish
# ──────────────────────────────────────────────────────────────────────
# Fish ana konfigürasyon dosyası.
# Upstream caelestia-dots/fish ile uyumlu.
#
# Starship başlatma ve caelestia entegrasyonu conf.d/caelestia.fish
# dosyasına taşındı — bu dosyada sadece genel shell ayarları var.

if status is-interactive

    # ── KARŞILAMA MESAJI ──────────────────────────────────────────────
    # fish_greeting.fish dosyası varsa onu kullan (fastfetch çalıştırır)
    # Yoksa fish'in varsayılan karşılama mesajını kapat:
    set -g fish_greeting ""

    # ── GENEL AYARLAR ─────────────────────────────────────────────────
    # Komut geçmişi boyutu
    set -g fish_history_max_size 10000

    # ── TAKMAİSİMLER ──────────────────────────────────────────────────
    alias ls    "eza --icons --group-directories-first"
    alias ll    "eza -l --icons --group-directories-first --git"
    alias la    "eza -la --icons --group-directories-first --git"
    alias lt    "eza --tree --icons --level=2"
    alias cat   "bat --style=plain"
    alias grep  "grep --color=auto"
    alias mkdir "mkdir -pv"
    alias cp    "cp -iv"
    alias mv    "mv -iv"
    alias rm    "rm -iv"

    # Hyprland / Caelestia kısayolları
    alias hreload "hyprctl reload"
    alias hlog    "journalctl --user -xe | grep -i hyprland"
    alias clog    "journalctl --user -xe | grep -i caelestia"

end
