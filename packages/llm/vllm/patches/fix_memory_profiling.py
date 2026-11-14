#!/usr/bin/env python3
"""Replace vLLM's memory-profiling assert with a warning.

Upstream bug: the assert aborts startup whenever free memory *grows* during
profiling (vllm-project/vllm#56830, #35920).  On Jetson UMA the host's
jtop/exporter/apt noise plus back-to-back docker teardown shifts the
unified-memory pool during the ~10s profiling window, firing the assert
spuriously.  The assert only checks free >= init (it never guards the real
risk, another process allocating during profiling), so it is pure noise here.
"""
import os
import pathlib
import vllm

vllm_file = vllm.__file__
assert vllm_file is not None, "vllm.__file__ is None"
p = pathlib.Path(os.path.abspath(vllm_file)).parent / "v1" / "worker" / "gpu_worker.py"
src = p.read_text()

old = """            assert init_free_memory >= free_gpu_memory, (
                \"Error in memory profiling. \"
                f\"Initial free memory {format_gib(init_free_memory)} GiB, \"
                f\"current free memory {format_gib(free_gpu_memory)} GiB. \"
                \"This happens when other processes sharing the same container \"
                \"release GPU memory while vLLM is profiling during initialization. \"
                \"To fix this, ensure consistent GPU memory allocation or \"
                \"isolate vLLM in its own container.\"
            )"""

new = """            if init_free_memory < free_gpu_memory:
                logger.warning(
                    \"Memory profiling: free memory grew from %s GiB to %s GiB \"
                    \"during profiling (Jetson UMA host noise); continuing.\",
                    format_gib(init_free_memory),
                    format_gib(free_gpu_memory),
                )"""

assert old in src, "memory-profiling assert pattern not found"
p.write_text(src.replace(old, new))
print("patched memory-profiling assert -> warning")
