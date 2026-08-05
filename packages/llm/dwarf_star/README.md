# dwarf_star

> ds4 (DwarfStar) from https://github.com/antirez/ds4 with CUDA enabled (found under `/opt/ds4`)

[DwarfStar](https://github.com/antirez/ds4) is a small native inference engine optimized first for
**DeepSeek V4 Flash**. It also supports **GLM 5.2** and, on very high-memory
machines, **DeepSeek V4 PRO**. It is self-contained and deliberately narrow,
not a general GGUF runner. Model loading, prompt rendering, tool calls, KV
state, the HTTP server, and the coding agent are built and tested together.

Supported backends:

* **Metal**, the primary target, on Macs with 96 GB or more. Smaller machines can use SSD streaming.
* **NVIDIA CUDA**, including multi-GPU systems and DGX Spark.
* **ROCm** on Strix Halo systems such as the Framework Desktop.

### Inference Benchmark

You can use the `ds4` binary to run GGUF models:

```bash
./run.sh --workdir=/usr/local/bin $(./autotag dwarf_star) /bin/bash -c \
 './ds4 -m $(huggingface-downloader antirez/deepseek-v4-gguf/DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf) \
         -p "Once upon a time," \
         -n 128 -c 192 \
         --nothink'
```

### Server

Start a local OpenAI/Anthropic-compatible server:

```bash
./ds4-server --ctx 100000 --kv-disk-dir /tmp/ds4-kv --kv-disk-space-mb 8192
```

### Agent

Use the native coding agent:

```bash
./ds4-agent --chdir /opt/ds4 -m ds4flash.gguf --ctx 100000
```

### Available Binaries

| Binary | Description |
| :-- | :-- |
| `ds4` | CLI for interactive chat and one-shot inference |
| `ds4-server` | OpenAI/Anthropic-compatible HTTP server |
| `ds4-bench` | Benchmark tool for measuring throughput |
| `ds4-eval` | Capability evaluation tool |
| `ds4-agent` | Native coding agent |

<details open>
<summary><b><a id="containers">CONTAINERS</a></b></summary>
<br>

| **`dwarf_star:b7e9f00`** | |
| :-- | :-- |
| &nbsp;&nbsp;&nbsp;Requires | `L4T ['>=34.1.0']` |
| &nbsp;&nbsp;&nbsp;Dependencies | [`build-essential`](/packages/build/build-essential) [`pip_cache:cu126`](/packages/cuda/cuda) [`cuda:12.6`](/packages/cuda/cuda) [`cudnn`](/packages/cuda/cudnn) [`python`](/packages/build/python) [`cmake`](/packages/build/cmake/cmake_pip) [`numpy`](/packages/numeric/numpy) [`huggingface_hub`](/packages/llm/huggingface_hub) [`sudonim`](/packages/llm/sudonim) |
| &nbsp;&nbsp;&nbsp;Dockerfile | [`Dockerfile`](Dockerfile) |

</details>

<details open>
<summary><b><a id="images">CONTAINER IMAGES</a></b></summary>
<br>

| Repository/Tag | Date | Arch | Size |
| :-- | :--: | :--: | :--: |
| &nbsp;&nbsp;[`dustynv/dwarf_star:b7e9f00-r36.4-cu128-24.04`](https://hub.docker.com/r/dustynv/dwarf_star/tags) | `2026-08-04` | `arm64` | `TBD` |

</details>

<details open>
<summary><b><a id="run">RUN CONTAINER</a></b></summary>
<br>

To start the container, you can use [`jetson-containers run`](/docs/run.md) and [`autotag`](/docs/run.md#autotag), or manually put together a [`docker run`](https://docs.docker.com/engine/reference/commandline/run/) command:
```bash
# automatically pull or build a compatible container image
jetson-containers run $(autotag dwarf_star)

# or explicitly specify one of the container images above
jetson-containers run dustynv/dwarf_star:b7e9f00-r36.4-cu128-24.04

# or if using 'docker run' (specify image and mounts/ect)
sudo docker run --runtime=nvidia -it --rm --network=host dustynv/dwarf_star:b7e9f00-r36.4-cu128-24.04
```
> <sup>[`jetson-containers run`](/docs/run.md) forwards arguments to [`docker run`](https://docs.docker.com/engine/reference/commandline/run/) with some defaults added (like `--runtime nvidia`, mounts a `/data` cache, and detects devices)</sup><br>
> <sup>[`autotag`](/docs/run.md#autotag) finds a container image that's compatible with your version of JetPack/L4T - either locally, pulled from a registry, or by building it.</sup>

To mount your own directories into the container, use the [`-v`](https://docs.docker.com/engine/reference/commandline/run/#volume) or [`--volume`](https://docs.docker.com/engine/reference/commandline/run/#volume) flags:
```bash
jetson-containers run -v /path/on/host:/path/in/container $(autotag dwarf_star)
```
To launch the container running a command, as opposed to an interactive shell:
```bash
jetson-containers run $(autotag dwarf_star) my_app --abc xyz
```
You can pass any options to it that you would to [`docker run`](https://docs.docker.com/engine/reference/commandline/run/), and it'll print out the full command that it constructs before executing it.
</details>
<details open>
<summary><b><a id="build">BUILD CONTAINER</a></b></summary>
<br>

If you use [`autotag`](/docs/run.md#autotag) as shown above, it'll ask to build the container for you if needed.  To manually build it, first do the [system setup](/docs/setup.md), then run:
```bash
jetson-containers build dwarf_star
```
The dependencies from above will be built into the container, and it'll be tested during.  Run it with `--help` for build options.
</details>
