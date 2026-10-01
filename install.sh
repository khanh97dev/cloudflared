#!/bin/sh
# Cloudflare Tunnel - one-line installer (token ma hoa AES-256)
#   curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | sh
#
# Token duoc ma hoa AES-256-CBC (openssl). Giai ma luc cai.
# - Neu nhung ca passphrase ben duoi  -> chay thang, khong can nhap gi.
# - Neu de passphrase ngoai (an toan hon):
#     curl -fsSL .../install.sh | TUNNEL_PASS='matkhau' sh
# - Hoac bo qua ma hoa, dung token raw:
#     curl -fsSL .../install.sh | TUNNEL_TOKEN='eyJ...' sh

set -eu

# ===== TOKEN DA MA HOA (base64 cua openssl aes-256-cbc -pbkdf2 -salt) =====
TOKEN_ENC=""
# Passphrase nhung san (de trong neu muon bat buoc truyen TUNNEL_PASS):
PASS_EMBEDDED=""
# =========================================================================

BIN=/usr/local/bin/cloudflared
CFG_DIR=/etc/cloudflared
SVC=/etc/systemd/system/cloudflared.service

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = "0" ] || die "Can chay bang root (sudo)."

# ---- 0. Lay token ----
TOKEN="${TUNNEL_TOKEN:-}"
# Bo khoang trang/newline lot vao khi copy-paste
TOKEN="$(printf '%s' "$TOKEN" | tr -d ' \t\n\r')"
if [ -z "$TOKEN" ]; then
  [ -n "$TOKEN_ENC" ] || die "Chua co token. Chay lai voi: ... | TUNNEL_TOKEN='eyJ...' sh"
  command -v openssl >/dev/null 2>&1 || die "Can openssl de giai ma token."
  PASS="${TUNNEL_PASS:-$PASS_EMBEDDED}"
  [ -n "$PASS" ] || die "Can passphrase. Chay lai voi: ... | TUNNEL_PASS='matkhau' sh"
  TOKEN="$(printf '%s' "$TOKEN_ENC" | openssl enc -aes-256-cbc -pbkdf2 -a -A -d -pass "pass:$PASS" 2>/dev/null)" \
    || die "Giai ma that bai (sai passphrase?)."
  [ -n "$TOKEN" ] || die "Token rong sau khi giai ma."
fi

# ---- 1. Phat hien kien truc ----
case "$(uname -m)" in
  x86_64|amd64)   ARCH=amd64 ;;
  aarch64|arm64)  ARCH=arm64 ;;
  armv7l|armv6l)  ARCH=arm ;;
  i386|i686)      ARCH=386 ;;
  *) die "Kien truc khong ho tro: $(uname -m)" ;;
esac
log "Kien truc: $ARCH"

# ---- 2. Tai cloudflared ----
URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
log "Tai cloudflared tu Cloudflare..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TMP/cloudflared"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMP/cloudflared" "$URL"
else
  die "Can curl hoac wget."
fi
[ -s "$TMP/cloudflared" ] || die "Tai that bai."
chmod 755 "$TMP/cloudflared"

# ---- 3. Cai dat binary ----
if [ -f "$SVC" ] && command -v systemctl >/dev/null 2>&1; then
  systemctl stop cloudflared >/dev/null 2>&1 || true
fi
install -m 755 "$TMP/cloudflared" "$BIN"
log "Da cai: $BIN ($("$BIN" --version 2>/dev/null | head -n1))"

# ---- 4. Luu token ----
mkdir -p "$CFG_DIR"; chmod 700 "$CFG_DIR"
umask 077
printf '%s' "$TOKEN" > "$CFG_DIR/token"
chmod 600 "$CFG_DIR/token"
log "Da luu token: $CFG_DIR/token"

# ---- 5. systemd service ----
if ! command -v systemctl >/dev/null 2>&1; then
  warn "Khong co systemd. Chay thu cong:"
  warn "  $BIN --no-autoupdate tunnel run --token-file $CFG_DIR/token"
  exit 0
fi
cat > "$SVC" <<EOF
[Unit]
Description=Cloudflare Tunnel client
After=network-online.target
Wants=network-online.target

[Service]
TimeoutStartSec=15
Type=notify
ExecStart=$BIN --no-autoupdate tunnel run --token-file $CFG_DIR/token
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable cloudflared >/dev/null 2>&1
systemctl restart cloudflared
sleep 3
if systemctl is-active --quiet cloudflared; then
  log "Tunnel dang chay. Log: journalctl -u cloudflared -f"
else
  warn "Service chua active. Log:"
  journalctl -u cloudflared -n 30 --no-pager || true
  exit 1
fi
