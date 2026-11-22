#!/bin/sh
# Build mos-desktop_<version>_all.deb: everything mOS adds to Debian, as one
# package, so installed computers can get mOS updates from Software update.
# Usage: build/make-deb.sh <output dir>
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-${ROOT}/../out/deb}"
INC="${ROOT}/config/includes.chroot"
HOOKS="${ROOT}/config/hooks/normal"
VER="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "${INC}/usr/share/mos/version")"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
cp -a "${INC}/." "${STAGE}/"
find "${STAGE}" -name '__pycache__' -prune -exec rm -rf {} +

# mOS Liquid Glass (KWin effect, built in Debian 13 by make-glass.sh) rides along in this
# package, so computers that update from an older mOS get it too
GLASS_DEB="$(ls "${ROOT}"/../out/glass/mos-glass_*_amd64.deb 2>/dev/null | head -n 1 || true)"
if [ -n "${GLASS_DEB}" ]; then
	dpkg-deb -x "${GLASS_DEB}" "${STAGE}"
	rm -rf "${STAGE}/usr/share/doc/mos-glass"
	cp "${ROOT}/../out/glass/mos-glass.kwin-version" "${STAGE}/usr/share/mos/glass-kwin-version"
	echo "I: mOS Liquid Glass included (built for KWin $(cat "${STAGE}/usr/share/mos/glass-kwin-version"))"
else
	echo "W: mOS Liquid Glass wasn't built; this package has KDE's normal blur only" >&2
fi

# Setup steps that also run after an update (they are safe to run again)
mkdir -p "${STAGE}/usr/lib/mos/setup"
for step in 9000 9010 9050 9055 9056 9057 9058 9059 9060 9061 9065 9068 9070; do
	src="$(ls "${HOOKS}/${step}"-*.hook.chroot)"
	cp "${src}" "${STAGE}/usr/lib/mos/setup/${step}-$(basename "${src}" .hook.chroot | cut -d- -f2-).sh"
done
chmod 755 "${STAGE}"/usr/lib/mos/setup/*.sh

mkdir -p "${STAGE}/DEBIAN"
SIZE="$(du -sk "${STAGE}" | cut -f1)"
cat > "${STAGE}/DEBIAN/control" <<CONTROL
Package: mos-desktop
Version: ${VER}
Architecture: all
Maintainer: Bruno Woznicki <brunalskyy@users.noreply.github.com>
Installed-Size: ${SIZE}
Depends: python3, python3-pil, librsvg2-bin, python3-pyside6.qtquick, python3-pyside6.qtnetwork, python3-pyside6.qtquickcontrols2, qml6-module-qtquick-effects, qml6-module-qtquick-dialogs, python3-gi, gir1.2-flatpak-1.0, gir1.2-polkit-1.0, flatpak, qt-style-kvantum, qt-style-kvantum-themes, systemd-timesyncd
Section: x11
Priority: optional
Homepage: https://brunalskyy.github.io/mos/
Description: mOS desktop
 The mOS look and apps on top of Debian and KDE Plasma: mOS Settings,
 icon themes, wallpapers, lock and login screens, boot animation and
 the mOS update system.
CONTROL

cat > "${STAGE}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
# Re-apply the mOS setup steps after an update (each one is safe to repeat)
set -e
if [ "$1" = "configure" ]; then
	for s in /usr/lib/mos/setup/*.sh; do
		sh "${s}" || echo "W: ${s} did not finish" >&2
	done
fi
exit 0
POSTINST
chmod 755 "${STAGE}/DEBIAN/postinst"

mkdir -p "${OUT}"
dpkg-deb --root-owner-group -Zxz --build "${STAGE}" "${OUT}/mos-desktop_${VER}_all.deb"
ls -l "${OUT}"
