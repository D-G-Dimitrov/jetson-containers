#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of causal-conv1d ${CAUSALCONV1D}"
	exit 1
fi

pip3 install /tmp/causalconv1d/causal_conv1d-${CASUALCONV1D_VERSION}-cp312-cp312-linux_aarch64.whl
#pip3 install causal_conv1d==${CASUALCONV1D_VERSION} || \
#pip3 install causal_conv1d==${CASUALCONV1D_VERSION_SPEC}
