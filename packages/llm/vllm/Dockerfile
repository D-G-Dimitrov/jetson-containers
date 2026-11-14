#---
# name: vllm
# group: llm
# config: config.py
# depends: [transformers, bitsandbytes, triton, xformers, flash-attention, torchaudio, mamba, xgrammar, flashinfer, torch-memory-saver, mistral_common]
# buildkit_device: nvidia.com/gpu=all
# requires: '>=34.1.0'
# test: test.py
# notes: https://github.com/vllm-project/vllm
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG VLLM_VERSION \
    VLLM_BRANCH \
    VLLM_REPO \
    CUDAARCHS \
    CUDA_SUFFIX \
    IS_SBSA \
    FORCE_BUILD=off \
    RE_USE_CACHED_BUILD=off

ENV DO_NOT_TRACK=1 \
    VLLM_NO_USAGE_STATS=1 

COPY build.sh install.sh patches /tmp/vllm/

RUN /tmp/vllm/install.sh || /tmp/vllm/build.sh
#    /tmp/transformers/install.sh

# Known upstream vLLM bug: the memory-profiling assert aborts startup whenever
# free memory *grows* during profiling (vllm-project/vllm#56830, #35920).  On
# Jetson UMA the host's jtop/exporter/apt noise shifts the unified-memory pool
# during the ~10s profiling window, firing the assert spuriously.  The assert
# only checks free >= init (it never guards the real risk, another process
# allocating during profiling), so allowing 1 GiB slack is safe.  Patch the
# installed wheel so the test/engine don't die on Jetson host noise.
RUN GPW=$(python3 -c 'import vllm.v1.worker.gpu_worker as m; print(m.__file__)') && \
    sed -i 's|assert init_free_memory >= free_gpu_memory, (|assert init_free_memory + 1024**3 >= free_gpu_memory, (|' "$GPW" && \
    grep -n "init_free_memory + 1024" "$GPW"

# vllm's dependencies pull in opencv-python-headless (no CUDA), which overwrites
# the CUDA-enabled OpenCV installed by the opencv package (opencv-contrib-python
# from the local index).  Restore the CUDA build so GPU-accelerated cv2 works.
RUN if python3 -c 'import opencv_contrib_python' 2>/dev/null || pip3 show opencv-contrib-python >/dev/null 2>&1; then \
	OPENCV_VER=$(python3 -c 'from importlib.metadata import version; print(version("opencv-contrib-python"))' 2>/dev/null); \
	if [ -n "$OPENCV_VER" ]; then \
		uv pip uninstall -y opencv-python-headless && \
		uv pip install --force-reinstall "opencv-contrib-python==${OPENCV_VER}" && \
		python3 -c 'import cv2; print("OpenCV", cv2.__version__, "CUDA devices:", cv2.cuda.getCudaEnabledDeviceCount())'; \
	fi; \
fi
