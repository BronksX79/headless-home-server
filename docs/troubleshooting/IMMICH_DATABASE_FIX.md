# Troubleshooting: Resolving Immich v3 Database Integration Faults

This diagnostic sheet details the resolution of container database crashes and microservices workers initialization loops.

---

## 💥 Symptom & Diagnostic Profile

### The Software Failure
* 💥 The `immich_server` container went into an infinite reboot loop, constantly displaying a status of `(health: starting)` before failing.
* 💥 Web browsers received an immediate `ERR_CONNECTION_REFUSED` error when trying to connect to Port `2283`.

### Error Logs Captured
```text
docker logs immich_server

Error: No vector extension found. Available extensions: vchord, vector
    at getVectorExtension (/usr/src/app/server/dist/repositories/database.repository.js:51:15)
microservices worker exited with code 1
Killing api process
```

### Root Cause Analysis
* The deployment pulled down the latest core release of the Immich engine (v3.x).
* Immich v3 completely deprecated older database dependency extensions (the `tensorchord/pgvecto-rs` image).
* The application now strictly requires the VectorChord (`vchord`) database extension to handle vector searches and AI image indexing.
* Because the initial compose file referenced the obsolete `pgvecto-rs` PostgreSQL image, the server threw validation failures on startup and crashed the runtime loop.

---

## 🛠️ Technical Remediation

To upgrade your database container and achieve a healthy deployment state, implement the following steps:

* 🛠️ **Step 1: Shutdown current services:** Navigate to your Immich directory and stop the active containers:
```bash
cd ~/immich
docker compose down
```
* 🛠️ **Step 2: Edit the compose file:** Open your configuration file:
```bash
nano docker-compose.yml
```
* 🛠️ **Step 3: Update the database image:** Locate the `database:` service block. Wipe the old image line and replace it with the official, VectorChord-packaged postgres image:
```yaml
database:
    container_name: immich_db
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
```
* 🛠️ **Step 4: Pull and rebuild the stack:** Force Docker to fetch the new database layers and recreate the instances:
```bash
docker compose pull
docker compose up -d --force-recreate
```
* 📊 **Step 5: Verify health status:** Wait 30 seconds and check active ports. The server should report a healthy status:
```bash
docker ps
# Output: immich_server ... Up (healthy) ... 2283->2283/tcp
```
