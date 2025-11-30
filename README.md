# Windows-Full-Repair-Tool

What I did:

* The script self-elevates to admin, safely restarts Explorer and shell hosts, clears icon/taskbar caches, re-registers Start Menu/Shell appx packages, restarts audio services, runs DISM and SFC, resets Windows Update components, and collects recent Application errors into a log.

How to use it:

1. Save the canvas file as `Windows_Full_Repair_Tool.bat` on your PC (you can copy from the canvas).
2. Right-click **Run as administrator**.
3. Close all apps before running. The script will log progress to a file in `%TEMP%` and will pause at the end so you can note the logfile path.

Warnings & notes:

* This script makes system-level changes. Back up important work first.
* The DISM and SFC steps can take 10–30 minutes depending on your PC.
* If you have custom Start Menu / shell tweaks (third-party shells, heavy tweakers, or debloat tools), they may conflict — tell me if you use any of those.
* If the problem persists after running and rebooting, paste the logfile `%TEMP%\\win_repair_... .log` here (or the `RecentAppErrors.txt`) and I’ll analyze it and give next steps.

Want me to add an optional step to also check for GPU driver crashes, or to create a smaller quick-fix version that only restarts Explorer and audio services?
