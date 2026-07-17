# 📖 Why & How

## Why

This started as a throwaway question. After finishing an earlier hardware project, there were spare parts left over — including this laptop — and I asked an AI search tool what to do with them. "Turn it into a home server" was one of the answers, and that's genuinely where this began.

I had no prior experience running a server, no background in networking or Linux administration, and no formal plan. What I had was old hardware, curiosity, and access to several different AI tools that I used to research, plan, and execute each step — cross-checking one against another rather than trusting any single source blindly. `AI_CONTRIBUTIONS.md` breaks down which tool did what.

The starting goal was simple and personal: **automatic photo backup from phones (both Android and iOS) that doesn't depend on a third-party cloud service.** Everything else — the DNS sinkhole, the reverse proxy, the portfolio site — got added because they were useful or interesting along the way, not because they were part of an original master plan.

## How

The approach, in order:

1. **Establish a stable, headless base.** Ubuntu Server, no GUI, lid-close suspend disabled via systemd, so the laptop can run permanently closed on a shelf.
2. **Separate fast and bulk storage.** OS, Docker, and databases on the SSD; bulk file storage on the HDD in the old optical bay. Details in `docs/HARDWARE.md` and `docs/architecture/STORAGE_NETWORKING.md`.
3. **Build the network layer first.** Pi-hole for DNS-level ad blocking, Caddy as the single edge proxy handling ports 80/443 so every future service gets a clean subdomain instead of a bookmarked port number.
4. **Pick self-hosted software that respects the hardware limits.** 4GB of RAM and no hardware video transcoding ruled out several popular options (Nextcloud, Plex-style transcoding). Immich was chosen for photo backup specifically *with* machine learning and transcoding disabled — a deliberate tradeoff of features for stability. That reasoning is logged in `docs/engineering-log/PHASE3_SERVICES_PROXY.md`.
5. **Fix things as they broke, and keep the failures.** Several real mistakes happened along the way — a firewall that got disabled during troubleshooting and silently stayed off, a database image incompatibility, a boot-loop caused by the laptop's missing battery. Those are documented in `docs/troubleshooting/`, on purpose, instead of being quietly cleaned up. The point of this repository is the actual process, mistakes included, not a polished retelling.

## What's Next

See `docs/STATUS.md` for what's actually running versus what's still planned.
