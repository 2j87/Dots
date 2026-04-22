# kerem-hyprland-dots — Sürüm Notları

> Hyprland + Caelestia Shell tabanlı Arch Linux masaüstü konfigürasyonu.  
> Yazar: Kerem | Oluşturulma: 2026-04

---

## v1.0.0 — İlk Sürüm

### Ne Bu Repo?

Bu repo, sıfırdan kurulabilen, çökmesiz ve bakımı kolay bir Hyprland + Caelestia Shell
masaüstü ortamı için hazırlanmış konfigürasyon dosyalarını içerir.

Tasarım felsefesi:
- **Her dosyanın tek bir sorumluluğu var.** Blur ayarını değiştirmek için `visual/decoration.conf`'a git, başka bir şeye dokunma.
- **Upstream koduna dokunulmaz.** `~/.config/quickshell/caelestia/` git reposudur, elle düzenlenmez.
- **Caelestia kullanıcı alanı ayrıdır.** `~/.config/caelestia/` senin alanın.
- **Script tek komutla kurar.** `install.sh` her şeyi halleder.

---

## Sistem Mimarisi

```
Hyprland (window manager / compositor)
  └── Caelestia Shell (quickshell tabanlı UI katmanı)
        ├── Bar (üst panel)
        ├── Dashboard (sol panel)
        ├── Launcher (uygulama başlatıcı)
        ├── Sidebar (bildirimler, sağ panel)
        ├── OSD (ses/parlaklık göstergesi)
        ├── Lock (kilit ekranı)
        └── Session (kapatma menüsü)
```

---

## Dosya Haritası

### `hypr/` — Hyprland Konfigürasyonu

| Dosya | Sorumluluk | Ne Zaman Düzenlersin |
|---|---|---|
| `hyprland.conf` | Ana giriş, sadece `source` satırları | Yeni bir dosya ekleyince |
| `core/env.conf` | Wayland, QT, GTK ortam değişkenleri | Yeni bir uygulama env değişkeni isterse |
| `core/variables.conf` | `$terminal`, `$mainMod`, `$kbSession` | Varsayılan uygulamayı değiştirince |
| `core/monitor.conf` | Monitör çözünürlüğü ve konumu | Monitör değiştirince |
| `visual/general.conf` | Border boyutu, gap, layout | Boşluk/layout ayarlamak istersen |
| `visual/decoration.conf` | Blur, shadow, rounding, opaklık | Görsel efektleri ayarlamak istersen |
| `visual/animations.conf` | Bezier eğrileri, geçiş animasyonları | Animasyonları hızlandırmak/yavaşlatmak istersen |
| `visual/misc.conf` | VRR, VFR, cursor, xwayland | Titreme/sorun gidermede |
| `input/keyboard.conf` | Klavye düzeni (tr), fare, touchpad | Klavye/touchpad ayarlamak istersen |
| `input/gestures.conf` | Touchpad workspace jest | Jest ayarı için |
| `input/binds.conf` | Tüm tuş kısayolları | Kısayol eklemek/değiştirmek istersen |
| `rules/windowrules.conf` | Pencere kuralları (float, size, opacity) | Uygulama davranışını özelleştirmek için |
| `rules/layerrules.conf` | Caelestia panel blur/animasyon kuralları | Panel görünümünü ayarlamak için |
| `autostart/system.conf` | Portal, ses, clipboard servisleri | Sistem servisi eklemek/çıkarmak için |
| `autostart/shell.conf` | Caelestia shell ve hyprpaper başlatma | Shell başlatma sorunlarında |
| `scheme/current.conf` | ⚠️ caelestia-cli yönetir — dokunma | — |
| `hypridle.conf` | Boşta kalma zamanlayıcıları | Kilit/uyku sürelerini değiştirmek için |
| `hyprlock.conf` | Kilit ekranı görünümü | Kilit ekranını özelleştirmek için |
| `hyprpaper.conf` | Wallpaper daemon | IPC ayarı için |
| `scripts/audio.sh` | Ses kontrol yardımcı scripti | Ses sorunlarında |

### `caelestia/` — Caelestia Kullanıcı Konfigürasyonu

| Dosya | Sorumluluk | Ne Zaman Düzenlersin |
|---|---|---|
| `shell.json` | Bar, dashboard, launcher, font, animasyon | Shell görünümünü özelleştirmek için |
| `cli.json` | Tema sistemi, special workspace toggle | Uygulama toggle'ları ve tema için |
| `hypr-user.conf` | Hyprland'a caelestia üzerinden tweak | VRR gibi özel ayarlar için |

---

## Bağımlılıklar

### Zorunlu Paketler

