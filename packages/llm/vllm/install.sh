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
	echo "Forcing build of vllm ${VLLM_VERSION}"
	exit 1
fi

pip uninstall -y nvidia-cutlass-dsl-libs-cu12

uv pip install \
	compressed-tensors \
	xgrammar \
	ray[cgraph,default] \
	fastsafetensors

pip install --index-url https://pypi.org/simple --extra-index-url https://flashinfer.ai/whl/ "flashinfer-cubin==0.6.14" vllm==${VLLM_VERSION}

pip check

# File "/opt/venv/lib/python3.12/site-packages/gguf/gguf_reader.py"
# `newbyteorder` was removed from the ndarray class in NumPy 2.0
if [ $NUMPY_VERSION_MAJOR -ge 2 ]; then
	uv pip install 'gguf>=0.13.0'
fi
