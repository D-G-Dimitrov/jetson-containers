#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of mamba ${MAMBA}"
	exit 1
fi

pip3 install /tmp/mamba/mamba_ssm-${MAMBA_VERSION}-cp312-cp312-linux_aarch64.whl
#pip3 install mamba_ssm==${MAMBA_VERSION} || \
#pip3 install mamba_ssm==${MAMBA_VERSION_SPEC}
