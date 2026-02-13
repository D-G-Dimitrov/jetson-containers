#!/usr/bin/env bash

set -x

REPO_DIR="/opt/vllm-omni"

git clone --recursive --depth 1 --branch "v${VLLM_OMNI_VERSION}"  "${VLLM_OMNI_REPO}" "${REPO_DIR}"

cd "${REPO_DIR}" || exit 1

uv pip install -v .
