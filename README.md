ARSLANIUS — Portable Mini Operating System built on Windows CMD

ARSLANIUS is an experimental portable mini‑operating system implemented entirely in Windows Batch (CMD).
Starting from version 16, the project evolves from simple prototypes into a structured OS‑like environment with its own kernel, registry, user system, services, restore points, and application ecosystem.

The system can run directly from a USB drive and automatically initializes itself on first launch.

[video](https://youtu.be/iBs5imWNbdo)
---

Features

• Boot menu with Safe Mode
• User accounts: SYSTEM, SYSTEM ADMINISTRATOR, GUEST
• Access control and privilege elevation
• Background services (SysPulse, SFC_Daemon)
• Automatic kernel generation and repair
• Restore Points and System Restore
• ARSLANIUS Archive format (.arc) with pack/unpack tools
• ArslanScript Interpreter
• ArslanScript Compiler (as-2-bat)
• ARS Store (application installer)
• HTML‑based system reports
• Portable architecture using %~dp0
• Full event logging


---

System Structure

ARSLANIUS/
  ├─ ARSLANIUS 18.cmd
  ├─ Setting And System Files/
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


---

How to Run

1. Copy the ARSLANIUS folder to any location (USB recommended).
2. Launch ARSLANIUS 18.cmd.
3. On first boot, press R to generate the kernel.
4. Log in as SYSTEM ADMINISTRATOR.
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
