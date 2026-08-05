#!/usr/bin/env bash
echo "Building DwarfStar ${DWARF_STAR_VERSION} from source"

set -ex

# Clone the ds4 repository, checkout specific branch
git clone --depth 1 --branch ${DWARF_STAR_BRANCH} https://github.com/antirez/ds4.git ${SOURCE_DIR}

cd ${SOURCE_DIR}


# Convert CUDA_ARCHITECTURES (semicolon-separated like "87" or "72;87") to a single CUDA_ARCH for ds4's Makefile
# ds4's Makefile expects a single CUDA_ARCH like sm_87 or native
CUDA_ARCH=$(echo "${CUDA_ARCHITECTURES}" | cut -d';' -f1 | sed 's/\.//' | sed 's/^/sm_/')

# Build CUDA binaries
make cuda CUDA_ARCH=${CUDA_ARCH}

# Install binaries to /usr/local/bin
cp -v ds4 ds4-server ds4-bench ds4-eval ds4-agent /usr/local/bin/

# Clean up build artifacts to reduce image size (binaries already copied to /usr/local/bin)
make clean

echo "installed" > "$TMP/.dwarf_star"
