* ds4 (DwarfStar) from https://github.com/antirez/ds4 with CUDA enabled (found under `/opt/ds4`)

DwarfStar is a small native inference engine optimized first for DeepSeek V4 Flash.
It also supports GLM 5.2 and, on very high-memory machines, DeepSeek V4 PRO.
It is self-contained and deliberately narrow, not a general GGUF runner.

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
