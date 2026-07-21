# Troubleshooting: Docker/UFW Port Exposure & Network Isolation Migration

This diagnostic sheet documents a gap discovered after adding two new services (`homepage`, `filebrowser`) alongside Immich: Docker's own iptables rules take effect before UFW's, meaning published container ports were reachable regardless of firewall configuration.

---

## 💥 Symptom & Diagnostic Profile

### The Gap
* 💥 `sudo ufw status verbose` showed a correctly configured, active firewall.
* 💥 `sudo ss -tlnp` showed three ports listening that UFW had never explicitly allowed: `2283` (Immich), `3000` (homepage), `8090` (filebrowser).
* 🤖 **Root cause:** Docker manages its own `iptables` rules independently of UFW. Any container that publishes a port with `ports:` in its compose file is reachable regardless of UFW's rule set — Docker's rules take precedence. This is a well-documented Docker/UFW interaction, not a misconfiguration specific to this server.
* 🤖 This meant the claim in `docs/architecture/STORAGE_NETWORKING.md` — that Immich's port 2283 was "not opened, reachable only via Caddy" — was true at the UFW level but false in practice.

### Compounding Issue Found Mid-Fix
* 💥 While sharing compose files for review, the Pi-hole `WEBPASSWORD` was pasted in plaintext into an external chat log.
* 🛠️ **Remediation:** Password rotated via `docker exec -it pihole pihole setpassword`, and the `WEBPASSWORD` environment variable removed entirely from `docker-compose.yml` — leaving it in place would have silently reset the password back to the leaked value on the next container recreation, since Pi-hole reapplies that env var on every start if present.

---

## 🛠️ Technical Remediation

### 🛠️ Step 1: Create a Shared Internal Network
```bash
docker network create proxynet
```
This is a Docker bridge network that only Caddy and the services it proxies to join — not published to the host at all.

### 🛠️ Step 2: Remove Host Port Publishing, Add `proxynet`
For `immich-server`, `homepage`, and `filebrowser`: deleted the `ports:` block entirely from each service definition, and added:
```yaml
networks:
  - proxynet
```
Caddy itself keeps its `ports:` block (80/443) — it's the only container intended to be reachable from the host network directly.

### 🛠️ Step 3: Route by Container Name, Not Host IP
Updated the Caddyfile so reverse proxy targets reference container names (resolvable via Docker's internal DNS on `proxynet`) instead of the host's LAN IP:
```
http://photos.local {
    reverse_proxy immich_server:2283
}
http://home.local {
    reverse_proxy homepage:3000
}
http://files.local {
    reverse_proxy filebrowser:80
}
```

### 🛠️ Step 4: Recreate and Verify
```bash
docker compose up -d --force-recreate   # for each affected stack, Caddy last
sudo ss -tlnp                            # confirm 2283/3000/8090 no longer listed
```

### 📊 Step 5: Add Local DNS Records
Added `photos.local`, `home.local`, `files.local` (and pre-existing `pi.home`) as A-records in Pi-hole's **Local DNS → DNS Records**, so any device on the LAN — not just the server itself — can resolve them.

---

## 📊 Outcome

Confirmed via `sudo ss -tlnp` post-migration: only `22`, `53`, `80`, `443`, and `8080` remain listening. Pi-hole (`53`, `8080`) is the one deliberate, documented exception — DNS and its dashboard can't route through an HTTP reverse proxy, so they stay on published host ports, restricted to the LAN subnet via UFW as before.
