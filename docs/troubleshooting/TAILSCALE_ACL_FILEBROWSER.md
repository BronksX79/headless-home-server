# Troubleshooting: Restricting Filebrowser via Tailscale ACLs

This log documents restricting network-level access to filebrowser specifically, given its ability to directly edit compose files (including, in principle, any service's configuration) — a materially higher-risk capability than any other service on this stack.

---

## 📦 Objective

Every other service (Immich, homepage, Pi-hole, Vaultwarden) should stay reachable from any device on the tailnet. Filebrowser should be reachable from one trusted device only (the primary PC), enforced at the network layer — not just behind its own login screen.

## 💥 The Constraint: Tailscale ACLs Can't See Hostnames

Tailscale ACLs operate on IP address and port, not on HTTP hostnames. Since `photos.local`, `home.local`, `files.local`, and `vault.local` were all reverse-proxied through the same Caddy container on the same shared ports (80/443), they were indistinguishable to an ACL — a rule restricting port 443 would have restricted all of them at once, not filebrowser alone.

**Resolution:** give filebrowser its own dedicated, un-shared port in Caddy, so it becomes something an ACL rule can actually target independently of the other services.

---

## 🛠️ Technical Remediation

### 🛠️ Step 1: Move Filebrowser to a Dedicated Caddy Listener
Removed the `files.local` reverse-proxy block and replaced it with a listener bound to its own port, with no hostname matching at all:
```
# Filebrowser - moved to dedicated port 8091 for Tailscale ACL restriction
:8091 {
    reverse_proxy filebrowser:80
}
```

### 🛠️ Step 2: Publish the New Port from the Caddy Container
```yaml
ports:
  - "80:80"
  - "443:443"
  - "443:443/udp"
  - "8091:8091"
```

### 🛠️ Step 3: Firewall Rule, LAN-Scoped
```bash
sudo ufw allow from 192.168.55.0/24 to any port 8091 comment 'Filebrowser - LAN/Tailscale ACL restricted'
```

### 🤖 Note: Old `files.local` Address Now 308-Redirects, By Design
Once any site in the Caddyfile (`vault.local`) uses automatic HTTPS, Caddy applies a global default: unmatched requests on port 80 get redirected to HTTPS rather than served or 404'd directly. Since `files.local` no longer matches any route, it falls into that catch-all and redirects to a hostname that also doesn't exist — which simply fails, as intended. This is expected behavior, not a misconfiguration; `files.local` was deliberately retired in favor of the dedicated port.

### 🛠️ Step 4: Write the Tailscale ACL Policy
At **Tailscale Admin Console → Access Controls**:
```json
{
  "tagOwners": {
    "tag:trusted": ["<tailscale-account-email>"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:22,53,80,443"]
    },
    {
      "action": "accept",
      "src": ["tag:trusted"],
      "dst": ["*:8091"]
    }
  ]
}
```
Every device on the tailnet can still reach SSH, DNS, and Caddy's normal web ports (so Immich/homepage/Vaultwarden/Pi-hole remain unaffected). Port `8091` accepts connections only from devices explicitly tagged `tag:trusted`.

### 🛠️ Step 5: Tag the Trusted Device
**Admin Console → Machines → (PC) → Edit ACL tags → `tag:trusted`**. Phone left untagged.

---

## 📊 Verification

| Device | Target | Result |
| :--- | :--- | :--- |
| PC (tagged `tag:trusted`) | `http://192.168.55.233:8091` | 200 OK — filebrowser loads |
| Phone (untagged) | `http://192.168.55.233:8091` | Connection timed out — blocked at the network layer |

Confirms the restriction operates independently of filebrowser's own login screen — an untagged device can't reach the service at all, rather than reaching a login prompt it could attempt to brute-force.
