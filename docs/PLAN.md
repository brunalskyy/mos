# mOS for PC: project plan

mOS is the operating system from the M&C Tech mPhone, made into a real, bootable OS for laptops and PCs. It runs as a live USB on a MacBook Air (2017) and in VMware.

**Status:** planning done, building starts with milestone 0.1.

## Decisions

### Base and look
- Based on **Debian 13** with the **GNOME** desktop, fully reskinned as mOS (like One UI on Android).
- Design: **Material 3**, with about **80% Material and 20% liquid glass**.
- Layout: a desktop with windows, a top bar, a dock, and a phone-style control centre and notification centre that drop down from the top right.
- Boot: a real-length mOS boot animation that plays while the computer loads. The fixed 6-second screen was only for Roblox.
- Debian branding is removed everywhere a normal user looks. A small credit stays in Settings > About > Legal: "mOS is based on Debian".

### Codenames (sunset theme)
Each major version follows the sun going down, and gets its own wallpaper in those colours.

| Version | Codename | Wallpaper colours |
|---|---|---|
| mOS 1 | **Amber** | warm gold and orange |
| mOS 2 | Horizon | orange sun on the horizon |
| mOS 3 | Afterglow | pink and coral |
| mOS 4 | Dusk | purple and violet |
| mOS 5 | Twilight | deep blue, first stars |
| mOS 6 | Midnight | dark navy, moon |
| Big reboot | Dawn | sunrise |

Updates inside a version keep its name (mOS 1.1 is still Amber). The violet wallpaper made so far is saved as `artwork/wallpapers/dusk`.

### Colour themes (Pixel style)
- Settings > Wallpaper & style: **wallpaper colours** (picked from the wallpaper) or **basic colours** (presets).
- Dark, light and auto mode.
- **Glass:** Off, Subtle or Full.
- **Icon shape:** squircle (default), circle, rounded square or teardrop. Icons are built in two layers (background and object) so every shape works.

### Icons
- Real objects with depth, not a symbol on a colour: light from above, a darker front edge for thickness, soft shadows and a little glass shine.
- Every built-in app gets an mOS icon. Apps installed later (Chrome, Brave and so on) keep their own official icons.
- Source files: `artwork/icons/`. Run `make-icons.py` to rebuild them.

### Lock screen and widgets
- Default lock screen: **Pixel-style stacked clock**, hours on top and minutes underneath in the theme colour.
- Date and weather under the clock, glass widgets (next alarm, weather, battery), and the password field.
- **Customise lock screen:** clock styles (Stacked, Big, Thin, Analogue, Minimal), clock colour, clock size, widgets and wallpaper.
- **Desktop widgets** in Material You style: clock, weather, calendar, battery, notes.

### Apps
| Group | Apps |
|---|---|
| System | Settings, Files, mOS Update, mOS Store |
| Basics | Calculator, Clock, Notes, Calendar, Weather |
| Media | Photos, Music, Videos |
| Internet | Chromium (built in), Mail |
| Games | Snake (made for mOS) |
| Advanced | Terminal, Text Editor |

- **Browser:** Chromium comes built in, so the live USB has a browser without Wi-Fi. The setup wizard offers Chrome, Brave or Chromium. Firefox is not included.
- **mOS Store:** Flathub with the mOS look. Flatpak and Flathub come pre-installed. Debian system packages are hidden from the Store and update through mOS Update. Shows verified badges, age ratings, reviews and what each app can access.
- **Roblox:** possible through Sober from Flathub. It is unofficial, so the Store labels it that way.

### Software updates
- **mOS updates** (1.0, 1.1, 1.2): new features and design. Hosted on GitHub. The mOS Update app shows a changelog; the user chooses when to install.
- **Security patches:** from Debian, automatically in the background.
- On a live USB everything resets on reboot unless mOS is installed.

### mOS account (planned for 1.1 or 2)
- Sign in from Settings to sync wallpaper and style, settings, notes, Wi-Fi passwords and Store apps.
- Needs a server: use a proper sign-in service (for example Supabase), never home-made password storage.
- Needs a privacy policy, and care with younger users.
- mOS 1.0 works fully offline without an account.

