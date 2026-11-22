**mOS 1.0 Amber (0.7.1 preview)**

- **Apple Control Panel** (Macs only, in Start and in the Store under "Apps included with your device"): live fan speed with Automatic, Quiet, Keep cool and Manual modes, temperatures, keyboard light, top row as media keys or F1 to F12, swap Cmd and Option, and battery health with charge cycles
- **Settings opens again** (0.7 broke it)
- **mOS right-click menu works**: KDE was catching right-clicks on empty desktop space before mOS could
- **New password box** on the lock and sign-in screens: one clean field with the arrow button joined on, in your accent colour
- **Your picture on the sign-in screen** when the computer starts, not just after locking
- **Liquid Glass always shows**: the taskbar stays see-through even when a window is maximised
- **Taskbar icons in dark mode**: Wi-Fi, sound and battery are white instead of black
- **Liquid Glass safety check** now knows which KWin it was built for

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
