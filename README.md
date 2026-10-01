# cloudflared one-line installer

Cai Cloudflare Tunnel (cloudflared) + systemd service chi bang 1 lenh.

## Cai dat

Script khong nhung token san. Co 3 cach dua token vao, xep theo do an toan:

### 1. Nhap tay (an toan nhat - token khong vao shell history)

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | sh
```

Script se hoi token, nhap xong Enter. Ky tu khong hien ra man hinh.

### 2. Truyen qua bien moi truong

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | TUNNEL_TOKEN='eyJ...' sh
```

Token nam tren command line nen se vao `~/.bash_history`. Script tu xoa cac dong
do sau khi cai (xem muc "Chong lo token"), nhung van nen go mot dau cach o dau
lenh neu shell co `HISTCONTROL=ignorespace`:

```sh
 curl -fsSL ... | TUNNEL_TOKEN='eyJ...' sh
```

### 3. Token ma hoa AES-256 nhung trong script

Dien `TOKEN_ENC` (base64 cua `openssl enc -aes-256-cbc -pbkdf2 -a -A -salt`) roi:

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | TUNNEL_PASS='matkhau' sh
```

## Script lam gi

1. Lay token (env `TUNNEL_TOKEN`, hoi tu terminal, hoac giai ma `TOKEN_ENC`)
2. Phat hien kien truc (amd64 / arm64 / arm / 386)
3. Tai `cloudflared` ban latest tu GitHub release cua Cloudflare
4. Cai vao `/usr/local/bin/cloudflared`
5. Ghi token vao `/etc/cloudflared/token` (chmod 600, thu muc chmod 700)
6. Xoa token khoi shell history
7. Tao + enable + start service `cloudflared`

## Chong lo token

- Token luu o `/etc/cloudflared/token`, quyen `600`, chi root doc duoc.
- Service dung `--token-file` nen token **khong** hien trong `ps aux`.
- Sau khi cai, script xoa cac dong co `TUNNEL_TOKEN` / `TUNNEL_PASS` trong
  `~/.bash_history` va `~/.zsh_history` (ca cua root).

Luu y: script chay trong subshell nen chi xoa duoc **file** history. Shell dang
mo van giu history trong RAM va se ghi de luc logout. Chay thêm lenh nay trong
shell hien tai:

```sh
history -c && history -w
```

## Quan ly

```sh
systemctl status cloudflared
journalctl -u cloudflared -f
systemctl restart cloudflared
```

## Go cai

```sh
systemctl disable --now cloudflared
rm -f /etc/systemd/system/cloudflared.service /usr/local/bin/cloudflared
rm -rf /etc/cloudflared
systemctl daemon-reload
```
