**mOS 1.0 Amber (0.7.2 preview)**

- **mOS right-click menu, for real this time**: KDE's desktop handles right-clicks itself, so mOS now plugs its own menu in the same way KDE's menu does. Right-click the desktop for Add widgets, Edit widgets, New folder, Paste, Open in Terminal, Change wallpaper, Display settings and Settings. After updating, the desktop restarts once by itself to switch over
- **Liquid Glass you can actually see**: the taskbar and pop-ups are clear glass now, with much less frost and tint, so you see what's behind bending at the edges and the shiny rim, instead of a grey bar
- **See-through taskbar everywhere**: it stays transparent even if Liquid Glass can't load (for example in some VMs), and no longer turns solid when a window is maximised
- **Games tab in the mOS Store works**: it was coming up empty because the page couldn't load

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

Heads up: on a physical machine, drivers for your hardware may not all be installed yet. In VMware it runs fine, but some features may be limited.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
