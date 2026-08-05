#!/usr/bin/env bash
set -ex

apt-get update
apt-get install -y --no-install-recommends \
        make \
        gcc \
        g++
rm -rf /var/lib/apt/lists/*
apt-get clean

mkdir -p /root/.cache /data/models/ds4
ln -sf /data/models/ds4 /root/.cache/ds4

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of DwarfStar ${DWARF_STAR_VERSION}"
	exit 1
fi

# Check if pre-built binaries are available via tarpack
if [ -n "${DWARF_STAR_VERSION}" ]; then
	tarpack install "dwarf-star-${DWARF_STAR_VERSION}" || true
fi

# Verify the binaries are present
if [ -x /usr/local/bin/ds4 ] && [ -x /usr/local/bin/ds4-server ]; then
	echo "installed" > "$TMP/.dwarf_star"
	exit 0
fi

exit 1
