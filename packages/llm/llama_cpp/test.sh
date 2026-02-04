#!/usr/bin/env bash
set -x

echo "TESTING LLAMA_CPP"

llama-cli -hf Qwen/Qwen3-0.6B-GGUF:Q8_0 --jinja -ngl 99  -sm row --temp 0.6 --top-k 20 --top-p 0.95 --min-p 0 --presence-penalty 1.5 -c 512 -n 128 --no-context-shift -p "Once upon a time," --single-turn
