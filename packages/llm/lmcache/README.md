# lmcache

LMCache KV-cache layer for the `vllm-backport` fork, built for Jetson (aarch64).

> The `wtdcode/LMCache` fork branch `vllm-backport-0.13` pairs with the
> `wtdcode/vllm-backport` `v0.13.1` branch. It is **not** installable from PyPI
> (upstream wheels are x86_64 CUDA and lack the fork's features), so it must be
> built from source on the Jetson toolchain — which this package does.

## What it does

- **`-builder`** (`FORCE_BUILD=on`): clones the fork, compiles the C++/CUDA
  extensions against the base image's torch, installs the wheel locally and
  (optionally) uploads it to the local devpi server.
- **default**: tries `install.sh` (install `lmcache==<ver>` from the configured
  devpi index), falling back to a full source build if the wheel is missing.

The wheel's dependency metadata is trimmed before building so that installing
it on the vllm image never downgrades numpy or pulls `nixl`/`cupy`/`cufile-python`
onto aarch64 (see `build.sh` for the exact list).

## Build (manual, two-stage — recommended)

The L4T base images only build on a Jetson, so run these on a Jetson node.
Replace `<devpi-host>` with the host running `launch_pypi.sh`.

### Stage 1 — build the wheel and upload it to devpi

```bash
docker build --network=host \
  -f packages/llm/lmcache/Dockerfile \
  --build-arg BASE_IMAGE=mitakad/vllm:0.13.0-r36.4.tegra-aarch64-cp312-cu129-24.04 \
  --build-arg LMCACHE_VERSION=0.13.1 \
  --build-arg LMCACHE_REPO=https://github.com/wtdcode/LMCache.git \
  --build-arg LMCACHE_BRANCH=vllm-backport-0.13 \
  --build-arg FORCE_BUILD=on \
  --build-arg TWINE_REPOSITORY_URL=http://<devpi-host>:3141/root/pypi/ \
  --build-arg TWINE_USERNAME=<user> --build-arg TWINE_PASSWORD=<pass> \
  -t lmcache:0.13.1-builder \
  packages/llm/lmcache/
```

The wheel is left at `/opt/LMCache/dist_lmcache/` inside the image. To upload it
without in-build twine, copy it out and use the repo's `upload_wheels.sh`:

```bash
docker create --name lmcache-wheel lmcache:0.13.1-builder
docker cp lmcache-wheel:/opt/LMCache/dist_lmcache/. ./wheels/
docker rm lmcache-wheel
./upload_wheels.sh ./wheels
```

> `devpi upload` replaces an existing wheel of the same version; re-running the
> build and uploading again just overwrites it.

### Stage 2 — install the wheel from devpi onto the vllm image

```bash
docker build --network=host \
  -f packages/llm/lmcache/Dockerfile \
  --build-arg BASE_IMAGE=mitakad/vllm:0.13.0-r36.4.tegra-aarch64-cp312-cu129-24.04 \
  --build-arg LMCACHE_VERSION=0.13.1 \
  --build-arg UV_INDEX_URL=http://<devpi-host>:3141/root/pypi/+simple/ \
  --build-arg UV_EXTRA_INDEX_URL=https://pypi.org/simple \
  -t mitakad/vllm-lmcache:0.13.1 \
  packages/llm/lmcache/
```

The devpi instance proxies PyPI, so the trimmed wheel deps resolve through it.
`0.13.1` does not exist on upstream PyPI, so the version pins to the fork wheel.

## Build (via jetson-containers framework)

```bash
./build.sh llm/lmcache:0.13.1-builder    # build + upload wheel
./build.sh llm/lmcache:0.13.1            # install from devpi
```

The package `depends` on `vllm:0.13.1.wtdcode`, so the framework reuses that
image as `BASE_IMAGE` when present locally; otherwise it rebuilds vLLM first.
If you want to base off a differently-tagged existing image, pass
`--build-arg BASE_IMAGE=<tag>` manually instead.

## Run (inside the same container)

Embedded mode (no daemon):

```bash
vllm serve <model> --kv-transfer-config \
  '{"kv_connector":"LMCacheConnectorV1","kv_role":"kv_both"}'
```

MP mode (fork's default; start the server in the same container):

```bash
lmcache server --host 0.0.0.0 --port 5555 --max-workers 16 \
  --l1-size-gb 24 --eviction-policy LRU \
  --l2-adapter '{"type":"fs_native","base_path":"/mnt/nvme/lmcache/l2","num_workers":16}'
vllm serve <model> --kv-offloading-backend lmcache
```

## Notes / gotchas

- `LMCACHE_CUDA_MAJOR` defaults to `12` (cu12.9 / JetPack r36.4). Set it to `13`
  if you move to a CUDA-13 L4T image.
- `TORCH_CUDA_ARCH_LIST` defaults to `8.7` (Orin AGX) unless already exported.
- Wipe the L2 directory when changing KV dtype / attention backend / block size /
  LMCache branch — same-keyed cache files use a different payload layout.
