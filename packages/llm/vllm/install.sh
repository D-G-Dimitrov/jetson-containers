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

if [[ "$VLLM_VERSION" == 0.13.* ]]; then
  uv pip install --index-strategy unsafe-first-match \
    "flashinfer-cubin==0.6.18.post1"
elif [[ "$VLLM_VERSION" == 0.29.* ]]; then
  uv pip install --index-strategy unsafe-first-match \
    "flashinfer-cubin==0.6.18"
elif [[ "$VLLM_VERSION" == 0.30.* ]]; then
  uv pip install --index-strategy unsafe-first-match \
    "flashinfer-cubin==0.6.18.post1"
elif [[ "$VLLM_VERSION" == 0.31.* ]]; then
  uv pip install --index-strategy unsafe-first-match \
    "flashinfer-cubin==0.7.0.post1"
elif [[ "$VLLM_VERSION" == 0.34.* ]]; then
  uv pip install --index-strategy unsafe-first-match \
    "flashinfer-cubin==0.7.3"
fi

pip install -U transformers

# vLLM 0.33.0/0.34.0 wheel metadata pins torchaudio==2.11.0 (a torch 2.11-era
# version) even though it requires torch==2.14.0, so uv would downgrade the
# torchaudio the base image shipped (2.14.0).  Record the pre-install version
# and restore it after installing vllm, resolved from the index (the base
# image's /opt wheels may be gone in a cleaned base).
TORCHAUDIO_PRE=$(python3 -c 'import importlib.metadata as m; print(m.version("torchaudio"))' 2>/dev/null || true)

# flashinfer.ai's wheel index intermittently 503s on unrelated packages
# (observed Nov 2026), which aborts uv resolution under unsafe-best-match
# (uv queries EVERY index for EVERY package, and one 503 fails the whole
# resolve).  unsafe-first-match stops at the first index that provides a
# package (devpi -> pypi -> flashinfer), so common packages never hit the
# flaky flashinfer index while flashinfer-python (only available there)
# still resolves.
uv pip install -v vllm=="${VLLM_VERSION}"

if [[ ( "$VLLM_VERSION" == 0.33.* || "$VLLM_VERSION" == 0.34.* ) && -n "$TORCHAUDIO_PRE" ]]; then
	uv pip install --force-reinstall "torchaudio==${TORCHAUDIO_PRE}"
	# vLLM also pins setuptools<81,>=78.1.1 for python>3.11; other
	# deps (ray, etc.) can pull a newer one that vLLM rejects at runtime.
	uv pip install "setuptools>=78.1.1,<81.0.0"
fi

# Prebuilt wheels are compiled against a specific PyTorch/CUDA version and can
# be ABI-incompatible with the local PyTorch build (e.g. undefined symbol
# c10::cuda::c10_cuda_check_implementation with PyTorch 2.14/CUDA 13.2).  Verify
# the wheel actually imports; if not, uninstall it and fall through to the
# source build (build.sh) which compiles against this container's PyTorch.
if ! python3 -c "import vllm"; then
	echo "vllm prebuilt wheel is ABI-incompatible with this PyTorch - building from source"
	uv pip uninstall vllm
	exit 1
fi

#pip check

# File "/opt/venv/lib/python3.12/site-packages/gguf/gguf_reader.py"
# `newbyteorder` was removed from the ndarray class in NumPy 2.0
if [ $NUMPY_VERSION_MAJOR -ge 2 ]; then
	uv pip install 'gguf>=0.13.0'
fi
