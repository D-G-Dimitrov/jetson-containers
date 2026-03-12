import os
from jetson_containers import update_dependencies

def vllm_omni(version, branch, repo=None, depends=None, requires=None, default=False):
    name = 'vllm-omni'
    pkg = package.copy()

    if requires:
        pkg['requires'] = requires

    if depends:
        pkg['depends'] = update_dependencies(pkg['depends'], depends)

    pkg['name'] = f'{name}:{version}'

    pkg['build_args'] = {
        'VLLM_OMNI_VERSION': version,
        'VLLM_OMNI_REPO': repo,
        'VLLM_OMNI_BRANCH': branch,
    }

    builder = pkg.copy()
    builder['name'] = f'{name}:{version}-builder'
    builder['build_args'] = {**pkg['build_args'], **{'FORCE_BUILD': 'on'}}
    builder['name'] = f'{name}:{version}-builder'

    if default:
        pkg['alias'] = name
        builder['alias'] = f'{name}:builder'

    return pkg, builder


package = [
    vllm_omni('0.14.0', 'release/v0.14.0',  depends=['vllm'] , repo='vllm-project/vllm-omni',default=False),
    vllm_omni('0.16.0', 'release/v0.16.0' ,depends=['vllm:0.16.0'] , repo='vllm-project/vllm-omni',default=False),
    vllm_omni('0.17.0', 'v0.17.0rc1' ,depends=['vllm:0.17.0'] , repo='vllm-project/vllm-omni',default=True)
]
