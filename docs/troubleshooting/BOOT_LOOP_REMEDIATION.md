# Troubleshooting: Legacy Laptop Boot-Loop Remediation

This diagnostic sheet details the resolution of physical motherboard freezes and CPU fan loops encountered during cold boot operations.

---

## 💥 Symptom & Diagnostic Profile

### The Hardware Failure
* 💥 Upon inserting the main AC power cord, the server fan spins immediately at maximum velocity.
* 💥 The network port lights remain completely dark.
* 💥 The system fails to boot past the BIOS checks; the SSH server daemon remains unreachable.

### Root Cause — Unconfirmed

> ⚠️ **This section previously stated a specific mechanism as confirmed fact** (that the BIOS detects a closed lid at POST and deliberately halts the bootloader while maxing fan speed as a thermal-safety measure "confined space" response). **That mechanism has not been verified against any BIOS/ACPI documentation for this hardware and is likely an invented explanation for an observed symptom.** It is retained below only as an unconfirmed hypothesis, not an engineering conclusion.

**What is actually known:**
1. The server operates on legacy laptop hardware (Fujitsu LifeBook AH530) with the battery cells removed — it runs mains-only, with no internal power buffer.
2. When mains power is disconnected (outage, cord pulled), the system loses power immediately and uncleanly — there is no graceful shutdown.
3. Cold-booting with the lid closed reliably reproduces the fan-max/no-boot symptom; cold-booting with the lid open does not.

**Unconfirmed hypothesis (not verified):** some BIOS/ACPI-level interaction with lid-switch state at POST, before any OS or ACPI table is loaded, may be involved. No corroborating documentation has been found for this specific motherboard. Treat the *workaround* below as empirically reliable; treat the *cause* as an open question.

---

## 🛠️ Restoration & Prevention Protocol

The steps below are verified reliable by repeated trial, independent of whether the root cause above is ever confirmed:

* 🛠️ **Step 1: Terminate the Loop:** Hold the physical power button down for 7 seconds to force a complete shutdown.
* 🛠️ **Step 2: Open the Chassis:** Open the physical laptop screen lid completely.
* 🛠️ **Step 3: Safe Boot Execution:** Tap the physical power button once with the lid fully open.
* 🛠️ **Step 4: Bootloader Processing:** Allow the laptop to run through its BIOS checks with the lid open for exactly **60 seconds**.
* 🛠️ **Step 5: OS Verification:** Watch the Ethernet port. When the green and yellow link lights begin to flash, the Ubuntu kernel has successfully taken over.
* 🛠️ **Step 6: Headless Close:** Close the laptop lid completely and return it to its cupboard/shelf. The systemd logind config will take over, keeping the server awake headlessly.

---

## 📊 Related Risk: No Battery Buffer on Power Loss

Because the battery cells are physically removed, **any mains power interruption is a hard, unclean shutdown** — including for the Postgres container backing Immich. This is a real data-integrity risk, not just an inconvenience:

* 📊 An unclean shutdown mid-write to Postgres carries a nonzero risk of database corruption, separate from the boot-loop issue above.
* 📊 This is currently an **accepted risk**, not a mitigated one. Options if this becomes a priority: a small UPS (even a low-capacity one just needs to bridge long enough for a graceful `docker compose down` via a `nut`/UPS-monitoring script), or accepting the risk and relying on backups (see Planned Developments — offsite rsync mirror) to recover rather than prevent corruption.
