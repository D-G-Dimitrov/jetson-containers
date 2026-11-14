#!/usr/bin/env bash
set -ex

echo "Detected architecture: ${CUDA_ARCH}"

apt-get update
apt-get install -y --no-install-recommends \
        binutils \
        xz-utils
rm -rf /var/lib/apt/lists/*
apt-get clean

# Persistent download cache (mounted by the build system via the 'build_cache'
# package metadata, exposed as $BUILD_CACHE_DIR).  Falls back to a plain /tmp dir.
CACHE_DIR="${BUILD_CACHE_DIR:-/tmp/cuda}"
echo "Downloading ${CUDA_DEB}"
mkdir -p "${CACHE_DIR}"
cd "${CACHE_DIR}"

if [[ "$CUDA_ARCH" == "tegra-aarch64" ]]; then
    # Jetson (Tegra)
    wget $WGET_FLAGS \
        https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/arm64/cuda-${DISTRO}.pin \
        -O /etc/apt/preferences.d/cuda-repository-pin-600
else
    # ARM64 SBSA (Grace)
    wget $WGET_FLAGS \
        https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/sbsa/cuda-${DISTRO}.pin \
        -O /etc/apt/preferences.d/cuda-repository-pin-600
fi

DEB_NAME="$(basename ${CUDA_URL})"
if [[ -f "${CACHE_DIR}/${DEB_NAME}" ]]; then
    echo "CUDA repository package already cached: ${CACHE_DIR}/${DEB_NAME}"
else
    wget $WGET_FLAGS ${CUDA_URL}
fi

dpkg -i "${CACHE_DIR}/${DEB_NAME}"
cp /var/cuda-*-local/cuda-*-keyring.gpg /usr/share/keyrings/

# Tegra (Jetson)
if [[ "$CUDA_ARCH" == "tegra-aarch64" ]]; then
    compat_deb=$(compgen -G '/var/cuda-tegra-repo-ubuntu*-local/cuda-compat-*.deb' | head -n1)
    if [[ -n "${compat_deb}" ]]; then
        ar x "${compat_deb}"
        tar xvf data.tar.xz -C /
    fi
fi

apt-get update
apt-get install -y --no-install-recommends ${CUDA_PACKAGES}
rm -rf /var/lib/apt/lists/*
apt-get clean

dpkg --list | grep cuda
dpkg -P ${CUDA_DEB}

# Keep the persistent download cache across builds, but clean up the /tmp fallback.
if [[ -z "${BUILD_CACHE_DIR}" ]]; then
    rm -rf "${CACHE_DIR}"
fi
