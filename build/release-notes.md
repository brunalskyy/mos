**mOS 1.0 Amber (0.7.3 preview)**

- **See-through Liquid Glass taskbar**: 70% see-through like TranslucentTB on Windows, with no more grey haze, and Liquid Glass frost, bending edges and rim on top
- **Taskbar always floats**: it stays rounded and floating even with a maximised window, and windows slide underneath it so you see them through the glass
- **Clock sets itself**: mOS now syncs the time from the internet (Settings > Date & time > Set time automatically)

Heads up: on a physical machine, drivers for your hardware may not all be installed yet. In VMware it runs fine, but some features may be limited.

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

Heads up: on a physical machine, drivers for your hardware may not all be installed yet. In VMware it runs fine, but some features may be limited.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