```
# Pacman
hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
hyprpicker hypridle hyprlock hyprpaper
networkmanager pipewire wireplumber
brightnessctl ddcutil lm-sensors
libcava libqalculate libnotify
grim slurp swappy wl-clipboard cliphist fuzzel glib2
fish inotify-tools trash-cli jq
foot thunar pavucontrol mpv btop fastfetch
adw-gtk-theme papirus-icon-theme
qt6-base qt6-declarative
polkit-gnome

# AUR (sırayla kurulmalı)
quickshell-git
caelestia-shell
caelestia-cli
ttf-material-symbols-variable-git
ttf-caskaydia-cove-nerd
papirus-folders
gpu-screen-recorder
app2unit
aubio
dart-sass
```

### Önerilen Ek Paketler

```
starship        # fish shell prompt
zen-browser     # variables.conf'ta $browser olarak tanımlı
code            # variables.conf'ta $editor olarak tanımlı
```

---

## Kurulum

`install.sh` scripti sırayla şunları yapar:

1. Gerekli sistem paketlerini `pacman` ile kurar
2. `yay` (AUR helper) yoksa derleyip kurar
3. AUR paketlerini sırayla kurar (`quickshell-git` önce, `caelestia-shell` sonra)
4. Mevcut `~/.config/hypr` ve `~/.config/caelestia` dizinlerini yedekler
5. Bu repodan config dosyalarını doğru konumlara yerleştirir
6. `~/.config/hypr/scripts/audio.sh` için çalıştırma izni verir
7. Kurulum sonrası kontrol listesini gösterir

```bash
git clone https://github.com/KULLANICI/kerem-hyprland-dots.git
cd kerem-hyprland-dots
chmod +x install.sh
./install.sh
```

---

## İlk Başlatma Sonrası

Hyprland'a girince sırayla şunları yap:

```bash
# 1. Wallpaper ayarla
caelestia wallpaper -f ~/Pictures/Wallpapers/resim.jpg

# 2. Dinamik renk şemasını aktifleştir
caelestia scheme set -n dynamic

# 3. Foot terminal teması — caelestia kendi config'ini sağlar
git clone https://github.com/caelestia-dots/caelestia.git /tmp/caelestia
cp -r /tmp/caelestia/foot ~/.config/foot
# Tema değiştiğinde caelestia foot renklerini otomatik günceller (enableTerm: true)

# 4. Monitörü tanımla (kendi monitör adınla)
hyprctl monitors   # önce ismi öğren
# sonra core/monitor.conf'u düzenle

# 5. Profil resmi ekle (dashboard için)
cp resim.jpg ~/.face

# 6. Shell IPC hedeflerini kontrol et
caelestia shell -s
```

---

## Sorun Giderme

| Sorun | Çözüm |
|---|---|
| Ekran titremesi | `visual/misc.conf` → `vrr = 0` |
| NVIDIA siyah ekran | `core/env.conf` → `WLR_NO_HARDWARE_CURSORS=1` dene |
| NVIDIA cursor yok | `core/env.conf` → `WLR_NO_HARDWARE_CURSORS=1` yap |
| NVIDIA titreme | `visual/misc.conf` → `nvidia_anti_flicker = true` |
| Wayland başlamıyor | `nvidia_drm.modeset=1` GRUB parametresinde var mı kontrol et |
| Shell başlamıyor | `journalctl --user -xe \| grep caelestia` |
| Bar görünmüyor | `caelestia shell -d` ile manuel başlat |
| Border rengi yok | `scheme/current.conf` mevcut mu kontrol et |
| Blur çalışmıyor | `visual/decoration.conf` → `blur.enabled = true` |
| Ses tuşları çalışmıyor | `input/binds.conf` → XF86Audio satırları |
| Touchpad çalışmıyor | `input/keyboard.conf` → touchpad bloğu |
| Font eksik (ikonlar bozuk) | `ttf-material-symbols-variable-git` kurulu mu? |
| Kilit ekranı açılmıyor | `hypridle.conf` ve `hyprlock.conf` kontrol et |

---

## Güncelleme

### Config dosyalarını güncelle
```bash
cd ~/kerem-hyprland-dots
git pull
./install.sh --update   # sadece config dosyalarını kopyalar, paket kurmaz
```

### Caelestia shell'i güncelle
```bash
# AUR paketi ise:
yay -Syu caelestia-shell caelestia-cli

# Manuel kurulum ise:
cd ~/.config/quickshell/caelestia
git pull
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

---

## Sürüm Geçmişi

| Versiyon | Tarih | Değişiklikler |
|---|---|---|
| v1.0.0 | 2026-04 | İlk sürüm — tam konfigürasyon seti |

---

## Katkıda Bulunanlar

- **Caelestia Shell** — [caelestia-dots/shell](https://github.com/caelestia-dots/shell) (soramanew)
- **Caelestia CLI** — [caelestia-dots/cli](https://github.com/caelestia-dots/cli)
- **Quickshell** — [quickshell.outfoxxed.me](https://quickshell.outfoxxed.me)
- **Hyprland** — [hyprland.org](https://hyprland.org)
