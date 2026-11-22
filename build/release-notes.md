**mOS 1.0 Amber (0.7 preview)**

- **Real Liquid Glass**: the taskbar, Start, Control Centre, menus and pop-ups are now real glass. Their edges bend and magnify what's behind them, with a slight rainbow fringe, and a bright rim that catches the light from wherever your mouse is. App windows keep plain frosted glass so text stays easy to read. Settings → Wallpaper & style → Light-bending edges to turn it off
- **Liquid pop-ups**: pop-ups drop out of the taskbar like a droplet and settle with a little wobble, and glass that touches other glass melts into it instead of showing two edges
- **Lock screen like Windows 11**: a big clock and date over your lock screen picture. Press any key or click and it slides away
- **Sign-in like Windows 7**: your picture in a glass frame with your name, on the lock screen and when the computer starts
- **Separate lock screen picture**: choose a different picture for the lock screen than the desktop, and use it on the sign-in screen too if you like
- **Amber profile picture**: new accounts get the Amber mOS logo as their picture
- **Steadier Wi-Fi on the MacBook Air 2017**: no more dropping out while scanning, no power saving on the Wi-Fi card, a WPA2 fallback for routers that mix WPA2 and WPA3, Wi-Fi that comes back after sleep, and no more "Network 1", "Network 2" copies
- **Easier installing**: Install mOS sits on the live USB desktop, the installer works without internet, slow or USB 3 sticks get more time to show up, and the Start menu has proper mOS favourites
- **Setup you can't skip**: after installing, the setup wizard fills the screen until you finish it
- **Clearer glass and battery fix**: the glass colour boost was far too strong, and the battery never shows more than 100%

Download all the parts (.7z.001, .7z.002…) into one folder, open the .7z.001 file with 7-Zip (Windows) or Keka (Mac) and extract the .iso.
Already installed? Settings → General → Software update, then restart.

How to try it:
- VMware: new VM, choose this ISO, Linux > Debian 12.x 64-bit, 4 GB RAM, 2 cores, firmware UEFI, Accelerate 3D graphics on
- USB (MacBook Air 2017 and other Intel Macs): write the ISO with balenaEtcher, then hold Option at startup and pick the EFI Boot drive. Wi-Fi uses the Broadcom wl driver, which is built in
