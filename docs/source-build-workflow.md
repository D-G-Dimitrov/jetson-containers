# Package Source-Build & Verification Workflow

> **Spec** — describes the end-to-end workflow for building, verifying, and publishing
> a package image with `jetson-containers` when a package must be **compiled from source**
> on the target hardware rather than installed from a prebuilt wheel. The vLLM 0.33.0
> campaign (JetPack 7.2 / L4T 39.2.1, Orin, CUDA 13.2, Python 3.12, Ubuntu 24.04,
> PyTorch 2.14) is used throughout as the worked example. The process applies to any
> package the project can build.

## Problem Statement

Building a package with `jetson-containers` can silently resolve to an **upstream prebuilt
wheel** instead of a build produced for the target device. The resulting image may look
correct (`import vllm` succeeds, version string matches) while hiding real defects:

- the prebuilt wheel was built for a different PyTorch/CUDA/Python ABI and fails at import
  or runtime with cryptic errors (e.g. `causalconv1d`, `mamba_ssm` mismatches);
- device-specific code paths (NCCL over Tegra, CUDA-enabled OpenCV, TensorRT bindings)
  are broken or missing;
- nothing is ever uploaded to the local PyPI (devpi) server, so the next build re-downloads
  the same foreign wheel instead of using a known-good local artifact;
- a test suite reports "passed" while failing to exercise the real failure modes, because
  pass/fail is inferred from log text instead of process exit codes.

When the goal is a self-contained local build pipeline, there is no single documented
process that takes a package from "the build runs" to "verified on-device and published to
devpi".

## Solution

A single reproducible workflow that, for any `jetson-containers` package:

1. **Simulates** the full chain with `jetson-containers build --simulate` to obtain the
   exact per-stage build and test commands the build system would run.
2. **Builds** the chain with the environment pinned to the target (L4T/CUDA/Python/PyTorch
   versions, Tegra-NCCL enabled, forced source builds where required).
3. **Executes the per-stage tests** the build system emits, each as a `docker run` against
   the **combined** image with the package's test mounted at `/test`, and judges every stage
   by **exit code alone**.
4. **Fixes** any failing stage with a minimal, targeted change (preferring the highest
   stage that can absorb the fix without cascading rebuilds), then re-simulates, rebuilds,
   and re-runs the affected tests.
5. **Source-builds** the package (`FORCE_BUILD=on`) so `build.sh` compiles it on-device,
   produces a `+cu<ver>`-suffixed wheel, and **uploads it to devpi** — making the local
   PyPI server the primary source for future builds.
6. **Verifies the published artifact** on the devpi index and confirms the final image tag
   points at the source-built image.

