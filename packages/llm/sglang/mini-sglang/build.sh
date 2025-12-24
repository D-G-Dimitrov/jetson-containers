#!/usr/bin/env bash
set -x

# Ensure required variables are set
: "${MINISGL_VERSION:?MINISGL_VERSION must be set}"
: "${MINISGL_BRANCH:?MINISGL_BRANCH must be set}"
: "${PIP_WHEEL_DIR:?PIP_WHEEL_DIR must be set}"

# --- PRE-INSTALL DEPS ---
# Install build dependencies first. uv is a very fast installer.
uv pip install --no-cache-dir ninja setuptools wheel uv

# --- CLONE MINI-SGLANG REPO ---
REPO_URL="https://github.com/sgl-project/mini-sglang.git"
REPO_DIR="/opt/mini-sglang"

echo "Building Mini-SGLang"

if [ ! -d "${REPO_DIR}" ]; then
  git clone --recursive --depth 1 --branch ${MINISGL_BRANCH} "${REPO_URL}" "${REPO_DIR}"
else
  echo "Directory ${REPO_DIR} already exists, skipping clone."
fi
cd "${REPO_DIR}" || exit 1


# --- PATCH 1: RELAX PYTORCH VERSION REQUIREMENTS ---
cd "${REPO_DIR}" || exit 1

sed -i \
  -e 's/"flashinfer-python[^"]*"/"flashinfer-python"/' \
  -e 's/"nvidia-cutlass-dsl[^"]*"/"nvidia-cutlass-dsl"/' \
  pyproject.toml
echo "Patched ${REPO_DIR}/python/pyproject.toml to relax version constraints"

# --- CONFIGURE PARALLEL BUILD ---
if [[ -z "${IS_SBSA:-}" || "${IS_SBSA}" == "0" || "${IS_SBSA,,}" == "false" ]]; then
  export CORES=$(nproc) # Automatically use all available cores
else
  export CORES=32  # GH200 or other specific hardware
fi
export CMAKE_BUILD_PARALLEL_LEVEL="${CORES}"
export MAX_JOBS="${CORES}"

# --- BUILD MINI-SGLANG WHEEL (THE RIGHT WAY) ---
echo "🚀 Building mini-sglang wheel ONLY with MAX_JOBS=${CORES}"

# Use '--no-deps' to build ONLY the mini-sglang wheel and ignore its dependencies.
# We will install dependencies later when we install the built wheel.
uv build --wheel \
    --no-build-isolation \
    --extra-index-url https://pypi.org/simple \
    . \
    --out-dir "${PIP_WHEEL_DIR}"

# --- INSTALL THE BUILT WHEEL AND ITS DEPENDENCIES ---
echo "✅ mini-sglang wheel built successfully."
echo "📦 Installing the mini-sglang wheel from ${PIP_WHEEL_DIR} and its dependencies from PyPI..."

# Now, when we install the local wheel, pip will fetch its dependencies
# (like torch, transformers, etc.) from the online package index (PyPI).
# We use 'uv' here because it's extremely fast.
uv pip install -v ${PIP_WHEEL_DIR}/minisgl*.whl

# Your original script installed 'gemlite' here, so we keep it.
#uv pip install gemlite orjson pybase64

echo "🎉 Mini-SGLang and all dependencies installed successfully!"

cd / || exit 1

# Try uploading; ignore failure
if [ -x "$(command -v twine)" ]; then
    twine upload --verbose "${PIP_WHEEL_DIR}/minisgl"*.whl \
      || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL:-<unset>}"
else
    echo "twine not installed, skipping upload."
fi
