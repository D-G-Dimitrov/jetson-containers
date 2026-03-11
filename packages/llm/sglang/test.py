import sglang as sgl


def main():
    llm = sgl.Engine(
        model_path="Qwen/Qwen3-0.6B",
        dtype="half",
        mem_fraction_static=0.5,
        disable_cuda_graph=True
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
        print("Generated text: ", end="", flush=True)

        # Use stream=True to get a generator that yields chunks instantly
        response_generator = llm.generate(prompt, sampling_params, stream=True)

        for chunk in response_generator:
            # Print each token as soon as it is generated
            print(chunk["text"], end="", flush=True)

        print("\n" + "-" * 40 + "\n")


if __name__ == "__main__":
    main()
