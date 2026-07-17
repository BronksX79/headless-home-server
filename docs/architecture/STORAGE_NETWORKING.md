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

### Directory Tree & Mounting Boundaries

* 📦 **Lexar Boot SSD (`/dev/sda2`):** Stores low-latency system runtimes.
* 📦 **OS & Engine:** Ubuntu Server and Docker core files live here.
* 📦 **Postgres DB:** Mapped to SSD volumes to prevent query bottlenecks.
* 📦 **Seagate Storage HDD (`/dev/sdb1`):** Stores high-capacity file payloads.
* 📦 **Docker Metadata (Pi-hole, Caddy):** Service compose folders live at `/mnt/storage/docker`.
* 📦 **Static Web Assets:** Portfolio code lives at `/mnt/storage/portfolio`.

> ⚠️ **Known Deviation — Immich is not yet migrated.** Per `CONTRIBUTING.md`'s volume binding standard, Immich's compose files and upload volume should live at `/mnt/storage/docker/immich`. In practice, Immich was deployed and is still running from `~/immich` on the boot SSD, and its Postgres data volume is a Docker-managed named volume (`immich_immich-db`) rather than an explicit host path. This is flagged as **planned cleanup work**, not a documentation error — see Planned Developments in the README.

---

## ⚙️ Network Topology & Port Mapping

### IP and Domain Allocation

* ⚙️ **Physical Interface:** `enp5s0` (Realtek Gigabit Ethernet RJ45)
* ⚙️ **Static Local IP Address:** `192.168.55.233`
* ⚙️ **Ad-Blocking Local Shortcut:** `http://pi.home` (Port 80)
* ⚙️ **Photo Cloud Local Shortcut:** `http://photos.local` (Port 80)
* ⚙️ **Direct Local Web Gateway:** `http://192.168.55.233` (Port 80)

### Host Port Bindings & Reverse Proxy Routes

```text
[LAN Client Requests]
       │
       ▼
 [Host: 192.168.55.233]
       │
       ├───► Port 53 ───► [Pi-hole Container:53] (DNS Traffic Sinkhole)
       │
       ├───► Port 80 ───► [Caddy Container:80] (Primary Reverse Proxy)
       │                    │
       │                    ├───► http://192.168.55.233 ──► [Local Folder: /var/www/portfolio]
       │                    ├───► http://photos.local   ──► [Immich Server Container:2283]
       │                    └───► http://pi.home        ──► [Pi-hole Dashboard Container:80]
       │
       ├───► Port 8080 ──► [Pi-hole Admin Console] (LAN-restricted, bypasses Caddy proxy)
       │
       └───► Port 2283 ──► [Immich Core API Engine] (Not exposed — see Firewall Rules below)
```

---

## 📊 Firewall State (UFW) — Verified

> This section was previously written to describe an *intended* firewall policy that was, in fact, never enforced — UFW had been disabled during Phase 1 troubleshooting (`sudo ufw disable`) and stayed inactive through the remainder of initial deployment. The rules below were verified live via `sudo ufw status verbose` on 2026-07-17 and reflect the actual, currently active state. See `docs/troubleshooting/FIREWALL_HARDENING.md` for the full remediation log.

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

**Deliberately not opened:** Port `2283` (Immich direct API) has no firewall rule at all. It is only reachable through Caddy's reverse proxy on 80/443 — this enforces the "isolate your ports" principle rather than just documenting it as a suggestion.

**Known limitation:** Rules 5 and 6 are IPv4-only (`192.168.55.0/24` is not a valid IPv6 notation). Any device reaching Pi-hole or its dashboard over IPv6 would currently be blocked outright rather than LAN-restricted. This fails closed (blocks access) rather than open (allows internet-wide access), so it is a functionality gap, not a security gap — noted here so a future "why can't device X reach Pi-hole" issue isn't a mystery.

### DNS Resolution Flowchart

```text
[Device Request] ──► [Pi-hole DNS (Port 53)]
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      [Internal Domain?]          [External Domain?]
              │                           │
     (photos.local / pi.home)       (google.com)
              │                           │
              ▼                           ▼
    [Resolve to 192.168.55.233]   [Forward to upstream resolver]
              │                           │
              ▼                           ▼
     [Route via Caddy Proxy]     [Fetch Web Payload]
```
