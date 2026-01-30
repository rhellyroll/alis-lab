# ALIS F-35 Shipboard Offline Repository

**Air-gapped RHEL 9 update system for extended F-35 deployments**

---

## Problem Statement

F-35 aircraft deployed to forward operating bases (e.g., Rovaniemi AB, Finland; Misawa AB, Japan; RAF Lakenheath, UK) routinely operate for **30–60+ days without external network access**. The supporting ALIS ground infrastructure runs **RHEL 9** but is unable to reach the Red Hat CDN during shipboard, carrier-based, or austere operations.

**Operational impact**: Inability to apply security updates during extended offline periods introduces unacceptable cyber risk to mission-critical systems.

This project addresses that gap with a **controlled, auditable, STIG-aligned offline update mechanism** suitable for denied or disconnected environments.

---

## Solution Overview

A portable, air-gapped RHEL 9 repository designed for forward deployment:

* Local RPM repository with explicit dependency resolution
* Physical media (USB/ext4) for ship-to-shore or enclave transfer
* Apache httpd for standardized repository access
* DISA STIG-aligned security controls
* Cryptographic validation of packages and repository metadata
* Lightweight operational monitoring for deployed NOC teams

This design prioritizes **operational realism**, **security**, and **maintainability** over full-mirror complexity.

---

## Technical Implementation

### Repository Package Staging

Only mission-critical system and security packages are staged to minimize attack surface and validation overhead.

```bash
dnf download --resolve \
  --destdir=/var/www/html/repos/alis-shipboard-packages/Packages/ \
  bash curl vim tar wget gzip audit firewalld

createrepo_c /var/www/html/repos/alis-shipboard-packages/
```

**Result**:

* 53 RPMs
* ~83 MB total size
* Full dependency closure for selected packages

---

### Kernel Update & Lifecycle Management

Kernel updates in ALIS-supported environments directly affect driver compatibility, timing, and aircraft availability. Kernel handling is intentionally conservative.

**Design decisions**:

* Kernel RPMs are staged but never auto-applied
* Running kernel version is explicitly validated
* Kernel drift is prevented during extended offline operations

```bash
uname -r
rpm -qa kernel
dnf versionlock add kernel*
```

**Operational controls**:

* Kernel updates require approved maintenance windows
* Reboots are coordinated with sortie schedules
* Rollback capability preserved via `dnf history`

This approach improves security posture **without risking mission interruption or aircraft grounding**.

---

### Repository Integrity & Supply Chain Security

RPM signature verification alone is insufficient in air-gapped environments. Repository metadata integrity is also enforced.

```bash
gpg --detach-sign --armor repodata/repomd.xml
```

Client-side enforcement:

```ini
gpgcheck=1
repo_gpgcheck=1
```

**Result**:

* Prevents metadata tampering
* Detects unauthorized package insertion
* Maintains end-to-end supply chain trust across physical transfer

---

### Apache Repository Service (Hardened)

Apache httpd is used intentionally to preserve standard `dnf` workflows across multiple ALIS nodes.

**Rationale**:

* Consistent update mechanism across systems
* No operator retraining required
* Centralized access logging and auditability

**Hardening controls**:

```bash
setsebool -P httpd_can_network_connect on
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
getenforce  # Enforcing
```

* Static content only (no CGI or scripting)
* SELinux enforcing
* Firewall restricted to HTTP service

---

### Air-Gapped USB Bundle Creation

A portable ext4 image is used for predictable Linux compatibility and journaling support.

```bash
dd if=/dev/zero of=/tmp/alis-usb-200mb.img bs=1M count=200
mkfs.ext4 -L "ALIS-UPDATES" /tmp/alis-usb-200mb.img
mount /tmp/alis-usb-200mb.img /mnt/alis-usb
cp -r /var/www/html/repos/alis-shipboard-packages/* /mnt/alis-usb/
```

**Result**:

* Deterministic 200 MB update bundle
* Suitable for shipboard, courier, or SCIF-to-SCIF transfer

---

### Removable Media Security Controls

Removable media represents a primary attack vector in disconnected DoD networks.

```bash
mount -o ro,noexec,nodev,nosuid /dev/loop0 /mnt/alis-usb
sha256sum -c MANIFEST.txt
```

**Controls implemented**:

* Read-only mounting
* Execution and device nodes disabled
* Mandatory manifest verification prior to use
* auditd logging of mount and access events

Any checksum mismatch invalidates the update set.

---

### Cryptographic Package Verification

All RPMs are validated using Red Hat GPG keys prior to installation.

```bash
rpm --checksig /var/www/html/repos/alis-shipboard-packages/Packages/*.rpm
```

**Result**: All packages verified as authentic and untampered.

---

### Operational Status Monitoring

A lightweight Bash-based status script provides deployed operators with immediate visibility.

```bash
#!/bin/bash
echo "═══ ALIS SHIPBOARD STATUS ═══"
echo "RPM Count: $(ls /var/www/html/repos/alis-shipboard-packages/Packages/*.rpm | wc -l)"
echo "USB Bundle Size: $(ls -lh /tmp/alis-usb-200mb.img | awk '{print $5}')"
echo "HTTP Status: $(systemctl is-active httpd)"
tail -3 /var/log/httpd/access_log
```

No Python or external dependencies are required.

---

## Deployment Scenarios

| Location              | Operational Context        | Transfer Method                      |
| --------------------- | -------------------------- | ------------------------------------ |
| Rovaniemi AB, Finland | Extended Arctic operations | USB courier between secure enclaves  |
| Misawa AB, Japan      | Carrier and shipboard ops  | Ship-to-shore physical media         |
| RAF Lakenheath, UK    | Rotational deployments     | Encrypted transfer during port calls |

---

## Program Context: ALIS and ODIN

This solution is applicable to:

* Legacy ALIS environments currently in service
* Transitional ALIS → ODIN hybrid deployments

The design reflects current fleet realities rather than future-only architectures.

---

## Known Constraints & Risk Management

Extended offline operations introduce unavoidable constraints:

* Certificate expiration over long durations
* Kernel updates requiring coordinated reboots
* Hardware driver compatibility risks

These risks are managed through:

* Version locking
* Staged updates
* Explicit maintenance authorization

Risks are documented and controlled, not ignored.

---

## Skills Demonstrated

* RHEL 9 administration in disconnected environments
* Offline repository design and dependency management
* DISA STIG-aligned system hardening
* Supply chain integrity and cryptographic validation
* Operational risk management for deployed systems
* Bash automation for repeatable operations

---

*This project demonstrates production-ready Linux administration for maintaining F-35 ALIS infrastructure during extended offline and forward-deployed operations.*
