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
  * **Immich** — photo backup engine on port 2283, with machine learning and video transcoding disabled to fit the CPU/RAM budget.
* **Local DNS Mapping:** `photos.local` and `pi.home` resolve locally via Pi-hole, routed through Caddy.
* **Static Web Deployment:** A single-file responsive HTML/CSS portfolio page served directly from `/mnt/storage/portfolio`.
* **Host Firewall Enforcement (UFW):** Found and fixed a firewall that had been silently disabled since early setup. Now default-deny on incoming, with DNS and the Pi-hole dashboard restricted to the home LAN, and Immich's port never opened directly. Full story in `docs/troubleshooting/FIREWALL_HARDENING.md`.

## Planned

* **Samba (SMB) Server Integration** — drag-and-drop file access from Windows/macOS clients on the LAN.
* **Tailscale Mesh Network** — encrypted remote access to dashboards without opening router ports.
* **Memory Array Expansion** — 4GB → 8GB DDR3, mainly to give Postgres more caching headroom.
* **Automated Offsite Backup (rsync)** — nightly mirror of the photo library to a separate external drive.
* **Immich Directory Migration** — move Immich's compose file and data off `~/immich` (SSD) and into the `/mnt/storage/docker` layout used by Pi-hole and Caddy, per the standard in `CONTRIBUTING.md`.
* **Power-Loss Mitigation** — evaluate a small UPS, since the battery cells were removed and any mains interruption is currently an unclean shutdown for Postgres. See `docs/troubleshooting/BOOT_LOOP_REMEDIATION.md`.
