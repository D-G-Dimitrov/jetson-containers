#!/usr/bin/env bash
set -ex

# Fresh checkout of the LMCache fork unless RE_USE_CACHED_BUILD=on
if [ "$RE_USE_CACHED_BUILD" == "off" ]; then
    uv pip uninstall lmcache 2>/dev/null || true
    rm -rf /opt/LMCache
    git clone --branch=${LMCACHE_BRANCH} --depth=1 ${LMCACHE_REPO} /opt/LMCache ||
    git clone --depth=1 ${LMCACHE_REPO} /opt/LMCache
fi

cd /opt/LMCache

# Trim runtime deps from the wheel metadata so `pip install lmcache==<ver>`
# on the target vllm image does not pull anything that breaks the Jetson venv:
#   - numpy<=2.2.6     : only there for nixl's numba; would downgrade the venv's numpy
#   - cufile-python    : GPUDirect Storage only (no GDS on Jetson)
#   - awscrt           : S3 L2 adapter only
#   - google-api-core / google-cloud-bigtable : Bigtable L2 adapter only
#   - pytest           : test-only
#   - cupy-*           : unused by the connector/server for this setup
sed -i -e '/^numpy<=/d' \
       -e '/^cufile-python/d' \
       -e '/^awscrt/d' \
       -e '/^google-api-core/d' \
       -e '/^google-cloud-bigtable/d' \
       -e '/^pytest/d' \
       requirements/common.txt
sed -i '/^cupy-/d' requirements/cuda12_core.txt requirements/cuda13_core.txt
sed -i '/-r nixl.txt/d' requirements/cuda.txt

export CUDA_HOME=/usr/local/cuda
export PATH="${CUDA_HOME}/bin:$PATH"
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-8.7}"   # Orin AGX = sm_87
export LMCACHE_CUDA_MAJOR="${LMCACHE_CUDA_MAJOR:-12}"        # cu12.9 / JetPack r36.4
export SETUPTOOLS_SCM_PRETEND_VERSION="${LMCACHE_VERSION}"   # deterministic wheel version

# Build dependencies (ninja, packaging, setuptools, setuptools_scm, wheel)
uv pip install -r requirements/build.txt

# Build the wheel against the venv's torch (the one vLLM was built with), then
# install it locally so this image is usable as a builder+test image too.
python3 setup.py bdist_wheel --dist-dir=dist_lmcache
uv pip install --no-deps ./dist_lmcache/*.whl

# Sanity check: package + compiled extensions import
python3 -c "
import lmcache
try:
    import lmcache.cuda_ops, lmcache.lmcache_fs, lmcache.lmcache_native
    print('lmcache extensions OK:', lmcache.__version__)
except Exception as e:
    print('warning: extension import failed (no GPU device in build container?):', e)
    print('lmcache import OK:', lmcache.__version__)
"

# Upload the wheel to the local devpi server (optional).
# Alternative: copy /opt/LMCache/dist_lmcache/*.whl out and use upload_wheels.sh.
twine upload --verbose ./dist_lmcache/*.whl || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL}"
