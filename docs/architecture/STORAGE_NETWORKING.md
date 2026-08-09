# Storage & Networking Architecture

This document specifies the physical storage partitions, directory layouts, and network configurations of the single-node server.

---

## 📦 Storage Architecture Specifications

### Physical Storage Partitions

| Block Device | Physical Media | Size | File System | Host Mount Point | Allocation / Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/dev/sda1` | Lexar NS100 SSD | 1MB | N/A | None | BIOS Boot Partition (GRUB) |
| `/dev/sda2` | Lexar NS100 SSD | 119.2GB | `ext4` | `/` (System Root) | Host OS, Docker, postgres DB |
| `/dev/sdb1` | Seagate Mobile HDD | 931.5GB | `ext4` | `/mnt/storage` | Bulk Photos, Docker Configs, Static Site |
| `/dev/sdc1` | TOSHIBA MK2559GSXP HDD | 250 GB | `ext4` | `/mnt/backup-HDD` | Backup: Immich database, Vaulwarden Passwords, Config Files |

### Directory Tree & Mounting Boundaries

* 📦 **Lexar Boot SSD (`/dev/sda2`):** Stores low-latency system runtimes.
* 📦 **OS & Engine:** Ubuntu Server and Docker core files live here.
* 📦 **Postgres DB:** Mapped to SSD volumes to prevent query bottlenecks.
* 📦 **Seagate Storage HDD (`/dev/sdb1`):** Stores high-capacity file payloads.
* 📦 **Docker Metadata:** Pi-hole, Caddy, homepage/filebrowser, and Vaultwarden compose folders live at `/mnt/storage/docker`.
* 📦 **Static Web Assets:** Portfolio code lives at `/mnt/storage/portfolio`.

> ⚠️ **Known Deviation — Immich is not yet migrated.** Per `CONTRIBUTING.md`'s volume binding standard, Immich's compose files and upload volume should live at `/mnt/storage/docker/immich`. In practice, Immich runs from `~/immich` on the boot SSD, with Postgres on a Docker-managed named volume rather than an explicit host path. Tracked in `docs/STATUS.md`.

---

## ⚙️ Network Topology & Port Mapping

### IP and Domain Allocation

* ⚙️ **Physical Interface:** `enp5s0` (Realtek Gigabit Ethernet RJ45)
* ⚙️ **Static Local IP Address:** `192.168.55.233`
* ⚙️ **Tailscale IP:** `100.105.250.83` (see `docs/troubleshooting/TAILSCALE_REMOTE_ACCESS.md`)
* ⚙️ **Local domains (via Pi-hole):** `pi.home`, `photos.local`, `home.local`, `files.local`, `vault.local`

### Docker Network Segmentation

Services fall into two categories:

* **Internal-only (`proxynet`):** Immich, homepage, filebrowser, and Vaultwarden publish no ports to the host at all. They join a dedicated Docker bridge network (`proxynet`) that only Caddy also joins, and are reachable exclusively through Caddy's reverse proxy, addressed by container name.
* **Host-published (unavoidable):** Caddy (80/443, the only intended host-facing service) and Pi-hole (53 for DNS, 8080 for its dashboard — neither can route through an HTTP reverse proxy).

### Host Port Bindings & Reverse Proxy Routes

```text
[LAN / Tailscale Client Requests]
       │
       ▼
 [Host: 192.168.55.233]
       │
       ├───► Port 53 ───► [Pi-hole Container:53] (DNS Traffic Sinkhole)
       │
       ├───► Port 80/443 ───► [Caddy Container] (Primary Reverse Proxy, on proxynet)
       │                    │
       │                    ├──► http://192.168.55.233 ──► [Local Folder: /var/www/portfolio]
       │                    ├──► http://photos.local   ──► [immich_server:2283]   (proxynet)
       │                    ├──► http://home.local     ──► [homepage:3000]        (proxynet)
       │                    ├──► http://files.local    ──► [filebrowser:80]       (proxynet)
       │                    ├──► https://vault.local   ──► [vaultwarden:80]       (proxynet, tls internal)
       │                    └──► http://pi.home        ──► [Pi-hole Dashboard:8080] (host IP, not on proxynet)
       │
       └───► Port 8080 ──► [Pi-hole Admin Console] (LAN-restricted, bypasses Caddy proxy)
```

**Deliberately not published to the host at all:** Immich (2283), homepage (3000), filebrowser (8090). See `docs/troubleshooting/NETWORK_ISOLATION.md` for why this changed from an earlier, firewall-only approach.

---

## 📊 Firewall State (UFW) — Verified

**Status:** `active` | **Default policy:** deny (incoming), allow (outgoing), deny (routed) | **Logging:** on (low)

| # | Port | Action | Source | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 22/tcp | ALLOW IN | Anywhere | SSH |
| 2 | 80/tcp | ALLOW IN | Anywhere | HTTP – Caddy |
| 3 | 443/tcp | ALLOW IN | Anywhere | HTTPS – Caddy |
| 4 | 443/udp | ALLOW IN | Anywhere | HTTP/3 – Caddy |
| 5 | 53 | ALLOW IN | `192.168.55.0/24` only | Pi-hole DNS – LAN restricted |
| 6 | 8080 | ALLOW IN | `192.168.55.0/24` only | Pi-hole dashboard – LAN restricted |
| 7–10 | (v6 equivalents of 1–4) | ALLOW IN | Anywhere (v6) | Same as above |

> ⚠️ **Important nuance, learned the hard way:** UFW rules alone do **not** guarantee a port is inaccessible. Docker inserts its own `iptables` rules for any container using `ports:`, and those rules take effect **before** UFW's — meaning a published container port is reachable regardless of what UFW says. This is why Immich, homepage, and filebrowser were migrated onto the internal `proxynet` network entirely (removing `ports:` from their compose files) rather than relying on a UFW rule to restrict them. Pi-hole's `53`/`8080` are the one remaining exception, since DNS can't be reverse-proxied — those stay genuinely reliant on both the LAN-restricted UFW rule *and* not being forwarded on the router.

**Known limitation:** Rules 5 and 6 are IPv4-only. A device reaching Pi-hole over IPv6 would be blocked outright rather than LAN-scoped — fails closed, not open.

### DNS Resolution Flowchart

```text
[Device Request] ──► [Pi-hole DNS (Port 53)]
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      [Internal Domain?]          [External Domain?]
              │                           │
     (*.local / pi.home)           (google.com)
              │                           │
              ▼                           ▼
    [Resolve to 192.168.55.233]   [Forward to upstream resolver]
              │                           │
              ▼                           ▼
     [Route via Caddy Proxy]     [Fetch Web Payload]
```

Devices connected via Tailscale use the same Pi-hole instance as their tailnet nameserver (MagicDNS + custom nameserver `192.168.55.233`), so `*.local` domains resolve identically whether a device is on the home LAN or connecting remotely. See `docs/troubleshooting/TAILSCALE_REMOTE_ACCESS.md` for the subnet-routing configuration that makes this reachable, not just resolvable.
