# ~/.config/fish/functions/fish_greeting.fish
# ──────────────────────────────────────────────────────────────────────
# Terminal açıldığında çalışır.
# fastfetch'i çalıştırır — sadece interaktif ve login oturumda.
#
# Devre dışı bırakmak için:
#   config.fish'te → set -g fish_greeting ""
# veya bu fonksiyonu boş bırak.

function fish_greeting
    # Sadece interaktif login oturumda fastfetch göster
    # (yeni sekme açtığında tekrar görmek istiyorsan "is-login" koşulunu kaldır)
    if status is-login
        fastfetch
    end
end
