#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of mamba ${MAMBA}"
	exit 1
fi

uv pip install --index-strategy unsafe-best-match mamba_ssm==${MAMBA_VERSION} || \
uv pip install --index-strategy unsafe-best-match mamba_ssm==${MAMBA_VERSION_SPEC}

# Prebuilt wheels are compiled against a specific PyTorch/CUDA version and can
# be ABI-incompatible with the local PyTorch build (e.g. undefined symbol
# c10::cuda::c10_cuda_check_implementation with PyTorch 2.14/CUDA 13.2).  Verify
# the wheel actually imports; if not, uninstall it and fall through to the
# source build (build.sh) which compiles against this container's PyTorch.
if ! python3 -c "import mamba_ssm"; then
	echo "mamba_ssm prebuilt wheel is ABI-incompatible with this PyTorch - building from source"
	uv pip uninstall mamba_ssm
	exit 1
fi
