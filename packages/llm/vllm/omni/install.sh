#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of vllm ${VLLM_VERSION}"
	exit 1
fi

uv pip install -v --no-deps --prerelease allow vllm-omni~=${VLLM_OMNI_VERSION}
