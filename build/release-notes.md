**mOS 1.0 Amber (0.6.2 preview)**

- **mOS password pop-up**: when the Store, Software update or Settings needs your password, you now get an mOS window in your colours instead of KDE's. KDE's dialog stays as a backup and takes over by itself if the mOS one ever stops
- **New Start button**: the Amber mOS logo with a solid white m, filling your icon shape (circle, squircle or rounded square)
- **App names on the taskbar**: open apps show their name next to the icon, like Windows 10. Turn it off in Settings → Taskbar
- **Files like Windows 11 File Explorer**: an address row on top, then New, Cut, Copy, Paste, Rename, Delete, Sort and View. Double-click opens things
- **No more doubles**: KDE System Settings, Info Center, KDE Welcome, Kate, Konqueror and other KDE apps that mOS replaces are hidden from Start and search. Searching "wifi", "bluetooth" or "printers" brings up mOS Settings

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
