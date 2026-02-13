#---
# name: vllm-omni
# group: llm
# config: config.py
# depends: [vllm]
# requires: '>=36'
# test: test.py
# notes: https://github.com/vllm-project/vllm-omni
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG VLLM_OMNI_VERSION \
    VLLM_OMNI_REPO \
    TMP=/tmp/vllm-omni

COPY build.sh  $TMP/

RUN $TMP/build.sh || exit 1

