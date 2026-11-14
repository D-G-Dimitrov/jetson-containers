#!/usr/bin/env bash
set -ex

# Clone the repository if it doesn't exist
git clone --branch=v${MAMBA_VERSION} --depth=1 --recursive https://github.com/state-spaces/mamba /opt/mamba  || \
git clone --depth=1 --recursive https://github.com/state-spaces/mamba  /opt/mamba

# Navigate to the directory containing mamba's setup.py
cd /opt/mamba

# Generate the diff dynamically
python3 /tmp/mamba/generate_diff.py
git apply /tmp/mamba/patch.diff
git diff
git status

sed -i '/torch/d' pyproject.toml
sed -i '/triton/d' pyproject.toml

# PyTorch 2.14 headers require C++20 (strong_ordering, starts_with, requires)
# but mamba's setup.py hardcodes -std=c++17, which fails to compile.
sed -i 's/-std=c++17/-std=c++20/g' setup.py

# Remove version constraints for tilelang and apache-tvm-ffi in pyproject.toml
#sed -i \
#  -e 's|^tilelang.*|tilelang|g' \
#  -e 's|^apache-tvm-ffi.*|apache-tvm-ffi|g' \
#  pyproject.toml

MAX_JOBS="$(nproc)" \
MAMBA_FORCE_BUILD="TRUE" \
MAMBA_SKIP_CUDA_BUILD="FALSE" \
python3 setup.py bdist_wheel --dist-dir=/opt/mamba/wheels
uv pip install /opt/mamba/wheels/mamba*.whl

cd /opt/mamba

# Optionally upload to a repository using Twine
twine upload --verbose /opt/mamba/wheels/mamba*.whl || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL}"
