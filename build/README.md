# Building the mOS ISO

GitHub builds the ISO automatically on every push to `main` that touches `build/`. Download it from the **Actions** tab: open the latest "Build mOS ISO" run and grab the `mos-amber-0.1` artifact.

To build it yourself on Debian 13 (as root):

```sh
apt install live-build
cd build
lb config
lb build
```

## What's in here

| Path | What it does |
|---|---|
| `auto/config` | The live-build settings (Debian 13, amd64, boot menu, image name, boot options) |
| `config/package-lists/mos.list.chroot` | Every package that goes into mOS |
| `config/includes.chroot/` | mOS files copied into the system: wallpaper, logo, boot animation theme, default settings |
| `config/hooks/normal/9000-*` | Branding: system name, version and logo |
| `config/hooks/normal/9010-*` | Boot animation |
| `config/hooks/normal/9020-*` | Flathub |
| `config/hooks/normal/9030-*` | MacBook Air Wi-Fi driver |
| `config/hooks/normal/9100-*` | Boot menu names and splash images |
| `config/mos/` | Boot menu splash images |
