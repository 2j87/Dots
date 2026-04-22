# kerem-hyprland-dots

**Hyprland + Caelestia Shell** tabanlı Arch Linux masaüstü konfigürasyonu.

> Temiz, çökmeyen, tek komutla kurulabilen bir rice.

---

## Hızlı Kurulum

```bash
git clone https://github.com/hkrclng/kerem-hyprland-dots.git
cd kerem-hyprland-dots
chmod +x install.sh
./install.sh
```

## Repo Yapısı

```
kerem-hyprland-dots/
├── install.sh              ← Tek komutla kurar
├── RELEASE_NOTES.md        ← Neyin nerede olduğu, sorun giderme
│
├── hypr/                   ← ~/.config/hypr olarak kopyalanır
│   ├── hyprland.conf       ← Ana giriş (sadece source'lar)
│   ├── core/               ← env, variables, monitor
│   ├── visual/             ← decoration, animations, misc
│   ├── input/              ← keyboard, gestures, binds
│   ├── rules/              ← windowrules, layerrules
│   ├── autostart/          ← system, shell
│   ├── scheme/             ← caelestia-cli yönetir
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   └── hyprpaper.conf
│
└── caelestia/              ← ~/.config/caelestia olarak kopyalanır
    ├── shell.json          ← UI ayarları
    ├── cli.json            ← Tema ve toggle ayarları
    └── hypr-user.conf      ← Kişisel Hyprland tweakleri
```

Detaylı dokümantasyon için → **[RELEASE_NOTES.md](./RELEASE_NOTES.md)**
