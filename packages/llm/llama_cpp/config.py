from jetson_containers import CUDA_ARCHITECTURES

def get_latest_release_tag(repo_path):
    """Get the latest release tag from a GitHub repository.

    Args:
        repo_path: GitHub repo path like user/repo

    Returns:
        str: Latest release tag name
    """

    # Call GitHub API
    api_url = f"https://api.github.com/repos/{repo_path}/releases/latest"
    import requests
    response = requests.get(api_url)

    if response.status_code == 200:
        return response.json()['tag_name']
    else:
        raise Exception(
            f"Failed to fetch release from {api_url} : {response.status_code} - {response.text}")

def llama_cpp(version,  repo=None, default=False):

    if repo and version == 'stable':
        version = get_latest_release_tag(repo)
        # strip the starting v if exists
        if version.startswith('v'):
            version = version[1:]

    pkg = package.copy()

    pkg['name'] = f'llama_cpp:{version}'

    pkg['build_args'] = {
        'LLAMA_CPP_REPO': repo,
        'LLAMA_CPP_VERSION': version,
        'CUDA_ARCHITECTURES': ';'.join([str(x) for x in CUDA_ARCHITECTURES]),
    }

    test_model = "bartowski/Qwen_Qwen3-1.7B-GGUF/Qwen_Qwen3-1.7B-Q4_K_M.gguf"

    pkg['test'] = pkg['test'] + [
        f"llama-cli -hf Qwen/Qwen3-0.6B-GGUF:Q8_0 --jinja --color -ngl 99 -fa -sm row --temp 0.6 --top-k 20 --top-p 0.95 --min-p 0 --presence-penalty 1.5 -c 40960 -n 32768 --no-context-shift"
    ]

    builder = pkg.copy()
    builder['name'] = builder['name'] + '-builder'
    builder['build_args'] = {**builder['build_args'], 'FORCE_BUILD': 'on'}

    if default:
        pkg['alias'] = 'llama_cpp'
        builder['alias'] = 'llama_cpp:builder'

    return pkg, builder

package = [
    llama_cpp('stable', repo='ggml-org/llama.cpp', default=True)
]
