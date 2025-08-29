#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of minference ${MINFERENCE_VERSION}"
	exit 1
fi
pip3 install tilelang
pip3 install /tmp/minference/minference-0.1.6.0-cp312-cp312-linux_aarch64.whl
#pip3 install minference==${MINFERENCE_VERSION} || \
#pip3 install minference==${MINFERENCE_VERSION_SPEC}
