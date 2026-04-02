ARSLANIUS — Portable Mini Operating System built on Windows CMD

PLEASE SEND YOUR IDEAS

ARSLANIUS is an experimental portable mini‑operating system implemented entirely in Windows Batch (CMD).
Starting from version 16, the project evolves from simple prototypes into a structured OS‑like environment with its own kernel, registry, user system, services, restore points, and application ecosystem.

[SERVER VERSION](https://github.com/Armsoup/ARSLANIUS_Server)

The system can run directly from a USB drive and automatically initializes itself on first launch.
---

Features

• Boot menu with Safe Mode

• User accounts: SYSTEM, SYSTEM ADMINISTRATOR, GUEST

• Access control and privilege elevation

• Background services (SysPulse, SFC_Daemon)

• Recovery Environment

• Restore Points and System Restore

• ARSLANIUS Archive format (.arc) with pack/unpack tools

• ARS Store (application installer)

• HTML‑based system reports

• Portable architecture using %~dp0

• Full event logging


---

System Structure

ARSLANIUS/

  ├─ ARSLANIUS 23.cmd

  ├─ Backup/
  
  ├─ Settings And System Files/
  
  │   ├─ kernel.dll

  │   ├─ REG.cfg
  
  │   ├─ system.log
  
  │   └─ systemprofile/
  
  ├─ Users/
  
  ├─ Programs/
  
  └─ RestorePoints/
  


---

Included Versions

• ARSLANIUS 16 — first OS‑level architecture

• ARSLANIUS 17 — improved logic and interface

• ARSLANIUS 18 Release — subsystem model, services, ACL

• ARSLANIUS 18 SP1 — portable core, improved services, HTML reports

• ARSLANIUS 19 - added commands on logon screen 

• ARSLANIUS 20 - Added Password Encryption, updated ArsStore, passwd and reset

• ARSLANIUS 21 - Added "reboot_to_recovery" command.

• ARSLANIUS 22 - SYSTEM is now BarOS AUTHORITY\SYSTEM, sysinfo added, logging logic updated.

• ARSLANIUS 23 - added backup backup-restore commands.
---
• ATTENTION! Support for the versions on which the [server version](https://github.com/Armsoup/ARSLANIUS_Server) is based will continue until support for that server version is discontinued.

Unsupported versions:

· ARSLANIUS 16

· ARSLANIUS 17

· ARSLANIUS 18

· ARSLANIUS 19

· ARSLANIUS 20

  These versions are no longer maintained. Please use the latest release (ARSLANIUS 23) for an up-to-date and secure experience.
  
  What does it mean is not supported? This means that all errors found will not be corrected only if they are not critical
  
How to Run

1. Copy the ARSLANIUS folder to any location (USB recommended).
2. Launch ARSLANIUS 23.cmd.
3. On first boot, press R to generate the kernel.
4. Log in as SYSTEM ADMINISTRATOR / Jiupolaqmn_isArslanius-lo
5. Create a user account.
6. Log in — the system will finish setup automatically.


---

Requirements

• Windows 7 / 8 / 10 / 11

• CMD with delayed expansion enabled


---

License

This project is free to use, study, and modify.
Provided “as is”, without warranty.
