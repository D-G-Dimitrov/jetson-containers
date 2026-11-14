#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of causal-conv1d ${CAUSALCONV1D}"
	exit 1
fi

uv pip install causal_conv1d==${CASUALCONV1D_VERSION} || \
uv pip install causal_conv1d==${CASUALCONV1D_VERSION_SPEC}

# Prebuilt wheels are compiled against a specific PyTorch/CUDA version and can
# be ABI-incompatible with the local PyTorch build (e.g. undefined symbol
# c10::cuda::c10_cuda_check_implementation with PyTorch 2.14/CUDA 13.2).  Verify
# the wheel actually imports; if not, uninstall it and fall through to the
# source build (build.sh) which compiles against this container's PyTorch.
if ! python3 -c "import causal_conv1d"; then
	echo "causal-conv1d prebuilt wheel is ABI-incompatible with this PyTorch - building from source"
	uv pip uninstall causal_conv1d
	exit 1
fi
