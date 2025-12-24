#!/usr/bin/env python3

import time
from random import randint, seed

from minisgl.core import SamplingParams
from minisgl.llm import LLM

def main():
    seed(0)
    # align the hyperparameters
    llm = LLM(
        "Qwen/Qwen3-0.6B",
        max_seq_len_override=4096,
        max_extend_tokens=16384,
        cuda_graph_max_bs=256,
        memory_ratio=0.5
    )

    sampling_params = [
        SamplingParams(temperature=0.6, max_tokens=50),
        SamplingParams(temperature=0.1, max_tokens=50)
    ]

    prompts = [
        "Ahoy! How many helicopters can a human eat in one sitting?",
        "Avast! What's the future of AI?",
    ]

    outputs = llm.generate(prompts, sampling_params)
    for output in outputs:
        print(output['text'])

if __name__ == "__main__":
    main()
