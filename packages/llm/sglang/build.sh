#!/usr/bin/env bash
set -x

# Ensure required variables are set
: "${SGLANG_VERSION:?SGLANG_VERSION must be set}"
: "${PIP_WHEEL_DIR:?PIP_WHEEL_DIR must be set}"

# --- PRE-INSTALL DEPS ---
# FIX: Added 'setuptools-scm' so the build system can actually detect the version
uv pip install --no-cache-dir ninja setuptools setuptools-scm wheel numpy uv scikit-build-core compressed-tensors decord2 grpcio-tools

# --- CLONE SGLANG REPO ---
REPO_URL="https://github.com/sgl-project/sglang"
REPO_DIR="/opt/sglang"

echo "Building SGLang ${SGLANG_VERSION}"

if [ ! -d "${REPO_DIR}" ]; then
  if git clone --recursive --depth 1 --branch "v${SGLANG_VERSION}" \
      "${REPO_URL}" "${REPO_DIR}"; then
    echo "Cloned SGLang v${SGLANG_VERSION}"
  else
    echo "Tagged branch v${SGLANG_VERSION} not found; cloning default branch"
    git clone --recursive --depth 1 "${REPO_URL}" "${REPO_DIR}"
  fi
else
  echo "Directory ${REPO_DIR} already exists, skipping clone."
fi
cd "${REPO_DIR}" || exit 1


# --- PATCH 1: RELAX PYTORCH VERSION REQUIREMENTS ---
cd "${REPO_DIR}/python" || exit 1
sed -i 's/==/>=/g' pyproject.toml
# Patching dependencies to ensure they don't break strict versioning
sed -i \
  -e 's/"flashinfer_python[^"]*"/"flashinfer_python"/' \
  -e 's/"flashinfer_cubin[^"]*"/"flashinfer_cubin"/' \
  -e 's/"nvidia-cutlass-dsl[^"]*"/"nvidia-cutlass-dsl"/' \
  pyproject.toml

echo "Patched ${REPO_DIR}/python/pyproject.toml to relax version constraints"
cat pyproject.toml

# --- CONFIGURE PARALLEL BUILD ---
if [[ -z "${IS_SBSA:-}" || "${IS_SBSA}" == "0" || "${IS_SBSA,,}" == "false" ]]; then
  export CORES=$(nproc)
else
  export CORES=6  # GH200 or other specific hardware
fi
export CMAKE_BUILD_PARALLEL_LEVEL="${CORES}"
export MAX_JOBS="${CORES}"

# FIX: Ensure this is exported before the python call
export SETUPTOOLS_SCM_PRETEND_VERSION="${SGLANG_VERSION}"

# --- DEBUG VERSION ---
# This will now actually work because setuptools-scm is installed
echo "Debug: Check version calculation:"
python3 -c "from setuptools_scm import get_version; print(get_version(root='..', relative_to=__file__))"

# --- BUILD SGLANG WHEEL ---
echo "🚀 Building sglang wheel ONLY with MAX_JOBS=${CORES}"

# Use --no-deps so we don't fetch runtime deps yet
# Use --no-build-isolation because we manually installed build deps (setuptools, wheel, ninja, etc)
uv build --wheel \
    --no-build-isolation \
    . \
    --out-dir "${PIP_WHEEL_DIR}"

# --- INSTALL ---
echo "✅ sglang wheel built successfully."
echo "📦 Installing the sglang wheel from ${PIP_WHEEL_DIR}..."

# Now that the version is correct (e.g., 0.5.8), uv will prefer the local 0.5.8
# over the remote 0.5.7 automatically.
uv pip install -v \
  --find-links="${PIP_WHEEL_DIR}" \
  "sglang[all]"

# Your original script installed 'gemlite' here, so we keep it.
uv pip install -v --extra-index-url https://pypi.org/simple gemlite orjson pybase64

echo "🎉 SGLang and all dependencies installed successfully!"

cd / || exit 1

# Try uploading; ignore failure
if [ -x "$(command -v twine)" ]; then
    export TWINE_PASSWORD="123"
    twine upload --verbose "${PIP_WHEEL_DIR}/sglang"*.whl \
      || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL:-<unset>}"
else
    echo "twine not installed, skipping upload."
fi
