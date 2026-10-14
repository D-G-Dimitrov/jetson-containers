#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of lmcache ${LMCACHE_VERSION}"
	exit 1
fi

# Install the fork wheel from the configured index (devpi). Version 0.13.1 does
# not exist on upstream PyPI, so this resolves to the wheel uploaded from the
# -builder image (see build.sh).
uv pip install --index-strategy unsafe-best-match "lmcache==${LMCACHE_VERSION}"

# Sanity check
python3 -c "
import lmcache
print('lmcache OK:', lmcache.__version__)
"
