# Troubleshooting: UFW Firewall — From Undocumented Gap to Verified Enforcement

This diagnostic sheet documents the discovery that the host firewall had been silently disabled since Phase 1, and the remediation that brought the live rule set in line with the policy previously (and inaccurately) documented in `STORAGE_NETWORKING.md`.

---

## 💥 Symptom & Diagnostic Profile

### The Gap
* 💥 During Phase 1 SSH troubleshooting, `sudo ufw allow 22/tcp` was immediately followed by `sudo ufw disable` to unblock a connection-refused issue.
* 💥 This was never reversed or re-documented. Every service deployed afterward (Caddy, Pi-hole, Immich) was done with **no host firewall active at all**.
* 🤖 The architecture docs, however, described a fully enforced rule set (SSH/HTTP/HTTPS allowed, DNS and dashboard LAN-restricted) — a policy that existed only on paper.

---

## 🛠️ Technical Remediation

### 🛠️ Step 1: Confirm Current State
```bash
sudo ufw status verbose
# Status: inactive
```

### 🛠️ Step 2: Set Default-Deny Posture
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### 🛠️ Step 3: Allow SSH Before Anything Else (Lockout Prevention)
```bash
sudo ufw allow 22/tcp comment 'SSH'
```
🤖 **Verification before proceeding:** confirmed sshd was actually listening on the expected port via `sudo ss -tlnp | grep ssh` prior to enabling, to avoid enabling a firewall around the wrong port.

### 🛠️ Step 4: Allow Required Service Ports
```bash
sudo ufw allow 80/tcp comment 'HTTP - Caddy'
sudo ufw allow 443/tcp comment 'HTTPS - Caddy'
sudo ufw allow 443/udp comment 'HTTP3 - Caddy'
sudo ufw allow from 192.168.55.0/24 to any port 53 comment 'Pi-hole DNS - LAN only'
sudo ufw allow from 192.168.55.0/24 to any port 8080 comment 'Pi-hole dashboard - LAN only'
```
📦 **Design decision:** DNS (53) and the Pi-hole dashboard (8080) are scoped to the home LAN subnet only, since neither has any reason to be reachable from outside the network. Immich's port `2283` was deliberately left with **no rule at all** — it's only reachable through Caddy's reverse proxy, enforcing port isolation rather than just documenting it as a goal.

### 🛠️ Step 5: Enable
```bash
sudo ufw enable
# Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
# Firewall is active and enabled on system startup
```

### 📊 Step 6: Verify
```bash
sudo ufw status numbered
```
```text
[ 1] 22/tcp                     ALLOW IN    Anywhere                   # SSH
[ 2] 80/tcp                     ALLOW IN    Anywhere                   # HTTP - Caddy
[ 3] 443/tcp                    ALLOW IN    Anywhere                   # HTTPS - Caddy
[ 4] 443/udp                    ALLOW IN    Anywhere                   # HTTP3 - Caddy
[ 5] 53                         ALLOW IN    192.168.55.0/24            # Pi-hole DNS - LAN only
[ 6] 8080                       ALLOW IN    192.168.55.0/24            # Pi-hole dashboard - LAN only
[ 7] 22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH
[ 8] 80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP - Caddy
[ 9] 443/tcp (v6)               ALLOW IN    Anywhere (v6)              # HTTPS - Caddy
[10] 443/udp (v6)               ALLOW IN    Anywhere (v6)              # HTTP3 - Caddy
```

📊 **Post-verification check:** a second, independent SSH session was opened and confirmed connectable before the original troubleshooting session was closed, to rule out a lockout from a stale connection masking a bad rule set.

---

## 🤖 Known Limitation

Rules 5 and 6 (LAN-restricted DNS and Pi-hole dashboard) are IPv4-only, since `192.168.55.0/24` has no IPv6 equivalent expressed here. A device reaching either service over IPv6 would be blocked outright rather than LAN-scoped. This fails closed, not open — a usability gap, not a security one — but worth knowing if a LAN device mysteriously can't reach Pi-hole.

## 📊 Outcome

`docs/architecture/STORAGE_NETWORKING.md` has been updated to describe this verified, active rule set rather than the aspirational one it previously documented.
