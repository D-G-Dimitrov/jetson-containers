import sglang as sgl
from sglang.utils import async_stream_and_merge, stream_and_merge


def main():
    llm = sgl.Engine(
        model_path="Qwen/Qwen3-0.6B-FP8",
        mem_fraction_static=0.5
    )
    prompts = [
        "Ahoy! How many helicopters can a human eat in one sitting?",
        "Avast! What's the future of AI?",
    ]

    sampling_params = {
        "temperature": 0.6,
        "top_p": 0.9,
        "max_new_tokens": 50,
    }

    for prompt in prompts:
        print(f"Prompt: {prompt}")
        merged_output = stream_and_merge(llm, prompt, sampling_params)
        print("Generated text:", merged_output)
        print()


if __name__ == "__main__":
    main()
