# ~/.config/fish/conf.d/caelestia.fish
# ──────────────────────────────────────────────────────────────────────
# Caelestia tema sistemi ile terminal entegrasyonu.
# conf.d/ içindeki her .fish dosyası otomatik yüklenir —
# config.fish'e dokunmana gerek yok.
#
# Caelestia renk entegrasyonu:
#   cli.json → "theme": { "enableTerm": true } yapıldığında
#   caelestia, tema değiştiğinde terminal 16-renk paletini günceller.
#   Starship ve fastfetch bu paleti otomatik kullanır.

if not status is-interactive
    return
end

# ── STARSHIP ──────────────────────────────────────────────────────────
# Starship config konumunu açıkça belirt
set -x STARSHIP_CONFIG "$HOME/.config/starship.toml"

if command -q starship
    starship init fish | source
end

# ── FOOT: PROMPT MARKER ───────────────────────────────────────────────
# foot terminali prompt'lar arası atlamayı (Ctrl+Shift+Z/X) destekler.
# Upstream caelestia-dots/fish'den alındı.
function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end

# ── CAELESTIA YARDIMCI FONKSİYONLAR ──────────────────────────────────

# ctheme: tema değiştir → ctheme dynamic | ctheme mocha | ctheme (liste)
function ctheme
    if test (count $argv) -eq 0
        echo "Mevcut temalar:"
        caelestia scheme list
        return
    end
    caelestia scheme set -n $argv[1]
    echo "✓ Tema: $argv[1]"
end

# cwall: wallpaper değiştir ve dinamik temayı güncelle
# Kullanım: cwall ~/Pictures/Wallpapers/resim.jpg
function cwall
    if test (count $argv) -eq 0
        echo "Kullanım: cwall <dosya_yolu>"
        caelestia wallpaper --help
        return
    end
    caelestia wallpaper -f $argv[1]
    echo "✓ Wallpaper: $argv[1]"
end

# crs: caelestia shell'i yeniden başlat
function crs
    caelestia shell restart
    echo "✓ Caelestia shell yeniden başlatıldı"
end
