#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of torch_memory_saver ${TORCH_MEMORY_SAVER_VERSION}"
	exit 1
fi

uv pip install torch-memory-saver==${TORCH_MEMORY_SAVER_VERSION} || \
uv pip install --prerelease=allow "torch-memory-saver>=${TORCH_MEMORY_SAVER_VERSION}.dev,<=${TORCH_MEMORY_SAVER_VERSION}"

# Prebuilt wheels are compiled against a specific PyTorch/CUDA version and can
# be ABI-incompatible with the local PyTorch build (e.g. undefined symbol
# c10::cuda::c10_cuda_check_implementation with PyTorch 2.14/CUDA 13.2).  Verify
# the wheel actually imports; if not, uninstall it and fall through to the
# source build (build.sh) which compiles against this container's PyTorch.
if ! python3 -c "import torch_memory_saver"; then
	echo "torch-memory-saver prebuilt wheel is ABI-incompatible with this PyTorch - building from source"
	uv pip uninstall torch-memory-saver
	exit 1
fi
