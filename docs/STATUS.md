# 🚦 Project Status

## Completed

* **Headless OS Provisioning:** Ubuntu Server (headless, no GUI) deployed onto the Lexar SSD.
* **ACPI Power Policy Hardening:** Lid-close suspend disabled via `/etc/systemd/logind.conf`, so the server runs closed on a shelf.
* **Storage Partitioning & Automounting:** 1TB HDD formatted `ext4`, mounted persistently at `/mnt/storage` via UUID in `/etc/fstab`.
* **Container Engine Deployment:** Docker installed via the `noble` stable channel (working around unreleased-codename 404s), non-root socket access configured.
* **Port 53 System Integration:** `systemd-resolved` masked to free port 53 for Pi-hole; `resolv.conf` pointed at public upstream resolvers.
* **Services Orchestration:**
  * **Pi-hole** — local DNS sinkhole, dashboard on port 8080.
  * **Caddy** — edge reverse proxy on ports 80/443.
  * **Immich** — photo backup engine, machine learning and video transcoding disabled to fit the CPU/RAM budget.
  * **homepage** — unified dashboard linking to all services.
  * **filebrowser** — web-based file management for the 1TB HDD, including direct editing of compose files.
  * **Vaultwarden** — self-hosted, Bitwarden-compatible password manager, served over HTTPS via Caddy's local CA.
* **Local DNS Mapping:** `photos.local`, `pi.home`, `home.local`, `files.local`, and `vault.local` all resolve locally via Pi-hole, routed through Caddy.
* **Static Web Deployment:** A single-file responsive HTML/CSS portfolio page served directly from `/mnt/storage/portfolio`.
* **Host Firewall Enforcement (UFW):** Default-deny on incoming, with DNS and the Pi-hole dashboard restricted to the home LAN. See `docs/troubleshooting/FIREWALL_HARDENING.md`.
* **Network Isolation (Docker/UFW Gap Fix):** Discovered that Docker's own iptables rules bypass UFW entirely for published container ports. Migrated Immich, homepage, and filebrowser off host-published ports and onto an internal-only Docker network (`proxynet`), reachable exclusively through Caddy. See `docs/troubleshooting/NETWORK_ISOLATION.md`.
* **Remote Access via Tailscale:** WireGuard-based private mesh network, no router ports forwarded. MagicDNS + Pi-hole as tailnet nameserver lets any connected device resolve all internal `*.local` domains from anywhere. Confirmed working over mobile data. See `docs/troubleshooting/TAILSCALE_REMOTE_ACCESS.md`.
* **Tailscale ACLs — Filebrowser Restriction:** Filebrowser (able to directly edit compose files) moved to its own dedicated Caddy port and restricted via a Tailscale ACL to a single tagged, trusted device. Every other service remains reachable to any tailnet device. Verified: untagged devices time out on the filebrowser port entirely, rather than merely hitting a login screen. See `docs/troubleshooting/TAILSCALE_ACL_FILEBROWSER.md`.
* Memory Array Expansion: RAM upgraded 4GB → 8GB DDR3 (1066MHz, native to the laptop's supported configuration). Primarily intended to give Postgres more caching headroom.
* Automated Offsite Backup (rsync): 256GB 2.5" HDD connected via powered USB hub, rsync job scheduled via cron for 04:00 every Sunday. Backup execution confirmed running; **restore has not yet been tested**. Treat as unverified until a restore has been performed successfully at least once.
  
## Planned

* **Samba (SMB) Server Integration** — drag-and-drop file access from Windows/macOS clients on the LAN.
* **Immich Directory Migration** — move Immich's compose file and data off `~/immich` (SSD) and into the `/mnt/storage/docker` layout used by other services, per the standard in `CONTRIBUTING.md`.
* **Power-Loss Mitigation** — evaluate a small UPS, since the battery cells were removed and any mains interruption is currently an unclean shutdown for Postgres. See `docs/troubleshooting/BOOT_LOOP_REMEDIATION.md`.
* **Cloudflare Tunnel (selective, public-facing only)** — being considered for services intended to be genuinely public (e.g. sharing an Immich photo album link), kept strictly separate from Tailscale-only services like filebrowser and Vaultwarden.
