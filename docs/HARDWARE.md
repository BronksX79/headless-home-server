# 🖥️ Hardware

## The Machine

A **Fujitsu LifeBook AH530** — a consumer laptop from roughly 2010, pulled out of storage after a previous hardware project left it and a few other spare parts sitting unused. Nothing here was bought for this project; it's built entirely from parts that already existed.

| Component | Specification | Notes / Constraints |
| :--- | :--- | :--- |
| **Chassis** | Fujitsu LifeBook AH530 | ~15 years old at time of deployment |
| **Processor** | Intel Pentium P6100 @ 2.00GHz | 2 cores / 2 threads. No AES-NI (no hardware crypto acceleration). No Quick Sync (no hardware video transcoding). |
| **Memory** | 4GB DDR3 (1066 MHz) | Hard ceiling — the single biggest constraint on what this server can run. |
| **System Drive** | Lexar NS100 128GB SATA SSD | Runs OS, Docker engine, and databases. Replaced the original spinning HDD. |
| **Storage Drive** | Seagate Mobile 1TB HDD | Mounted via an optical-bay caddy adapter, in the slot the DVD drive used to occupy. Bulk photo/media storage. |
| **Network** | Realtek RTL8111 Gigabit Ethernet | Wired connection only — no reliance on the laptop's aging Wi-Fi card. |
| **Battery** | Removed | Runs mains-power only. See `docs/troubleshooting/BOOT_LOOP_REMEDIATION.md` for why this matters. |

## Cost

Not applicable — every component was already owned from a prior project. This is a repurposing exercise, not a purchase.

## Why This Hardware, Despite the Limits

Two cores, no hardware transcoding, no crypto acceleration, and 4GB of RAM rule out a lot of the "normal" self-hosted stack (Nextcloud, Plex with transcoding, anything Java-heavy). That constraint is treated as a design input rather than a blocker throughout this project — see `docs/PROJECT_STORY.md` for how it shaped the choice of services, and `docs/architecture/STORAGE_NETWORKING.md` for how the two drives and network are actually laid out.
