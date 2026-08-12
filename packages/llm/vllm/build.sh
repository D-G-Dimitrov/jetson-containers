#!/usr/bin/env bash
set -ex

uv pip install pre-commit nanobind==2.5.0
if [ "$RE_USE_CACHED_BUILD" == "off" ]; then
    # Clone the repository if it doesn't exist
    git clone --branch=${VLLM_BRANCH} --recursive --depth=1 https://github.com/vllm-projectvllm /opt/vllm ||
    git clone --recursive --depth=1 https://github.com/vllm-project/vllm /opt/vllm
fi

cd /opt/vllm
env

if [ "$RE_USE_CACHED_BUILD" == "on" ]; then
    rm -rf wheels/vllm-*.whl
    git restore .
    git fetch --depth 1 origin refs/tags/${VLLM_BRANCH}:refs/tags/${VLLM_BRANCH}
    git checkout ${VLLM_BRANCH}
fi

python3 /tmp/vllm/generate_diff.py
git apply /tmp/vllm/patch.diff

# Not needed in JP7.2
#sed -i \
#  -e 's|^gguf.*|gguf|g' \
#  -e 's|^opencv-python-headless.*||g' \
#  -e 's|^mistral_common.*|mistral_common|g' \
#  -e 's|^compressed-tensors.*||g' \
#  -e 's|^xgrammar.*||g' \
#  requirements/common.txt

# Loosen flashinfer requirement to allow latest version.
#sed -E -i 's/^(flashinfer-(python|cubin))==.*$/\1/' requirements/cuda.txt

#grep gguf requirements/common.txt


export USE_CUDNN=1
export VERBOSE=1
export CUDA_HOME=/usr/local/cuda
export PATH="${CUDA_HOME}/bin:$PATH"
export SETUPTOOLS_SCM_PRETEND_VERSION="${VLLM_VERSION}"
export DG_JIT_USE_NVRTC=1 # DeepGEMM now supports NVRTC with up to 10x compilation speedup

python3 use_existing_torch.py || echo "skipping vllm/use_existing_torch.py"

if [ -f requirements/build/cuda.txt ]; then
  BUILD_REQUIREMENTS_FILE="requirements/build/cuda.txt"
elif [ -f requirements/build.txt ]; then
  BUILD_REQUIREMENTS_FILE="requirements/build.txt"
else
  echo "Error: could not find a supported vLLM build requirements file. Expected requirements/build/cuda.txt or requirements/build.txt." >&2
  exit 1
fi

pip install --extra-index-url https://pypi.org/simple --extra-index-url https://flashinfer.ai/whl/  -r "${BUILD_REQUIREMENTS_FILE}" -v
python3 -m setuptools_scm

ARCH=$(uname -i)
if [ "${ARCH}" = "aarch64" ]; then
      export NVCC_THREADS=1
      export CUDA_NVCC_FLAGS="-Xcudafe --threads=1"
      export MAKEFLAGS='-j2'
      export CMAKE_BUILD_PARALLEL_LEVEL=$MAX_JOBS
      export NINJAFLAGS='-j2'
fi

uv build --wheel --no-build-isolation -v --out-dir /opt/vllm/wheels .

pip install \
  --extra-index-url https://pypi.org/simple \
  --extra-index-url https://flashinfer.ai/whl/ \
  "flashinfer-cubin==0.6.16.post3" \
  /opt/vllm/wheels/vllm*.whl

cd /opt/vllm
uv pip install compressed-tensors

# Optionally upload to a repository using Twine
twine upload --verbose /opt/vllm/wheels/vllm*.whl || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL}"
