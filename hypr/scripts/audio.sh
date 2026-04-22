#!/usr/bin/env bash
# ── SCRIPTS/AUDIO.SH ──────────────────────────────────────────────────
# Ses kontrol yardımcı scripti.
# Caelestia shell kendi ses servisini (services/Audio.qml) yönetir.
# Bu script, bar dışında kullanmak istersen diye burada.
#
# Kullanım:
#   audio.sh up        → sesi 5% artır
#   audio.sh down      → sesi 5% azalt
#   audio.sh mute      → sesi kapat/aç
#   audio.sh micmute   → mikrofonu kapat/aç
#   audio.sh get       → mevcut ses seviyesini yazdır

set -euo pipefail

SINK="@DEFAULT_AUDIO_SINK@"
SOURCE="@DEFAULT_AUDIO_SOURCE@"
STEP="5%"
MAX="150%"   # caelestia default max volume

case "${1:-}" in
    up)
        wpctl set-volume -l 1.5 "$SINK" "$STEP+"
        ;;
    down)
        wpctl set-volume "$SINK" "$STEP-"
        ;;
    mute)
        wpctl set-mute "$SINK" toggle
        ;;
    micmute)
        wpctl set-mute "$SOURCE" toggle
        ;;
    get)
        wpctl get-volume "$SINK" | awk '{printf "%.0f\n", $2 * 100}'
        ;;
    *)
        echo "Kullanım: audio.sh [up|down|mute|micmute|get]" >&2
        exit 1
        ;;
esac
