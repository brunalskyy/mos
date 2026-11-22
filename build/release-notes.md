**mOS 1.0 Amber (0.7.2 preview)**

- **mOS right-click menu, for real this time**: KDE's desktop handles right-clicks itself, so mOS now plugs its own menu in the same way KDE's menu does. Right-click the desktop for Add widgets, Edit widgets, New folder, Paste, Open in Terminal, Change wallpaper, Display settings and Settings. After updating, the desktop restarts once by itself to switch over
- **Clearer Liquid Glass**: the taskbar and pop-ups have a much lighter tint, so you see the glass, the bending edges and the shiny rim instead of a grey bar

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
