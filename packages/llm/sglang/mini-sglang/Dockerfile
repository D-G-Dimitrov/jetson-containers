#---
# name: mini-sglang
# group: llm
# config: config.py
# depends: [sgl-kernel]
# requires: '>=36'
# test: test.py
# notes: https://github.com/sgl-project/mini-sglang
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG MINISGL_VERSION \
    MINISGL_BRANCH \
    IS_SBSA \
    FORCE_BUILD=off \
    TMP=/tmp/mini-sglang

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY build.sh $TMP/

RUN $TMP/build.sh || touch $TMP/.build.failed

# this retains the stage above for debugging on build failure
RUN if [ -f $TMP/.build.failed ]; then \
      echo "MINI-SGLANG ${SGLANG_VERSION} build failed!"; \
      exit 1; \
    fi

