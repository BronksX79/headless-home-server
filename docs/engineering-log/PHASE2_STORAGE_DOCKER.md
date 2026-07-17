# Engineering Log: Phase 2 — Storage Array & Docker Deployment

This log documents the integration of the secondary storage drive and the deployment of the containerization engine.

---

## 📦 Target Storage Environment

| Device Node | Physical Media | Size | File System | Mount Point | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/dev/sda2` | Lexar NS100 SSD | 119.2GB | `ext4` | `/` | OS, Docker, postgres DB |
| `/dev/sdb1` | Seagate Mobile HDD | 931.5GB | `ext4` | `/mnt/storage` | Data, Mapped Volumes |

---

## ⚙️ Chronological Milestones & Resolutions

### ⚙️ Milestone 2.1: Secondary Drive Diagnostics
* ⚙️ **Objective:** Verify physical connection of caddy hard drive.
* 💥 **Verification Hurdle:** Standard `lsblk` checks omitted unmounted devices.
* 🛠️ **Remediation:** Queried low-level hardware class logs:
```bash
sudo lshw -class disk
```
* 🤖 **Diagnostic Result:** Core system registered Seagate HDD as `/dev/sdb`.

### ⚙️ Milestone 2.2: Partitioning & ext4 Formatting
* ⚙️ **Objective:** Cleanly partition and format the 1TB drive.
* 🛠️ **Execution:** Created GPT partition table using parted:
```bash
sudo parted /dev/sdb --script mklabel gpt mkpart primary ext4 0% 100%
```
* 🛠️ **Execution:** Laid down ext4 filesystem on `/dev/sdb1`:
```bash
sudo mkfs.ext4 /dev/sdb1
```
* 🤖 **System Allocation:** Discovered old ext4 sectors on drive.
* 🛠️ **Remediation:** Overrode sector tables manually by inputting `y`.
* 🤖 **System Allocation:** Unique drive UUID generated: `b5345363-2947-4697-a835-c6f1bdef670a`.

### ⚙️ Milestone 2.3: Boot-Time Mounting Automation
* ⚙️ **Objective:** Ensure the storage partition auto-mounts on boot.
* 🛠️ **Execution:** Created target local directory tree:
```bash
sudo mkdir -p /mnt/storage
sudo mount /dev/sdb1 /mnt/storage
```
* ⚙️ **Configuration:** Appended unique UUID parameters to fstab:
```bash
sudo nano /etc/fstab
```
* ⚙️ **Configuration Entry:**
```text
UUID=b5345363-2947-4697-a835-c6f1bdef670a  /mnt/storage  ext4  defaults  0  2
```
* 🛠️ **Verification:** Reloaded mounts; returned zero error codes:
```bash
sudo mount -a
```

### ⚙️ Milestone 2.4: Docker Engine Installation
* ⚙️ **Objective:** Install the virtualization runtime engine.
* 🛠️ **Execution:** Updated secure keys and prerequisite repositories:
```bash
sudo apt update && sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
* 💥 **Mirror Hurdle:** Package update returned 404 on `resolute` codename.
* 🤖 **Hurdle Analysis:** Ubuntu 26.04 is unreleased; Docker mirrors lack package folders.
* 🛠️ **Remediation:** Pointed repository explicitly to stable `noble` channel:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
* 🛠️ **Execution:** Triggered core package manager update and install:
```bash
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
* 🛠️ **User Permission Setup:** Added user `amin` to docker group:
```bash
sudo usermod -aG docker amin
newgrp docker
```
* 📊 **Operational Verification:** Verified running status; returned empty table:
```bash
docker ps
```
