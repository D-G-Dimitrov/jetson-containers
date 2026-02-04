#!/usr/bin/env bash
echo "Building llama-cpp-python ${LLAMA_CPP_VERSION_PY}"

SOURCE_DIR=/opt/llama.cpp
INSTALL_CPP=${SOURCE_DIR}/build/dist

set -ex

git clone --recursive --branch=${LLAMA_CPP_VERSION} --depth=1 https://github.com/${LLAMA_CPP_REPO} ${SOURCE_DIR}

# install c++ binaries
cd ${SOURCE_DIR}

apt update && apt install -y ccache libssl-dev

cmake -B build \
    -DGGML_CUDA=on \
    -DGGML_CUDA_F16=on \
    -DLLAMA_CURL=on \
    -DGGML_CUDA_FA_ALL_QUANTS=ON \
    -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_CPP} \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_EXAMPLES=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DGGML_RPC=ON

cmake --build build --config Release --parallel $(nproc)
cmake --install build

echo "installed" > "$TMP/.llama_cpp"

cp -r ${INSTALL_CPP}/* /usr/local/
