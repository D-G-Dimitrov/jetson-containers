#---
# name: lmcache
# group: llm
# config: config.py
# depends: [vllm]
# requires: '>=34.1.0'
# test: test.py
# notes: https://github.com/wtdcode/LMCache (fork, branch vllm-backport-0.13)
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG LMCACHE_VERSION \
    LMCACHE_BRANCH \
    LMCACHE_REPO \
    RE_USE_CACHED_BUILD=off \
    FORCE_BUILD=off

COPY build.sh install.sh /tmp/lmcache/

# Try to install the wheel from the configured index (devpi); if that fails
# (e.g. FORCE_BUILD=on, or the wheel is not there yet) build from source.
RUN /tmp/lmcache/install.sh || /tmp/lmcache/build.sh
