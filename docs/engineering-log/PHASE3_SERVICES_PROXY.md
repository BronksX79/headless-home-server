# Engineering Log: Phase 3 — Edge Proxy & Multi-Service Routing

This log documents the deployment of local area network services and the edge proxy routing infrastructure.

---

## 📦 Service Runtime Baseline

* 📦 **Data Partition Path:** `/mnt/storage/docker` (Hosted on Seagate 1TB HDD).
* 📦 **Core Proxy Engine:** Caddy Server (Port 80/443 host bindings).
* 📦 **Core DNS Sinkhole:** Pi-hole (Port 53 loopback, Port 8080 dashboard).
* 📦 **Core Storage Cloud:** Immich Photo Suite (Port 2283 backend API).
* 📦 **Static Web Assets:** Responsive HTML portfolio (Served via Caddy).

---

## ⚙️ Chronological Milestones & Resolutions

### ⚙️ Milestone 3.1: Directory Hierarchy & Non-Root Execution
* ⚙️ **Objective:** Establish isolated application folders on the 1TB HDD.
* 🛠️ **Execution:** Created persistent storage targets for Caddy and Pi-hole:
```bash
sudo mkdir -p /mnt/storage/docker/pihole /mnt/storage/docker/caddy
sudo chown -R amin:amin /mnt/storage/docker
```

### ⚙️ Milestone 3.2: Port 53 Binding & System Resolver Masking
* ⚙️ **Objective:** Free Port 53 from the host operating system.
* 💥 **Binding Hurdle:** Deployed containers crashed; Port 53 was already occupied.
* 🤖 **Hurdle Analysis:** Ubuntu runs `systemd-resolved` socket listeners by default.
* 🛠️ **Remediation:** Stopped and masked the network resolver daemon:
```bash
sudo systemctl stop systemd-resolved
sudo systemctl mask systemd-resolved
sudo systemctl stop systemd-resolved-monitor.socket systemd-resolved-varlink.socket
sudo systemctl mask systemd-resolved-monitor.socket systemd-resolved-varlink.socket
```
* 🛠️ **Execution:** Recreated `/etc/resolv.conf` with external upstream paths:
```bash
sudo rm -f /etc/resolv.conf
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" | sudo tee /etc/resolv.conf > /dev/null
sudo chattr +i /etc/resolv.conf
```
> 🤖 **Note:** the `chattr +i` above makes this file immutable at the filesystem level. It's the correct way to stop `systemd-resolved` from overwriting it, but it also means any future `netplan apply`, DHCP renewal, or reinstall that tries to rewrite this file will fail with a permission error that doesn't obviously look like a permissions problem. Worth remembering if DNS resolution mysteriously breaks after an unrelated network change.

### ⚙️ Milestone 3.3: Pi-hole Port 80 Conflict Resolution
* ⚙️ **Objective:** Prevent Port 80 conflicts between Pi-hole and Caddy.
* 💥 **Ingress Hurdle:** Both applications required Port 80 host bindings.
* 🛠️ **Remediation:** Remapped Pi-hole dashboard port to `8080:80` in compose files.
* 🛠️ **Remediation:** Configured Caddy to own standard Ports 80 and 443.
* 🛠️ **Execution:** Deployed Pi-hole stack; returned active healthy state:
```bash
docker compose -f /mnt/storage/docker/pihole/docker-compose.yml up -d
```
* 🛠️ **Credential Reset:** Overrode failed default password configurations:
```bash
docker exec -it pihole pihole setpassword
```

### ⚙️ Milestone 3.4: Immich Setup & Database Remapping
* ⚙️ **Objective:** Deploy low-resource personal photo cloud storage.
* 💥 **Database Hurdle:** Server microservices worker crashed in boot loop.
* 🤖 **Hurdle Analysis:** Immich v3 deprecated old `pgvecto-rs` extension schemas.
* 🛠️ **Remediation:** Swapped image target to the official VectorChord branch:
```yaml
image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
```
* 🛠️ **Execution:** Initialized database, server API, and cache containers:
```bash
docker compose -f ~/immich/docker-compose.yml up -d
```
* ⚙️ **Performance Tuning:** Logged into admin interface to disable ML.
* ⚙️ **Performance Tuning:** Set Video Transcoding to Disabled / Direct Play.

> ⚠️ **Note:** despite the directory standard in `CONTRIBUTING.md` (services under `/mnt/storage/docker/[service_name]`), Immich was deployed and still runs from `~/immich` on the SSD, not `/mnt/storage/docker/immich`. Tracked as an open item in `docs/STATUS.md`.

### ⚙️ Milestone 3.5: Caddy Reverse Proxy & Domain Mapping
* ⚙️ **Objective:** Establish human-readable subdomains for local clients.
* 🛠️ **Execution:** Created the master web routing configurations (Caddyfile):
```text
http://192.168.55.233:80 {
    root * /var/www/portfolio
    file_server
}
http://photos.local:80 {
    reverse_proxy 192.168.55.233:2283
}
http://pi.home:80 {
    reverse_proxy 192.168.55.233:8080
}
```
* 🛠️ **Execution:** Recreated Caddy container and loaded routing changes:
```bash
docker compose -f /mnt/storage/docker/caddy/docker-compose.yml up -d --force-recreate
docker compose exec caddy caddy reload
```
* 🛠️ **Local DNS Mapping:** Added local A-records inside Pi-hole Settings:
  * `photos.local` mapped to `192.168.55.233`
  * `pi.home` mapped to `192.168.55.233`

---

## 📊 Infrastructure Verification Metrics

* 📊 **Static Site Ingress:** `http://192.168.55.233` returns portfolio page.
* 📊 **Proxy Subdomain Ingress:** `http://photos.local` routes to Immich.
* 📊 **Infrastructure Ingress:** `http://pi.home` routes to Pi-hole.
* 📊 **Docker Verification:** All core services running cleanly:
```bash
docker ps
```
