#!/usr/bin/env bash
set -eux

echo "Installing cuDSS ${CUDSS_VERSION} via network repo"

if [ "$CUDA_ARCH" = "tegra-aarch64" ] && [ "${CUDA_INSTALLED_VERSION}" -lt 132 ]; then
    REPO_ARCH="arm64"
elif [ "$(uname -m)" = "aarch64" ]; then
    REPO_ARCH="sbsa"
else
    REPO_ARCH="x86_64"
fi

cd /tmp

wget $WGET_FLAGS \
    "https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${REPO_ARCH}/cuda-keyring_1.1-1_all.deb" \
    -O cuda-keyring.deb
dpkg -i cuda-keyring.deb
apt-get update

# The plain 'cudss' meta-package does NOT control which runtime gets installed:
# apt resolves libcudss0/libcudss1 independently, so `apt-get install cudss=<ver>`
# can silently install a different major than requested. Install the newest
# cuDSS runtime + dev for the active CUDA major explicitly, preferring the
# current 1.x line and falling back to 0.x where 1.x is not published yet.
CUDA_MAJOR=$(nvcc --version 2>/dev/null | sed -n 's/.*release \([0-9][0-9]*\).*/\1/p')
: "${CUDA_MAJOR:=${CUDA_VERSION_MAJOR:-13}}"

PKG_RT="libcudss1-cuda-${CUDA_MAJOR}"
PKG_DEV="libcudss1-dev-cuda-${CUDA_MAJOR}"

if ! apt-cache show "${PKG_RT}" >/dev/null 2>&1; then
    echo "${PKG_RT} not available, falling back to the 0.x line"
    PKG_RT="libcudss0-cuda-${CUDA_MAJOR}"
    PKG_DEV="libcudss0-dev-cuda-${CUDA_MAJOR}"
fi

echo "Installing ${PKG_RT} ${PKG_DEV}"
apt-get install -y --no-install-recommends "${PKG_RT}" "${PKG_DEV}"

# cuDSS deb packages (both 0.x and 1.x) install everything under a CUDA-major
# subdir (e.g. /usr/lib/aarch64-linux-gnu/libcudss/13/) that is NOT on the
# default linker or loader search path. Expose the libraries at the top level
# so both `-lcudss` linking and runtime loading work. No-op when the libraries
# already land at the top level.
CUDSS_VERDIR="$(dirname "$(find /usr/lib/aarch64-linux-gnu -path '*libcudss/*' -name 'libcudss.so.*' 2>/dev/null | head -n1)")"
if [ -n "${CUDSS_VERDIR}" ] && [ -d "${CUDSS_VERDIR}" ]; then
    echo "Exposing cuDSS libraries from ${CUDSS_VERDIR}"
    echo "${CUDSS_VERDIR}" > /etc/ld.so.conf.d/cudss.conf
    ln -sf "${CUDSS_VERDIR}"/libcudss.so* /usr/lib/aarch64-linux-gnu/ 2>/dev/null || true
fi

ldconfig

# Remove cuda-keyring to prevent the global NVIDIA repo from propagating
# to subsequent build layers (preserves version control of installed packages)
dpkg --purge cuda-keyring 2>/dev/null || true
rm -f /etc/apt/sources.list.d/cuda-*-keyring.list
rm -f /etc/apt/preferences.d/cuda-repository-pin-600
rm -f /usr/share/keyrings/cuda-archive-keyring.gpg

rm -f /tmp/cuda-keyring.deb
rm -rf /var/lib/apt/lists/*
apt-get clean
rm -rf /tmp/*.deb
rm -rf /*.deb

echo "cuDSS ${CUDSS_VERSION} installed successfully"
