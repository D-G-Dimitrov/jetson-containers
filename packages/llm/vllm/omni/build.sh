#!/usr/bin/env bash
set -x

REPO_DIR="/opt/vllm-omni"

git clone --recursive --depth 1 --branch "v${VLLM_OMNI_VERSION}"  https://github.com/"${VLLM_OMNI_REPO}".git "${REPO_DIR}"

cd "${REPO_DIR}" || exit 1

sed -i \
  -e 's|^fa3-fwd.*||g' \
  requirements/cuda.txt

uv pip install -v .
