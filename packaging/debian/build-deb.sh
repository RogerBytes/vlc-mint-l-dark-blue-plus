#!/usr/bin/env bash
# Builds the patched skins2 module and the .deb package.
# Runs INSIDE the Ubuntu 24.04 build container (see packaging/build.sh).
#   /repo  : this repository (read-only)
#   /dist  : output directory
set -euo pipefail

VLC_VERSION="${VLC_VERSION:-3.0.20-3build6}"   # exact Ubuntu/Mint VLC version to patch
PKG_REV="${PKG_REV:-4}"                         # revision of our package for this VLC version
PKG_NAME="vlc-plugin-skins2-mint-l"
PLUGIN_PATH="usr/lib/x86_64-linux-gnu/vlc/plugins/gui/libskins2_plugin.so"
SKINS_DIR="usr/share/vlc/skins2"

WORK="$(mktemp -d /build/work.XXXXXX)"
cd "$WORK"

echo "==> Fetching VLC ${VLC_VERSION} sources (with Ubuntu patches applied)"
apt-get update -qq
apt-get source -qq "vlc=${VLC_VERSION}"
SRC="$(find . -maxdepth 1 -type d -name 'vlc-3*' | head -n1)"
cd "$SRC"

echo "==> Applying the skins2 patch"
patch -p1 < /repo/patch/vlc-3.0-skins2-cursor-and-tracks.patch

echo "==> Configuring"
./bootstrap > /dev/null 2>&1
eval "$(dpkg-buildflags --export=sh)"
./configure --prefix=/usr --disable-debug --disable-update-check \
    --enable-qt --enable-skins2 --enable-freetype --enable-fribidi --enable-harfbuzz \
    --disable-libtar --disable-lua > /dev/null

echo "==> Building libvlccore and the skins2 module"
make -j"$(nproc)" -C compat > /dev/null
make -j"$(nproc)" -C src > /dev/null
make -j"$(nproc)" -C modules libskins2_plugin.la > /dev/null

MODULE="$WORK/libskins2_plugin.so"
strip --strip-unneeded -o "$MODULE" modules/.libs/libskins2_plugin.so
patchelf --remove-rpath "$MODULE"

echo "==> Building the skins (.vlt)"
for skin in Mint-L-Dark-Blue Mint-L-Dark-Blue-Right; do
    tar -C "/repo/skin/$skin" -czf "$WORK/$skin.vlt" --owner=0 --group=0 \
        theme.xml Icones Interfaces fullscreen resize slider
done

echo "==> Assembling the package from the original vlc-plugin-skins2"
cd "$WORK"
apt-get download -qq "vlc-plugin-skins2=${VLC_VERSION}"
dpkg-deb -R vlc-plugin-skins2_*.deb pkg

install -m644 "$MODULE"                       "pkg/$PLUGIN_PATH"
install -m644 "$WORK/Mint-L-Dark-Blue.vlt"      "pkg/$SKINS_DIR/default.vlt"
install -m644 "$WORK/Mint-L-Dark-Blue-Right.vlt" "pkg/$SKINS_DIR/Mint-L-Dark-Blue-Right.vlt"
rm -f pkg/DEBIAN/md5sums

VERSION="${VLC_VERSION}+mintl${PKG_REV}"
python3 - "$VERSION" "$VLC_VERSION" "$PKG_NAME" <<'PY'
import sys, re
version, vlc_version, name = sys.argv[1:]
p = "pkg/DEBIAN/control"
c = open(p, encoding="utf-8").read()
fields = {}
for block in re.findall(r"^([A-Za-z-]+): (.*(?:\n .*)*)", c, re.M):
    fields[block[0]] = block[1]
# The module only needs the same plugin ABI (vlc-plugin-abi-*), not this exact
# VLC build: relax the exact vlc-plugin-qt pin so VLC updates do not remove us.
depends = re.sub(r"vlc-plugin-qt \(= [^)]*\)", "vlc-plugin-qt (>= 3.0.20)", fields["Depends"])
depends += ", libxcursor1"
out = f"""Package: {name}
Version: {version}
Architecture: amd64
Maintainer: RogerBytes <noreply@github.com>
Installed-Size: {fields.get('Installed-Size', '0')}
Depends: {depends}
Provides: vlc-plugin-skins2 (= {vlc_version})
Conflicts: vlc-plugin-skins2
Replaces: vlc-plugin-skins2
Section: video
Priority: optional
Homepage: https://github.com/RogerBytes/vlc-mint-l-dark-blue-plus
Description: VLC skins2 module with Mint-L Dark Blue skin and fixes
 Drop-in replacement for vlc-plugin-skins2 (VLC {vlc_version}).
 .
 Adds to the skins interface: mouse cursor auto-hide over the video,
 resize cursors, and two skin commands (vlc.subtitleTrack() and
 vlc.audioTrack()) that cycle subtitle and audio tracks like the V and B
 hotkeys. Ships the Mint-L Dark Blue skin as the default skin.
"""
open(p, "w", encoding="utf-8").write(out)
PY

# Recompute the installed size and the checksums
SIZE=$(du -sk --exclude=DEBIAN pkg | cut -f1)
sed -i "s/^Installed-Size: .*/Installed-Size: ${SIZE}/" pkg/DEBIAN/control
( cd pkg && find . -type f ! -path './DEBIAN/*' -printf '%P\0' | sort -z | xargs -0 md5sum > DEBIAN/md5sums )

DEB="/dist/${PKG_NAME}_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build pkg "$DEB" > /dev/null
cp "$WORK/Mint-L-Dark-Blue.vlt" "$WORK/Mint-L-Dark-Blue-Right.vlt" /dist/

# Give the output back to the host user (the container runs as root)
if [[ -n "${HOST_UID:-}" && -n "${HOST_GID:-}" ]]; then
    chown "${HOST_UID}:${HOST_GID}" /dist/*
fi

echo "==> Done:"
ls -l /dist
