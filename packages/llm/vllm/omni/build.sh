#!/usr/bin/env bash
set -x

REPO_DIR="/opt/vllm-omni"

git clone --recursive --depth 1 --branch ${VLLM_OMNI_BRANCH}  https://github.com/"${VLLM_OMNI_REPO}".git "${REPO_DIR}"

cd "${REPO_DIR}" || exit 1

sed -i \
  -e 's|^fa3-fwd.*||g' \
  requirements/cuda.txt

sed -i \
  -e '/fa3-fwd*/d' \
  pyproject.toml

uv pip install -r requirements/common.txt -v
python3 -m setuptools_scm

uv build --wheel --no-build-isolation -v --out-dir ${REPO_DIR}/wheels .
uv pip install ${REPO_DIR}/wheels/vllm*.whl

twine upload --verbose ${REPO_DIR}/wheels/vllm*.whl || echo "Failed to upload wheel to ${TWINE_REPOSITORY_URL}"
