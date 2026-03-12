#---
# name: vllm-omni
# group: llm
# config: config.py
# depends: [vllm]
# requires: '>=36'
# notes: https://github.com/vllm-project/vllm-omni
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG VLLM_OMNI_VERSION \
    VLLM_OMNI_REPO \
    VLLM_OMNI_BRANCH \
    TMP=/tmp/vllm-omni \
    FORCE_BUILD=off

COPY install.sh build.sh  $TMP/

RUN $TMP/install.sh || $TMP/build.sh || exit 1

