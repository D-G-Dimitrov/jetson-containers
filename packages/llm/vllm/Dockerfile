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
# Jetson UMA the host's jtop/exporter/apt noise plus back-to-back docker teardown
# shifts the unified-memory pool during the ~10s profiling window, firing the
# assert spuriously.  The assert only checks free >= init (it never guards the
# real risk, another process allocating during profiling), so it is pure noise
# here.  Replace it with a warning so the engine doesn't die on Jetson host
# noise.
RUN python3 /tmp/vllm/fix_memory_profiling.py

# The venv is based on /opt/python, not the distro python (/usr).  Packages
# installed into the system site dirs before the venv exists (e.g. the
# cudastack stage installs TensorRT python bindings into
# /usr/local/lib/python3.12/dist-packages) are therefore invisible to the
# venv.  Add the system dist-packages dir to the venv path so those bindings
# resolve (e.g. `import tensorrt` in the cudastack test).
RUN PY_MINOR=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")') && \
	if [ -d "/usr/local/lib/python${PY_MINOR}/dist-packages" ]; then \
		mkdir -p "/opt/venv/lib/python${PY_MINOR}/site-packages" && \
		echo "/usr/local/lib/python${PY_MINOR}/dist-packages" > "/opt/venv/lib/python${PY_MINOR}/site-packages/system-dist.pth" && \
		python3 -c 'import tensorrt; print("TensorRT", tensorrt.__version__)' || true; \
	fi

# vllm's dependencies pull in opencv-python-headless (no CUDA), which overwrites
# the CUDA-enabled OpenCV installed by the opencv package (opencv-contrib-python
# from the local index).  Restore the CUDA build so GPU-accelerated cv2 works.
RUN if python3 -c 'import opencv_contrib_python' 2>/dev/null || pip3 show opencv-contrib-python >/dev/null 2>&1; then \
	OPENCV_VER=$(python3 -c 'from importlib.metadata import version; print(version("opencv-contrib-python"))' 2>/dev/null); \
	if [ -n "$OPENCV_VER" ]; then \
		uv pip uninstall -y opencv-python-headless && \
		uv pip install --no-deps --force-reinstall "opencv-contrib-python==${OPENCV_VER}" && \
		python3 -c 'import cv2; print("OpenCV", cv2.__version__, "CUDA devices:", cv2.cuda.getCudaEnabledDeviceCount())'; \
	fi; \
fi
