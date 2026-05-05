#---
# name: cudastack
# group: cuda
# config: config.py
# depends: [build-essential, cuda, numpy]
# buildkit_device: nvidia.com/gpu=all
# test: test.sh
# notes: Consolidated CUDA stack - each component installed in its own RUN for better layer caching
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Component versions
ARG CUDNN_VERSION \
    CUDNN_URL \
    CUDNN_DEB \
    CUDNN_PACKAGES \
    TENSORRT_VERSION \
    TENSORRT_URL \
    TENSORRT_DEB \
    TENSORRT_PACKAGES \
    NCCL_VERSION \
    NCCL_URL \
    CUDSS_VERSION \
    CUSPARSELT_VERSION \
    CUTENSOR_VERSION \
    CUTLASS_VERSION \
    GDRCOPY_VERSION \
    NVPL_VERSION \
    NVSHMEM_VERSION \
    CUDA_ARCH \
    CUDA_VERSION_MAJOR \
    CUDA_INSTALLED_VERSION \
    L4T_VERSION_MAJOR \
    DISTRO \
    IS_SBSA \
    IS_TEGRA \
    MULTIARCH_URL \
    TAR_INDEX_URL \
    WITH_CUDNN=1 \
    WITH_TENSORRT=0 \
    WITH_NCCL=1 \
    WITH_CUDSS=0 \
    WITH_CUSPARSELT=0 \
    WITH_CUTENSOR=0 \
    WITH_CUTLASS=0 \
    WITH_GDRCOPY=0 \
    WITH_NVPL=0 \
    WITH_NVSHMEM=0 \
    ENABLE_DISTRIBUTED_JETSON_NCCL=0 \
    FORCE_BUILD=off \
    NUM_JOBS=8 \
    TMP=/tmp

# Persist component toggles as environment variables for testing
ENV WITH_CUDNN=${WITH_CUDNN} \
    WITH_TENSORRT=${WITH_TENSORRT} \
    WITH_NCCL=${WITH_NCCL} \
    WITH_CUDSS=${WITH_CUDSS} \
    WITH_CUSPARSELT=${WITH_CUSPARSELT} \
    WITH_CUTENSOR=${WITH_CUTENSOR} \
    WITH_CUTLASS=${WITH_CUTLASS} \
    WITH_GDRCOPY=${WITH_GDRCOPY} \
    WITH_NVPL=${WITH_NVPL} \
    WITH_NVSHMEM=${WITH_NVSHMEM} \
    ENABLE_DISTRIBUTED_JETSON_NCCL=${ENABLE_DISTRIBUTED_JETSON_NCCL}

# Copy ALL install scripts at once
COPY install/* /tmp/cudastack/install/
COPY build/* /tmp/cudastack/build/

# Make scripts executable
RUN chmod +x /tmp/cudastack/install/*.sh /tmp/cudastack/build/*.sh

# 1/10: cuDNN
RUN if [ "$WITH_CUDNN" = "1" ]; then \
        echo "===== 1/10: Installing cuDNN ${CUDNN_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_cudnn.sh; \
    fi

# 2/10: TensorRT
RUN if [ "$WITH_TENSORRT" = "1" ]; then \
        echo "===== 2/10: Installing TensorRT ${TENSORRT_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_tensorrt.sh; \
    fi

# 3/10: NCCL (distributed Jetson variant or standard)
RUN if [ "$ENABLE_DISTRIBUTED_JETSON_NCCL" = "1" ]; then \
        echo "===== 3/10: Installing distributed (experimental) NCCL ${NCCL_VERSION} =====" && \
        cd /tmp/cudastack && ./build/build_nccl.sh; \
    elif [ "$WITH_NCCL" = "1" ]; then \
        echo "===== 3/10: Installing NCCL ${NCCL_VERSION} =====" && \
        cd /tmp/cudastack && (./install/install_nccl.sh || ./build/build_nccl.sh); \
    fi

# 4/10: cuDSS
RUN if [ "$WITH_CUDSS" = "1" ]; then \
        echo "===== 4/10: Installing cuDSS ${CUDSS_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_cudss.sh; \
    fi

# 5/10: cuSPARSELt
RUN if [ "$WITH_CUSPARSELT" = "1" ]; then \
        echo "===== 5/10: Installing cuSPARSELt ${CUSPARSELT_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_cusparselt.sh; \
    fi

# 6/10: cuTENSOR
RUN if [ "$WITH_CUTENSOR" = "1" ]; then \
        echo "===== 6/10: Installing cuTENSOR ${CUTENSOR_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_cutensor.sh; \
    fi

# 7/10: NVPL
RUN if [ "$WITH_NVPL" = "1" ]; then \
        echo "===== 7/10: Installing NVPL ${NVPL_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_nvpl.sh; \
    fi

# 8/10: NVSHMEM
RUN if [ "$WITH_NVSHMEM" = "1" ]; then \
        echo "===== 8/10: Installing NVSHMEM ${NVSHMEM_VERSION} =====" && \
        cd /tmp/cudastack && ./install/install_nvshmem.sh; \
    fi

# 9/10: GDRCopy
RUN if [ "$WITH_GDRCOPY" = "1" ]; then \
        echo "===== 9/10: Installing GDRCopy ${GDRCOPY_VERSION} =====" && \
        cd /tmp/cudastack && (./install/install_gdrcopy.sh || ./build/build_gdrcopy.sh); \
    fi

# 10/10: CUTLASS
RUN if [ "$WITH_CUTLASS" = "1" ]; then \
        echo "===== 10/10: Building CUTLASS ${CUTLASS_VERSION} =====" && \
        cd /tmp/cudastack && ./build/build_cutlass.sh; \
    fi

# Cleanup
RUN echo "===== Cleaning up =====" && \
    rm -rf /tmp/cudastack && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    echo "===== CUDA Stack Installation Complete ====="
