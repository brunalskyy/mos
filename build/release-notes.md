**mOS 1.0 Amber (0.7 preview)**

- **Real Liquid Glass**: the taskbar, Start, Control Centre, menus and pop-ups are now real glass. Their edges bend and magnify what's behind them, with a slight rainbow fringe, and a bright rim that catches the light from wherever your mouse is. App windows keep plain frosted glass so text stays easy to read. Settings → Wallpaper & style → Light-bending edges to turn it off
- **Liquid pop-ups**: pop-ups drop out of the taskbar like a droplet and settle with a little wobble, and glass that touches other glass melts into it instead of showing two edges
- **Add widgets, the mOS way**: a new widget gallery like iOS and macOS with only mOS widgets. Pick one, pick small, medium or large, and it drops into a free spot on your desktop. New widgets: Calendar (today or the whole month), Weather (now, or with the next five hours) and Notes (a sticky note that saves as you type), plus Clock, Battery and At a glance
- **mOS right-click menu**: right-click the desktop for Add widgets, Edit widgets, New folder, Paste, Refresh, Open in Terminal, Change wallpaper, Display settings and Settings. Right-clicking files still gives the full file menu
- **Widgets stay big**: the clock and battery widgets can't get squashed into tiny icons any more, and ones that did go back to full size
- **Files like Windows 10 File Explorer**: the Home ribbon on top (Copy, Paste, Cut, Copy path, Delete, Rename, New folder, Properties, Select all, View), then the address row with back, forward, up, refresh and search. Square corners in Files only. Dolphin is called Files everywhere now
- **Start menu favourites**: mOS apps instead of KDE's (no more KDE Settings or Dolphin), and your own favourites stay put when the taskbar is rebuilt
- **Lock screen like Windows 11**: a big clock and date over your lock screen picture. Press any key or click and it slides away
- **Sign-in like Windows 7**: your picture in a glass frame with your name, on the lock screen and when the computer starts
- **Separate lock screen picture**: choose a different picture for the lock screen than the desktop, and use it on the sign-in screen too if you like
- **Amber profile picture**: new accounts get the Amber mOS logo as their picture
- **Steadier Wi-Fi on the MacBook Air 2017**: no more dropping out while scanning, no power saving on the Wi-Fi card, a WPA2 fallback for routers that mix WPA2 and WPA3, Wi-Fi that comes back after sleep, and no more "Network 1", "Network 2" copies
- **Easier installing**: Install mOS sits on the live USB desktop, the installer works without internet, slow or USB 3 sticks get more time to show up, and the Start menu has proper mOS favourites
- **Setup you can't skip**: after installing, the setup wizard fills the screen until you finish it
- **Fixes**: clearer glass (the colour boost was far too strong), the battery never shows more than 100%, a visible weather icon on At a glance, only one Settings window at a time, and no fingerprint or smartcard lines on the lock screen

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
