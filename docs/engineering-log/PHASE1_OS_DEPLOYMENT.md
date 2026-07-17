# Engineering Log: Phase 1 — OS Deployment & Headless Network Access

This log documents the hardware diagnostics, minimal operating system provisioning, and initial headless configuration.

---

## 📦 Host Hardware Specifications

| Component | Physical Specification | Diagnostic Status |
| :--- | :--- | :--- |
| **System** | Fujitsu LifeBook AH530 Laptop | Healthy |
| **Processor** | Intel Pentium P6100 (2.00GHz) | Active (No AES-NI/Quick Sync) |
| **Memory** | 4GB DDR3 RAM (1066 MHz) | Healthy (3.9Gi recognized) |
| **Boot Drive** | Lexar NS100 128GB SATA SSD | Formatted (ext4 on `/dev/sda2`) |
| **Network** | Realtek RTL8111 Gigabit Ethernet | Link up (Interface: `enp5s0`) |
| **Peripherals** | External HDMI Monitor / USB Keyboard | Disconnected post-install |
| **Battery** | Lithium-ion cells uninstalled | Removed (Mains-only operation) |

---

## ⚙️ Chronological Milestones & Resolutions

### ⚙️ Milestone 1.1: Pre-Flight Diagnostics
* ⚙️ **Objective:** Verify system component health before installing the OS.
* ⚙️ **Execution:** Booted Puppy Linux (BookwormPup64) via Ventoy USB.
* 💥 **Diagnostic Hurdle:** The standard `sensors` package was absent.
* 🛠️ **Remediation:** Queried raw kernel files to read thermals:
```bash
cat /sys/class/thermal/thermal_zone*/temp
```
* 🤖 **Diagnostic Result:** System reported a stable 56°C idle.
* 🤖 **Diagnostic Result:** Core memory was verified at 3.9Gi.
* 🤖 **Diagnostic Result:** Drives `sda` (SSD) and `dev/sdb` (HDD) detected.

### ⚙️ Milestone 1.2: OS Installation & Custom Partitioning
* ⚙️ **Objective:** Install minimal Ubuntu Server on the Lexar SSD.
* 💥 **Partition Hurdle:** Installer defaulted to logical volume groups (LVM).
* 🛠️ **Remediation:** Deselected LVM option during manual partition phase.
* 💥 **Target Hurdle:** Installer targeted the secondary 1TB HDD.
* 🛠️ **Remediation:** Manually selected `/dev/sda` (Lexar SSD) for installation.
* 💥 **Boot loader Hurdle:** Done button locked on unallocated SSD space.
* 🛠️ **Remediation:** Created two custom partitions on the SSD:
  * partition 1 (bios_grub): Created 1MB boot partition.
  * partition 2 (ext4): Formatted remaining space to `/`.
* 🛠️ **SSH Ingress:** Marked checkbox `[X] Install OpenSSH server`.

### ⚙️ Milestone 1.3: Closed-Lid Suspend Override
* ⚙️ **Objective:** Prevent the server from sleeping when closed.
* 💥 **Configuration Hurdle:** Accessing `logind.conf` returned an empty file.
* 🛠️ **Remediation:** Exited file and used shell tab-completion:
```bash
sudo nano /etc/systemd/logind.conf
```
* ⚙️ **Configuration Update:** Uncommented and updated power policies:
```text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
```
* ⚙️ **Service Reload:** Restarted the login manager service:
```bash
sudo systemctl restart systemd-logind
```

### ⚙️ Milestone 1.4: Post-Install Headless Connection
* ⚙️ **Objective:** Disconnect display peripherals and manage via SSH.
* 💥 **Hardware Loop Hurdle:** Laptop fans spun high but halted boot.
* 🛠️ **Remediation:** Performed cold boot with physical lid open.
* 💥 **Network Resolution Hurdle:** Connection timed out on IP 108.
* 🛠️ **Remediation:** Logged in locally to read actual interface IP:
```bash
hostname -I
```
* 🤖 **Network Discovery:** Local address resolved to `192.168.55.233`.
* 💥 **Port 22 Handshake Hurdle:** Connection refused on Port 22.
* 🛠️ **Remediation:** Logged in locally to update firewall parameters:
```bash
sudo ufw allow 22/tcp
sudo ufw disable
sudo systemctl enable --now ssh
```
* 🛠️ **Final Remote Validation:** SSH login established from desktop:
```bash
ssh amin@192.168.55.233
```

> ⚠️ **Note added retroactively:** the `sudo ufw disable` step above was never reversed at the time, and the server ran with no host firewall at all through the rest of this deployment. See `docs/troubleshooting/FIREWALL_HARDENING.md` for the fix.

---

## 📊 Post-Phase 1 Power Recovery Protocol

Because the server runs without battery backing, power loss causes hard shutdowns. Follow this physical protocol during recovery:

* 📊 1. System State: Motherboard clock resets; laptop remains off.
* 📊 2. Physical Step: Move server, open physical screen lid.
* 📊 3. Power Initialization: Tap physical power button once.
* 📊 4. Kernel Boot Time: Wait 60 seconds with open lid.
* 📊 5. Headless Transition: When Ethernet lights flash, close lid.
