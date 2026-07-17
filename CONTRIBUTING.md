# Engineering Contribution Guidelines

This document outlines the technical standards, branching models, and pre-commit validation procedures for modifying configurations or adding services to the headless home server.

---

## 🛠️ Contribution Workflow

* 🛠️ **Repository Isolation:** All development must occur on separate feature or bugfix branches.
* 🛠️ **Branch Naming Standard:** Use semantic prefixes: `feature/`, `bugfix/`, `docs/`, or `refactor/`.
* 🛠️ **Main Branch Integrity:** Direct commits to the `main` branch are strictly prohibited.
* 🛠️ **Pull Request Verification:** Pull requests must reference an active issue or engineering log entry.

---

## 📦 Technical Configuration Standards

### 📦 Docker Compose YAML Standards
* 📦 **Indentation:** Strictly use spaces for indentation; tab characters are prohibited.
* 📦 **Specification Tense:** Omit the obsolete `version` attribute from all compose files.
* 📦 **Resource Hardening:** Always declare explicit memory limits on resource-heavy containers.
* 📦 **Volume Bindings:** Map container data volumes strictly to `/mnt/storage/docker/[service_name]`.

### 📦 Environment Variable Hygiene (`.env`)
* 📦 **Syntax Structure:** Declare variables cleanly with no spaces surrounding the `=` operator.
* 💥 **Escape Prevention:** Avoid enclosing database credentials in raw single-quotes (`'`).
* 💥 **String Mismatches:** Enclosing characters in single-quotes can cause PostgreSQL parsing failures.

### 📦 Caddy Proxy Directives (`Caddyfile`)
* ⚙️ **Formatting Utility:** Always execute `caddy fmt --overwrite` on modified Caddyfiles.
* ⚙️ **Scheme Declarations:** Explicitly declare the `http://` or `https://` protocol scheme.
* ⚙️ **DNS Integration:** Ensure every new proxy host maps to an active record in Pi-hole.

---

## ⚙️ Git Commit Message Standards

Contributions must use structured, semantic commit messages to preserve a clean git history:

```text
<type>: <short description in present tense>

[optional body providing technical justification or context]
```

### Approved Commit Types
* `feat`: Deploys a new containerized service or system capability.
* `fix`: Resolves an active infrastructure bug or configuration fault.
* `docs`: Modifies technical logs, specs, readmes, or guides.
* `refactor`: Restructures existing configuration files without altering active states.
* `test`: Introduces system verification, network pings, or diagnostic scripts.

---

## 📊 Pre-Commit Validation Protocols

Before submitting a pull request, run these validation procedures on your local testing environment:

### 📊 1. Validate Docker Compose Blueprints
Run the config parsing utility to check for indentation or structural syntax errors:
```bash
docker compose -f /mnt/storage/docker/[service]/docker-compose.yml config
```

### 📊 2. Validate Caddyfile Routing Syntax
Verify that the edge proxy can safely parse and adapt the updated rules:
```bash
docker compose -f /mnt/storage/docker/caddy/docker-compose.yml exec caddy caddy validate --config /etc/caddy/Caddyfile
```

### 📊 3. Verify Local DNS Integration
Query the local DNS resolution engine to ensure the domain matches the host:
```bash
dig @192.168.55.233 [new_subdomain].local
```
