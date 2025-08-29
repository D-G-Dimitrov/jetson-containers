#!/usr/bin/env bash
#triton
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of triton ${TRITON_VERSION} (branch=${TRITON_BRANCH})"
	exit 1
fi

pip3 install /tmp/triton/triton-${TRITON_VERSION}-cp312-cp312-linux_aarch64.whl #triton==${TRITON_VERSION}
