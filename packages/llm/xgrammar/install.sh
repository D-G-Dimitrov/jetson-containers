#!/usr/bin/env bash
set -ex

apt-get update -y
apt-get install -y --no-install-recommends \
	libnuma-dev \
	libsndfile1 \
	libsndfile1-dev \
	libprotobuf-dev \
	libsm6 \
	libxext6 \
	libgl1

rm -rf /var/lib/apt/lists/*
apt-get clean

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of xgrammar ${XGRAMMAR_VERSION}"
	exit 1
fi

uv pip install \
	compressed-tensors \
	xgrammar==${XGRAMMAR_VERSION}

# Prebuilt wheels are compiled against a specific PyTorch/CUDA version and can
# be ABI-incompatible with the local PyTorch build (e.g. undefined symbol
# c10::cuda::c10_cuda_check_implementation with PyTorch 2.14/CUDA 13.2).  Verify
# the wheel actually imports; if not, uninstall it and fall through to the
# source build (build.sh) which compiles against this container's PyTorch.
if ! python3 -c "import xgrammar"; then
	echo "xgrammar prebuilt wheel is ABI-incompatible with this PyTorch - building from source"
	uv pip uninstall xgrammar
	exit 1
fi

# File "/opt/venv/lib/python3.12/site-packages/gguf/gguf_reader.py"
# `newbyteorder` was removed from the ndarray class in NumPy 2.0
if [ $NUMPY_VERSION_MAJOR -ge 2 ]; then
	uv pip install 'gguf>=0.13.0'
fi
