# Troubleshooting: Tailscale Remote Access Setup

This log documents deploying Tailscale for remote access to internal services (`*.local` domains) without forwarding any router ports, and the three separate issues hit getting a phone working over mobile data.

---

## 📦 Objective

Reach `vault.local`, `photos.local`, `home.local`, `files.local`, and `pi.home` from any device, from anywhere — not just devices physically on the home LAN — without opening inbound ports on the router.

## ⚙️ Why Tailscale Fits This Hardware

Tailscale is built on WireGuard, which uses ChaCha20-Poly1305 rather than AES for encryption — a deliberate design choice that performs well in pure software. This matters specifically because the Pentium P6100 has no AES-NI instruction set; VPN technologies that lean on hardware-accelerated AES (OpenVPN, IPsec) would be comparatively slower on this CPU. Tailscale's own daemon is a lightweight single Go binary with minimal RAM/CPU footprint at idle.

Installed as a native Ubuntu package rather than a Docker container, since it needs direct control of host routing tables — running it in Docker would require privileged flags and host networking mode for no real benefit here.

---

## 🛠️ Setup Steps

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticated via browser, confirmed with:
```bash
tailscale status
# 100.105.250.83  bronksserver  ...
```

---

## 💥 Issue 1: `/etc/resolv.conf` Immutability Conflict

* 💥 `tailscale status` reported a health warning: Tailscale couldn't write to `/etc/resolv.conf` because it was set immutable (`chattr +i`) back in Phase 3, as a workaround to stop `systemd-resolved` from overwriting Pi-hole's custom upstream DNS settings.
* 🤖 **Analysis:** `systemd-resolved` was already masked (disabled) from that same Phase 3 work, so nothing remained that would actually fight Tailscale for control of the file — the immutable flag was solving a problem that no longer existed, and blocking a new legitimate need instead.
* 🛠️ **Remediation:**
```bash
sudo chattr -i /etc/resolv.conf
sudo systemctl restart tailscaled
```
Confirmed clean via `tailscale status` — no health warnings.

---

## 💥 Issue 2: Phone Couldn't Resolve `*.local` Domains

* 💥 Phone joined the tailnet successfully (visible in `tailscale status`), but browsing to `photos.local` returned "DNS probe bad config."
* 🤖 **Analysis:** Android's system-level **Private DNS** setting (Settings → Network & Internet → Private DNS) overrides VPN-provided DNS in some configurations, even when Tailscale's own "Use Tailscale DNS" toggle is enabled inside its app.
* 🛠️ **Remediation:** Set Android's Private DNS to **Off** (not "Automatic," which still lets Android pick its own provider). Combined with:
  * Tailscale Admin Console → **DNS** → MagicDNS enabled
  * Custom nameserver added: `192.168.55.233` (Pi-hole), with **Override local DNS** enabled

---

## 💥 Issue 3: Connection Timed Out After DNS Was Fixed

* 💥 After fixing DNS, `photos.local` resolved but timed out rather than connecting.
* 🤖 **Analysis:** Pi-hole resolves `*.local` domains to the server's LAN IP (`192.168.55.233`) — a different network than the tailnet's own `100.x.x.x` addressing. By default, Tailscale only routes traffic to a device's own tailnet IP, not to other networks that device can reach (like the home LAN behind it). This required explicitly advertising the home subnet.
* 🛠️ **Remediation:**
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
sudo tailscale up --advertise-routes=192.168.55.0/24 --accept-dns=true
```
Then approved manually in the admin console (**Machines → bronksserver → Subnet routes** → enable `192.168.55.0/24`) — Tailscale requires explicit approval before a device can route traffic to another network, by design.

---

## 📊 Certificate Trust on Mobile

`vault.local` requires HTTPS (a hard browser/app requirement for Bitwarden-compatible clients), served via Caddy's `tls internal` self-signed local CA. Devices that haven't explicitly trusted that CA see a certificate warning. Trusted on Android via:

* Settings → Security & Privacy → Encryption & credentials → Install a certificate → CA certificate
* Selected the exported `root.crt` (retrieved via `docker exec caddy cat /data/caddy/pki/authorities/local/root.crt`)

`photos.local` (and other plain-HTTP-only services) will always show a browser "not secure" label — this is expected and accurate, not a misconfiguration. It's an accepted tradeoff: those services don't require encryption to function, and their traffic is already wrapped in Tailscale's own WireGuard encryption when accessed remotely.

## 📊 Outcome

Confirmed working over mobile data (Wi-Fi off) on Android: `vault.local` (HTTPS, cert-trusted) and `photos.local` (HTTP) both load correctly from outside the home network, with no router ports forwarded.
