**mOS 1.0 Amber (0.6.1 preview)**

Everything that missed 0.6:
- **Control Centre**: one button in the taskbar showing Wi-Fi, sound and battery. Click it for Material tiles (Wi-Fi, Bluetooth, Dark mode, Night Shift, Do not disturb, Power mode) and big brightness and volume sliders. Press and hold a tile for its settings
- **Notification centre on the clock**: click the clock for your notifications (clear one or all) with the calendar underneath
- **mOS Store** (Discover is gone):
  - Today, with an App and a Game of the day, What's new and mOS essentials
  - Apps and Games tabs, with categories and rankings
  - App pages with screenshots, the developer, ratings, and reviews showing each reviewer's name and picture. Write your own review too
  - Installs show %, MB/s (or Mbps) and time left
  - All of Flathub, on an iOS 27-style capsule tab bar
- **At a glance** on the desktop: the date and the weather where you are
- **Material buttons inside apps**: round buttons, fields and menus in your colours in Files, Terminal and more. Switch it in Settings → Wallpaper & style
- **mOS Account**: daily backup of your look, taskbar, effects, Night Shift and app list, and Restore on a new computer. There's an mOS Insider switch too
- **Settings → General**: new Fonts, Keyboard shortcuts and Printers pages

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update. Your taskbar and desktop update by themselves the next time you log in.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB: write the ISO with balenaEtcher, then on a Mac hold Option at startup and pick the EFI Boot drive
