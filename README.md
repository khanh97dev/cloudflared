# cloudflared one-line installer

Cai Cloudflare Tunnel (cloudflared) + systemd service chi bang 1 lenh.

## Cai dat

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | sh
```

Token tunnel da duoc nhung trong script, khong can nhap gi them.

Dung tunnel khac:

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/cloudflared/main/install.sh | TUNNEL_TOKEN=xxxxx sh
```

## Script lam gi

1. Phat hien kien truc (amd64 / arm64 / arm / 386)
2. Tai `cloudflared` ban latest tu GitHub release cua Cloudflare
3. Cai vao `/usr/local/bin/cloudflared`
4. Ghi token vao `/etc/cloudflared/token` (chmod 600)
5. Tao + enable + start service `cloudflared`

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