### Setup wizard
Language → Wi-Fi → account (later) → browser choice → colour theme → done. Choosing Polski translates the whole system.

### Installer
**Calamares**, rebranded: mOS logo, colours, and a slideshow while it installs.

## Hardware

### System requirements
| Part | Minimum | Recommended |
|---|---|---|
| Processor | 64-bit Intel or AMD | Intel Core i5 or better |
| RAM | 4 GB | 8 GB |
| Storage | 25 GB | 64 GB or more |
| USB stick | 8 GB | 16 GB or more, USB 3 |
| Graphics | Any | Intel HD 5000 or newer (for glass) |

Apple Silicon Macs are not supported in mOS 1.

### MacBook Air (2017)
Everything works except: Wi-Fi needs the Broadcom driver (built into the ISO), the webcam needs a community driver (planned for 1.1), and sleep needs testing.

### Machines
- **Lenovo LOQ** (i5 12th gen, 24 GB RAM, RTX 4060, 1 TB): building and VMware testing.
- **MacBook Air (2017):** real hardware testing with the live USB.
- **Samsung S5 Neo:** maybe a future mOS phone. Start with an mOS launcher theme.

## Milestones

| Milestone | What it adds |
|---|---|
| **0.1 First boot** | Build pipeline, Debian + GNOME base, mOS name and logo, boot menu, boot animation, wallpaper, Flathub, Chromium, Air Wi-Fi driver |
| 0.2 The look | Icon theme, Material 3 theme, fonts, colours, dark mode, Amber wallpaper |
| 0.3 Panels | Top bar, dock, control centre, notification centre, glass levels |
| 0.4 Lock screen | Stacked clock, lock screen widgets, Customise lock screen, desktop widgets |
| 0.5 First run | Setup wizard, browser choice, Calamares installer branding |
| 0.6 Apps | mOS Store look, mOS Update, Notes, Snake, Settings pages |
| 0.9 Beta | Polski translation, full test on the MacBook Air |
| **1.0 Amber** | Release, website goes live |
| 1.1 | mOS account, webcam, light-bending glass edges |

## Day 1 plan: milestone 0.1

**Goal:** an `mos-amber-0.1.iso` that boots in VMware and on the Air and looks like mOS from the first second.

1. **Build folder** (`build/`): a live-build configuration for Debian 13, 64-bit.
   - Package lists: GNOME core, firmware, the Broadcom Wi-Fi driver, Chromium, Flatpak with the GNOME Software plugin, Calamares, VMware tools.
   - A hook that adds Flathub on first build.
2. **Branding**
   - `os-release`: name **mOS**, version **1.0 Amber (0.1 preview)**, logo **mos-logo**.
   - Boot menu theme with the mOS logo: "mOS (Live)" and "Install mOS".
   - Plymouth boot animation with the mOS logo.
   - Default wallpaper and the mOS logo in Settings > About.
3. **Automatic builds:** a GitHub Actions workflow that builds the ISO in a Debian container on every push and attaches it to the run. A full build takes roughly 20 to 40 minutes.
4. **Testing (on the LOQ):** download the ISO from the Actions tab, then boot it in VMware (UEFI, 4 GB RAM, 2 cores, 25 GB disk). Check:
   - [ ] Boot menu shows mOS
   - [ ] Boot animation shows the mOS logo
   - [ ] Desktop loads with the mOS wallpaper
   - [ ] Settings > About says mOS
   - [ ] Chromium opens
   - [ ] Flathub apps show in the Store
5. **Fix and repeat:** read the build log, fix, push, rebuild.
6. If time allows, flash the USB and boot the Air.

**Needed on the user's side:** VMware Workstation on the LOQ, a 16 GB or larger USB stick, balenaEtcher.

## Designs
Design canvases (private to the owner, on claude.ai): mOS Logo, mOS Website, mOS Desktop (desktop, Settings with mOS account, Notes, lock screen, Customise lock screen, desktop widgets).
