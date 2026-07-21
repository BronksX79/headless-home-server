# Headless Home Server

A decade-old laptop, forgotten in a drawer after another project, turned into an always-on home server — DNS-level ad blocking, a reverse proxy, private photo backup, a self-hosted password manager, and remote access from anywhere, built with no prior server experience.

## Quick Facts

* **Hardware:** Fujitsu LifeBook AH530 (2010-era) — dual-core Pentium, 4GB RAM, no GPU acceleration. → [`docs/HARDWARE.md`](docs/HARDWARE.md)
* **Why & How:** the actual reasoning behind each decision, including the ones that came from trial and error. → [`docs/PROJECT_STORY.md`](docs/PROJECT_STORY.md)
* **What's running vs. what's planned:** → [`docs/STATUS.md`](docs/STATUS.md)
* **Network & storage layout:** how the two drives are split and how traffic is routed. → [`docs/architecture/STORAGE_NETWORKING.md`](docs/architecture/STORAGE_NETWORKING.md)

## Stack

Ubuntu Server (headless) · Docker · Pi-hole · Caddy · Immich · homepage · filebrowser · Vaultwarden · Tailscale · UFW

## Engineering Logs & Troubleshooting

The full, unfiltered build process — including the mistakes — is documented phase by phase:

* [`docs/engineering-log/PHASE1_OS_DEPLOYMENT.md`](docs/engineering-log/PHASE1_OS_DEPLOYMENT.md) — OS install, headless access
* [`docs/engineering-log/PHASE2_STORAGE_DOCKER.md`](docs/engineering-log/PHASE2_STORAGE_DOCKER.md) — storage array, Docker setup
* [`docs/engineering-log/PHASE3_SERVICES_PROXY.md`](docs/engineering-log/PHASE3_SERVICES_PROXY.md) — Pi-hole, Caddy, Immich deployment
* [`docs/troubleshooting/BOOT_LOOP_REMEDIATION.md`](docs/troubleshooting/BOOT_LOOP_REMEDIATION.md) — a battery-less boot-loop and its (unconfirmed) cause
* [`docs/troubleshooting/IMMICH_DATABASE_FIX.md`](docs/troubleshooting/IMMICH_DATABASE_FIX.md) — a vector-database version mismatch
* [`docs/troubleshooting/FIREWALL_HARDENING.md`](docs/troubleshooting/FIREWALL_HARDENING.md) — a firewall that was silently off for weeks
* [`docs/troubleshooting/NETWORK_ISOLATION.md`](docs/troubleshooting/NETWORK_ISOLATION.md) — Docker silently bypassing UFW for published ports
* [`docs/troubleshooting/TAILSCALE_REMOTE_ACCESS.md`](docs/troubleshooting/TAILSCALE_REMOTE_ACCESS.md) — remote access setup, and three separate issues fixed along the way

## Other

* [`CONTRIBUTING.md`](CONTRIBUTING.md) — engineering standards for this repo
* [`AI_CONTRIBUTIONS.md`](AI_CONTRIBUTIONS.md) — which AI tools were used, and for what
* [`LICENSE`](LICENSE) — MIT
