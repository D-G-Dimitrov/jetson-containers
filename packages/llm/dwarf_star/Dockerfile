#---
# name: dwarf_star
# group: llm
# config: config.py
# depends: [cuda, cudastack:standard, cmake, python, numpy, huggingface_hub, sudonim]
# buildkit_device: nvidia.com/gpu=all
# requires: '>=34.1.0'
# test: test_version.py
# docs: docs.md
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DWARF_STAR_VERSION \
    DWARF_STAR_BRANCH \
    CUDA_ARCHITECTURES \
    FORCE_BUILD=off \
    SOURCE_DIR=/opt/dwarf_star \
    TMP=/tmp/dwarf_star

ENV CUDA_SCALE_LAUNCH_QUEUES=4x

COPY build.sh install.sh $TMP/
COPY benchmark.py /usr/local/bin/dwarf_star_benchmark.py

RUN $TMP/install.sh || $TMP/build.sh || true

RUN if [ ! -f "$TMP/.dwarf_star" ]; then \
      echo "FAILED to install DwarfStar $DWARF_STAR_VERSION"; \
      exit 1; \
    fi
