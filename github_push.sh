#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# github_push.sh — kerem-hyprland-dots reposunu GitHub'a gönderir
#
# Kullanım:
#   1. GITHUB_USER ve GITHUB_TOKEN'ı doldur
#   2. chmod +x github_push.sh && ./github_push.sh
#
# Token oluşturma:
#   GitHub → Settings → Developer settings
#   → Fine-grained personal access tokens → New token
#   → Repository permissions: Contents = Read & Write
# ══════════════════════════════════════════════════════════════════════

set -euo pipefail

GITHUB_USER=""        # GitHub kullanıcı adın (örn: hkrclng)
GITHUB_TOKEN=""       # Personal access token (örn: github_pat_xxx)

REPO_NAME="kerem-hyprland-dots"
REPO_DESC="Hyprland + Caelestia Shell :: Arch Linux dotfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}[OK]${RESET}   $*"; }
info() { echo -e "${CYAN}[-->]${RESET} $*"; }
die()  { echo -e "${RED}[!!!]${RESET} $*" >&2; exit 1; }

[[ -z "$GITHUB_USER"  ]] && die "GITHUB_USER boş! Scriptin içini doldur."
[[ -z "$GITHUB_TOKEN" ]] && die "GITHUB_TOKEN boş! Scriptin içini doldur."
command -v git  &>/dev/null || die "git kurulu değil"
command -v curl &>/dev/null || die "curl kurulu değil"

echo -e "\n${BOLD}${CYAN}  → $GITHUB_USER/$REPO_NAME${RESET}\n"

# ── REPO OLUŞTUR / KONTROL ET ─────────────────────────────────────────
info "Repo kontrol ediliyor..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME")

if [[ "$STATUS" == "200" ]]; then
    ok "Repo zaten mevcut"
else
    info "Repo oluşturuluyor..."
    CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$REPO_NAME\",\"description\":\"$REPO_DESC\",\"private\":false,\"auto_init\":false}" \
        "https://api.github.com/user/repos")
    [[ "$CODE" == "201" ]] || die "Repo oluşturulamadı (HTTP $CODE). Token iznini kontrol et."
    ok "Repo oluşturuldu"
    sleep 2
fi

# ── GIT YAPILANDIRMASI ────────────────────────────────────────────────
cd "$SCRIPT_DIR"

[[ ! -d ".git" ]] && git init && git checkout -b main 2>/dev/null || true

if git remote get-url origin &>/dev/null; then
    git remote set-url origin "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"
else
    git remote add origin "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"
fi

# .gitignore
cat > .gitignore << 'EOF'
*.swp
*.tmp
*~
.DS_Store
EOF

# ── COMMIT & PUSH ─────────────────────────────────────────────────────
info "Dosyalar ekleniyor..."
git add -A

if git diff --cached --quiet; then
    ok "Değişiklik yok, push atlanıyor"
else
    git commit -m "feat: kerem-hyprland-dots v1.0.0

Hyprland + Caelestia Shell konfigürasyonu ilk sürümü.
- core/ visual/ input/ rules/ autostart/ yapısı
- Caelestia shell.json + cli.json başlangıç ayarları
- install.sh otomatik kurulum scripti
- RELEASE_NOTES.md dokümantasyonu"
    ok "Commit oluşturuldu"
fi

info "Push ediliyor..."
git push -u origin main --force
ok "Push tamamlandı!"

echo ""
echo -e "${BOLD}${GREEN}  ✓ https://github.com/$GITHUB_USER/$REPO_NAME${RESET}"
echo ""
echo "  Başka bir makineden kurmak için:"
echo "    git clone https://github.com/$GITHUB_USER/$REPO_NAME.git"
echo "    cd $REPO_NAME && chmod +x install.sh && ./install.sh"
echo ""
echo -e "${RED}  [!] Güvenlik: Token scriptin içinde kalıyor.${RESET}"
echo "      Push sonrası temizle:"
echo "      sed -i 's/GITHUB_TOKEN=\".*\"/GITHUB_TOKEN=\"\"/' github_push.sh"
