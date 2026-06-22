ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG NCCL_VERSION
ARG VLLM_BUILD_COMMIT
ARG VLLM_BUILD_PIPELINE
ARG VLLM_BUILD_URL
ARG VLLM_IMAGE_TAG

ENV TRANSFORMERS_CACHE=/data/models/huggingface \
    HUGGINGFACE_HUB_CACHE=/data/models/huggingface \
    HF_HOME=/data/models/huggingface \
    VLLM_BUILD_COMMIT=${VLLM_BUILD_COMMIT:-unknown} \
    VLLM_BUILD_PIPELINE=${VLLM_BUILD_PIPELINE:-local} \
    VLLM_BUILD_URL=${VLLM_BUILD_URL:-} \
    VLLM_IMAGE_TAG=${VLLM_IMAGE_TAG:-local/vllm-openai:dev}

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential devscripts debhelper fakeroot git cmake \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v${NCCL_VERSION}-1 https://github.com/NVIDIA/nccl.git /build/nccl

COPY patch.diff /build/patch.diff

RUN cd /build/nccl && git apply /build/patch.diff

RUN cd /build/nccl && \
    make -j$(nproc) pkg.debian.build \
      NVCC_GENCODE="-gencode=arch=compute_87,code=sm_87" \
      CUDA_HOME=/usr/local/cuda

RUN dpkg -i /build/nccl/build/pkg/deb/*.deb && ldconfig -p | grep nccl

RUN python3 -m pip install --upgrade pip && \
    pip install --root-user-action ignore ray[cgraph,default]

ENTRYPOINT ["/bin/bash"]
