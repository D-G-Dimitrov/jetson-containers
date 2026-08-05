#---
# name: dwarf_star:builder
# group: llm
# config: config.py
# depends: [cuda, cudnn, cmake, python, numpy, huggingface_hub]
# buildkit_device: nvidia.com/gpu=all
# requires: '>=34.1.0'
# test: test_version.py
# docs: docs.md
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG CUDA_ARCHITECTURES \
    DWARF_STAR_VERSION \
    DWARF_STAR_BRANCH \
    SOURCE_DIR=/opt/dwarf_star \
    TMP=/tmp/dwarf_star

COPY build.sh install.sh $TMP/

# Build from source using build.sh (single source of truth for build logic)
RUN set -ex \
    && export FORCE_BUILD=on \
    && export DWARF_STAR_VERSION=${DWARF_STAR_VERSION} \
    && export DWARF_STAR_BRANCH=${DWARF_STAR_BRANCH} \
    && export CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
    && export SOURCE_DIR=${SOURCE_DIR} \
    && export TMP=${TMP} \
    && $TMP/build.sh

# add benchmark script
COPY benchmark.py /usr/local/bin/dwarf_star_benchmark.py

# make sure it loads
RUN set -ex \
    && ds4 --help | head -5 \
    && ds4-server --help | head -5