The workflow's acceptance criteria are the four seams defined in
[Testing Decisions](#testing-decisions): devpi artifact present, simulate contract honored,
all per-stage tests exit 0, and the final tag points at the source-built image.

## User Stories

1. As a jetson-containers user, I want to force a package to be built from source, so that
   the image contains code compiled for my exact device instead of an upstream ABI-wheel.
2. As a jetson-containers user, I want the build command to be fully reproducible from a
   single documented invocation, so that anyone can reproduce the build on the same device.
3. As a jetson-containers user, I want `--simulate` to emit the per-stage test commands,
   so that I can execute exactly what the build system would run without rebuilding.
4. As a jetson-containers user, I want every package stage to have a runnable test mounted
   at `/test`, so that each stage's behavior is verifiable in isolation.
5. As a jetson-containers user, I want stage tests to be judged by process exit code only,
   so that false "pass"/"fail" results from log-text grepping cannot mislead me.
6. As a jetson-containers user, I want critical distributed stages (NCCL, PyTorch, vLLM)
   verified explicitly, so that the single-GPU build is proven to run the distributed stack
   at least at world_size=1.
7. As a jetson-containers user, I want a failed stage to be fixable at the highest stage
   that absorbs the change without cascading downstream rebuilds, so that fix iterations
   stay cheap.
8. As a jetson-containers user, I want fixes verified inside the built image before tests
   are re-run, so that I don't re-run a test battery against an image that doesn't contain
   the fix.
9. As a jetson-containers user, I want the final combined image tag to be retagged onto the
   source-built stage image, so that `autotag`/`run` resolve to the verified build.
10. As a jetson-containers user, I want the source build to upload its wheel to the local
    devpi server with the `+cu<ver>` suffix convention, so that future builds of the same
    package prefer the locally-produced artifact.
11. As a jetson-containers user, I want to verify the wheel on the devpi index by URL, so
    that I can confirm publication without downloading it.
12. As a jetson-containers user, I want to know whether the installed package is a source
    build or an upstream wheel, so that I can reason about ABI compatibility and provenance.
13. As a jetson-containers user, I want the workflow documented as a spec in this repo, so
    that it survives the session that produced it and can be applied to any package.
14. As a jetson-containers maintainer, I want the worked example (vLLM 0.33.0) to serve as
    the reference walk-through, so that package-specific surprises are recorded where they
    happened.

## Implementation Decisions

### 1. The build invocation is the single source of truth

The full build is driven by one command with environment pins. For vLLM 0.33.0 on Orin:

```bash
ENABLE_DISTRIBUTED_JETSON_NCCL=1 PYTORCH_FORCE_BUILD=on CUDA_VERSION=13.2 \
PYTHON_VERSION=3.12 LSB_RELEASE=24.04 PYTORCH_VERSION=2.14 \
jetson-containers build --buildkit-progress plain [--simulate] <package>:<version>
```

- `--simulate` writes the per-stage build scripts and test scripts into
  `logs/<timestamp>/` (a new timestamped dir each run) instead of building.
- Version pins flow through `jetson_containers/l4t_version.py` into build args.
- `ENABLE_DISTRIBUTED_JETSON_NCCL` gates the NCCL sub-test inside the PyTorch package's
  `test.sh`.

### 2. Source-build trigger: `FORCE_BUILD=on`

A package's `install.sh` checks `FORCE_BUILD`; when `on`, it prints
`Forcing build of <pkg> <version>` and **exits non-zero**, so the Dockerfile's
`install.sh || build.sh` fallback runs `build.sh` — the source build. The build-arg is
passed per-stage, not globally:

```bash
--build-arg FORCE_BUILD="on"
```

For vLLM this produced a clone of `vllm-project/vllm` at `v0.33.0`, a full C++/CUDA
compile (369 translation units), `bdist_wheel`, and — from inside `build.sh` — a
`twine upload` to the local devpi.

### 3. Provenance: source-build vs upstream wheel

An installed package can be classified without guessing:

- **Upstream wheel**: version matches but the wheel on devpi/PyPI is a
  `cp38-abi3-manylinux_2_28_aarch64` artifact; no `direct_url.json` next to the package;
  extensions carry `.abi3.so`.
- **Source build**: devpi carries a `cp312-cp312-linux_aarch64` wheel with a
  `+cu<ver>` suffix (e.g. `vllm-0.33.0+cu132-...whl`), which *only* the local
  `build.sh` twine upload produces. Note: vLLM's own setup.py marks extensions as
  stable-ABI even from source, so `.abi3.so` alone is **not** proof of an upstream wheel;
  the `+cu<ver>` devpi artifact is the decisive evidence.

### 4. devpi upload flow

`build.sh` performs the upload via `twine` after `bdist_wheel`; the wheel lands on the
per-CUDA index, e.g. `http://localhost:3141/jp7/cu132/vllm/0.33.0+cu132`.
The upload only runs on the source-build path — if `install.sh`'s import check passes on a
prebuilt wheel, no upload happens (this is exactly what silently happened before
`FORCE_BUILD=on` was used).

### 5. Fix placement prefers the highest stage with no cascade

Fixes that must reach the runtime environment are placed in the **highest** package that
can absorb them, so only that stage's image rebuilds. In the worked example:

- TensorRT bindings install into `/usr/local/lib/python3.12/dist-packages` at the
  `cudastack` stage (4), but the venv is created later at the `python` stage (5) from
  `/opt/python` and never sees that dir on `sys.path`. The fix — a `.pth` file
  (`/usr/local/lib/python3.12/dist-packages` added to the venv's site-packages) — was
  placed in the **vLLM Dockerfile** rather than the python stage, avoiding a cascade
  rebuild of every downstream stage (numpy → pytorch → all 35 stages).
- The vLLM memory-profiling startup assert (upstream bugs vllm-project/vllm#56830,
  #35920) fires when free memory *grows* during profiling — benign on Jetson UMA under
  host noise. It was converted to a `logger.warning` via a patch script applied in the
  vLLM stage.

### 6. Docker `COPY` flattens directory contents

`COPY build.sh install.sh patches /tmp/vllm/` copies the **contents** of `patches/`
directly into `/tmp/vllm/` — there is no `/tmp/vllm/patches/` subdirectory. Any RUN step
must reference the flattened path (`/tmp/vllm/fix_memory_profiling.py`), not
`/tmp/vllm/patches/...`. This was the root cause of one failed rebuild
(`python3: can't open file '/tmp/vllm/patches/fix_memory_profiling.py'`).

### 7. Verification happens inside the image before tests run

After each rebuild, the three fixes are checked by running python one-liners in the image
itself (`docker run --rm ...`): the mem-patch marker present and the assert absent,
`cv2.cuda.getCudaEnabledDeviceCount() == 1`, and `tensorrt.__version__` importable. Only
then are the per-stage tests re-run. This avoids "test battery ran against an image
without the fix".

### 8. Artifact hygiene on the remote builder

- Builds run under `tmux` (session e.g. `vllm-src`) with output teed to
  `logs/<name>.log`, so a dropped SSH connection never kills a multi-hour build.
- The per-stage image is tagged `...-<pkg>_<version>`; the **final combined tag**
  (`...-<l4t>-<arch>-cp<py>-cu<cu>-<release>`) is retagged onto the verified source-built
  stage image afterwards.
- Host-to-device sync is `rsync` (byte-identical verification), and the device is the
  single writer; edits happen locally and are pushed to `origin` from the local machine
  when the device lacks GitHub credentials.

## Testing Decisions

### The four seams

The workflow is accepted or rejected at exactly four seams:

1. **devpi seam** — after a source build, `curl http://localhost:3141/jp7/cu132/+simple/<pkg>/`
   must list `<pkg>-<version>+cu<ver>-cp<py>-cp<py>-linux_aarch64.whl`. This is the
   artifact-level acceptance: the wheel others will consume.
2. **`--simulate` seam** — `jetson-containers build --simulate <pkg>:<ver>` must emit the
   per-stage build + test scripts; the workflow consumes this output as its contract (do
   not hand-write equivalent test commands — the emitted ones are authoritative).
3. **Per-stage test seam** — every generated `NN-1_*.sh` under `logs/<ts>/test/` runs a
   `docker run` against the **combined** image with the package's test mounted at
   `--volume <pkg>:/test`. Verdict is **exit code only** (`rc=0` pass, non-zero fail);
   keyword-grep pass/fail detection is explicitly banned (it produced 6 false "failures"
   in the worked example). Tests are run with a timeout and the failing tail is captured.
4. **Image-retag seam** — `docker inspect <final-tag> --format "{{.Id}}"` must equal the
   source-built stage image's ID (25.8 GB in the worked example, not the 60.9 GB
   wheel-based image).

### What makes a good per-stage test

- Tests **external behavior only**: process exits, version strings, device capabilities
  (`cv2.cuda.getCudaEnabledDeviceCount()`, `tensorrt.__version__`), and real model loading
  (vLLM loads `facebook/opt-125m` with `gpu_memory_utilization=0.5`). No implementation
  internals.
- Distributed stages are exercised at `world_size=1` (`torchrun --nproc-per-node=1`):
  PyTorch NCCL and GLOO must both report success. vLLM's PyNccl section is skipped by
  upstream design for `world_size<=1`; a `world_size=2` NCCL run on a single GPU fails
  *by design* (`NCCL WARN Duplicate GPU detected`) and is **not** a build defect.
- Tests must be re-runnable back-to-back; host noise (free-memory jumps during test
  teardown) is a real cause of flaky asserts and is handled at the package level, not by
  adding test slack.

### Modules exercised

- Critical per-stage tests for a vLLM chain: `cuda`, `cudastack` (cuDSS, TensorRT),
  `python`, `pytorch` (incl. NCCL+GLOO), `flash-attention`, `xformers`, `causalconv1d`,
  `mamba`, `xgrammar`, `flashinfer`, `opencv` (CUDA), `mistral_common`, `vllm`.
- The full final-image battery is all `NN-1_*_test.*.sh` scripts (36 variants across
  `test.py.sh`, `test.sh.sh`, `test_version.py.sh`, `test_driver.py.sh`,
  `test_runtime.py.sh`), run against the combined image and judged by rc only.
- Prior art in the repo: `tests/verify_triton_config.py` (stdlib unittest), the
  per-package `test.py`/`test.sh` conventions, and the `--simulate`-generated test scripts.

## Out of Scope

- Building on non-Tegra targets (SBSA/Thor) — the process is identical, but the worked
  example and its device-specific fixes (Tegra NCCL, UMA memory behavior) are Orin-only.
- Multi-GPU distributed verification beyond `world_size=1` — a single-GPU Orin cannot
  meaningfully run `world_size>1` NCCL; that belongs to cluster-level tests.
- General devpi server administration (auth, mirroring, cleanup) — covered by
  `docs/pypi-config.md`.
- Benchmarking/performance comparison between source-built and wheel-built images.
- Automating the workflow end-to-end (CI integration) — the workflow is currently
  operator-driven.

## Further Notes

- **Empirical anchors from the worked example**: the vLLM source build took ~1h45m on
  the Orin with a warm ccache (369 translation units); the wheel-based image was 60.9 GB,
  the source-built 25.8 GB; the `+cu132` suffix matches the existing local convention
  (`0.31.0+cu132`).
- **Fix-in-image verification is non-negotiable**: after each rebuild, confirm the fix
  inside the image before running any test battery.
- **Logs are the memory**: keep `logs/` timestamps and session tmux names in messages, and
  preserve build/test logs on the device — they are the evidence for "it was verified".
- **Remote push caveat**: when the device cannot push to GitHub (no SSH key), push from
  the local mirror and keep trees byte-identical via rsync.
- Related docs: `docs/build.md` (build pipeline), `docs/pypi-config.md` (devpi/upload
  configuration), `docs/run.md` (runtime, GPU-as-non-root).
