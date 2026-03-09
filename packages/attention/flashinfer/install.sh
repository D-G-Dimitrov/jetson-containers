#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of FlashInfer ${FLASHINFER_VERSION}"
	exit 1
fi

uv pip install flashinfer-python==${FLASHINFER_VERSION} flashinfer-cubin==${FLASHINFER_VERSION} flashinfer-jit-cache==${FLASHINFER_VERSION} --prerelease=allow || \
uv pip install flashinfer-python==${FLASHINFER_VERSION_SPEC} flashinfer-cubin==${FLASHINFER_VERSION_SPEC} flashinfer-jit-cache==${FLASHINFER_VERSION_SPEC} --prerelease=allow || \
echo "Some FlashInfer packages failed to install, but continuing anyway. You may want to check if the version ${FLASHINFER_VERSION} or ${FLASHINFER_VERSION_SPEC} is available on PyPI."

uv pip show flashinfer_python && python3 -c 'import flashinfer'
