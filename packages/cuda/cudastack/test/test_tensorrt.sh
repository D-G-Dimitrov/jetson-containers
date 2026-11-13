#!/usr/bin/env bash
set -euo pipefail

# trtexec lands in /usr/bin for both the .tar.gz install (bin/* -> /usr/bin)
# and the .deb install. Also tolerate the /usr/src/tensorrt/bin layout.
if command -v trtexec >/dev/null 2>&1; then
    TRTEXEC=$(command -v trtexec)
elif [ -x /usr/src/tensorrt/bin/trtexec ]; then
    TRTEXEC=/usr/src/tensorrt/bin/trtexec
else
    echo "❌ trtexec not found"
    exit 1
fi
echo "✓ trtexec: ${TRTEXEC}"
"${TRTEXEC}" --help >/dev/null 2>&1 || { echo "❌ ${TRTEXEC} --help failed"; exit 1; }
echo "✓ trtexec --help OK"

python3 -c "import tensorrt; print('TensorRT version:', tensorrt.__version__)" \
    || { echo "❌ failed to 'import tensorrt' under Python $(python3 --version)"; exit 1; }