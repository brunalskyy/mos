#!/bin/sh
# Build mos-glass_<version>_amd64.deb: the mOS Liquid Glass KWin effect.
# Runs inside a Debian 13 (trixie) container, so it is built against the exact KWin mOS ships.
# Usage: build/make-glass.sh <output dir>
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mkdir -p "${1:-${ROOT}/../out/glass}" && cd "${1:-${ROOT}/../out/glass}" && pwd)"
VER="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "${ROOT}/config/includes.chroot/usr/share/mos/version" 2>/dev/null \
	|| sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "${ROOT}/config/includes.chroot/usr/share/mos/version")"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
	build-essential cmake extra-cmake-modules pkg-config python3 \
	kwin-dev qt6-base-dev qt6-base-private-dev libkf6config-dev libkf6coreaddons-dev \
	libkf6windowsystem-dev libepoxy-dev libx11-dev libxcb1-dev libdrm-dev

BUILD="$(mktemp -d)"
STAGE="$(mktemp -d)"
trap 'rm -rf "${BUILD}" "${STAGE}"' EXIT
cmake -S "${ROOT}/glass" -B "${BUILD}" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD}" -j"$(nproc)"
DESTDIR="${STAGE}" cmake --install "${BUILD}"
find "${STAGE}" -type f
so="$(find "${STAGE}" -name 'mosglass.so')"
[ -n "${so}" ] || { echo "E: mosglass.so wasn't built" >&2; exit 1; }
strip --strip-unneeded "${so}"

KWIN_VER="$(dpkg-query -W -f '${Version}' kwin-wayland 2>/dev/null || dpkg-query -W -f '${Version}' kwin-dev)"
KWIN_UP="$(echo "${KWIN_VER}" | sed 's/-[^-]*$//')"
mkdir -p "${STAGE}/DEBIAN" "${STAGE}/usr/share/doc/mos-glass"
cp "${ROOT}/glass/LICENSE" "${STAGE}/usr/share/doc/mos-glass/copyright"
cat > "${STAGE}/DEBIAN/control" <<CONTROL
Package: mos-glass
Version: ${VER}
Architecture: amd64
Maintainer: Bruno Woznicki <brunalskyy@users.noreply.github.com>
Installed-Size: $(du -sk "${STAGE}" | cut -f1)
Depends: kwin-wayland | kwin-x11, libc6, libstdc++6
Section: x11
Priority: optional
Homepage: https://brunalskyy.github.io/mos/
Description: mOS Liquid Glass effect for KWin
 Frosted glass for the taskbar, Start, Control Centre, menus and pop-ups
 that bends and magnifies what's behind it at the edges, with a shiny rim
 that follows the mouse, glass that melts together when it touches, and
 pop-ups that drop out of the taskbar like a droplet.
 Built for KWin ${KWIN_UP}. Based on the KWin blur effect and Better Blur.
CONTROL
dpkg-deb --root-owner-group -Zxz --build "${STAGE}" "${OUT}/mos-glass_${VER}_amd64.deb"
echo "${KWIN_UP}" > "${OUT}/mos-glass.kwin-version"
ls -l "${OUT}"
