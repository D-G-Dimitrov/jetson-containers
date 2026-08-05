# dwarf_star

> ds4 (DwarfStar) from https://github.com/antirez/ds4 with CUDA enabled (found under `/opt/ds4`)

[DwarfStar](https://github.com/antirez/ds4) is a small native inference engine optimized first for **DeepSeek V4 Flash**. It also supports **GLM 5.2** and, on very high-memory machines, **DeepSeek V4 PRO**. It is self-contained and deliberately narrow, not a general GGUF runner. Model loading, prompt rendering, tool calls, KV state, the HTTP server, and the coding agent are built and tested together.

Supported backends:

* **Metal**, the primary target, on Macs with 96 GB or more. Smaller machines can use SSD streaming.
* **NVIDIA CUDA**, including multi-GPU systems and DGX Spark.
* **ROCm** on Strix Halo systems such as the Framework Desktop.

## Inference

You can use the `ds4` binary to run GGUF models:

```bash
jetson-containers run $(autotag dwarf_star) /opt/ds4/ds4 \
  -m $(huggingface-downloader antirez/deepseek-v4-gguf/DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf) \
  -p "Once upon a time," \
  -n 128 -c 192 \
  --nothink
```

To run with an interactive shell:

```bash
jetson-containers run $(autotag dwarf_star) /bin/bash
```

## Server

Start a local OpenAI/Anthropic-compatible server:

```bash
jetson-containers run $(autotag dwarf_star) /opt/ds4/ds4-server --ctx 100000 --kv-disk-dir /tmp/ds4-kv --kv-disk-space-mb 8192
```

To run in detached/foreground mode so the server stays up:

```bash
jetson-containers run -d --name ds4-server $(autotag dwarf_star) /opt/ds4/ds4-server --ctx 100000 --kv-disk-dir /tmp/ds4-kv --kv-disk-space-mb 8192
```

## Benchmark

Measure prefill and generation throughput at context frontiers:

```bash
jetson-containers run $(autotag dwarf_star) /opt/ds4/ds4-bench \
  -m $(huggingface-downloader antirez/deepseek-v4-gguf/DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf) \
  --prompt-file /opt/ds4/speed-bench/promessi_sposi.txt \
  --ctx-start 2048 \
  --ctx-max 65536 \
  --step-incr 2048 \
  --gen-tokens 128
```

## Evaluation

Run the embedded capability evaluation suite:

```bash
jetson-containers run $(autotag dwarf_star) /opt/ds4/ds4-eval \
  -m $(huggingface-downloader antirez/deepseek-v4-gguf/DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf) \
  --trace /tmp/ds4-eval.txt
```

## Agent

Use the native coding agent:

```bash
jetson-containers run --workdir=/opt/ds4 $(autotag dwarf_star) /opt/ds4/ds4-agent \
  -m $(huggingface-downloader antirez/deepseek-v4-gguf/DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf) \
  --ctx 100000
```

## Available Binaries

| Binary | Description |
| :-- | :-- |
| `ds4` | CLI for interactive chat and one-shot inference |
| `ds4-server` | OpenAI/Anthropic-compatible HTTP server |
| `ds4-bench` | Benchmark tool for measuring throughput |
| `ds4-eval` | Capability evaluation tool |
| `ds4-agent` | Native coding agent |