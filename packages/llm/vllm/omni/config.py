import os
from jetson_containers import update_dependencies

def vllm_omni(version, repo=None, depends=None, requires=None, default=False):
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
    }

    builder = pkg.copy()

    builder['name'] = f'{name}:{version}-builder'

    if default:
        pkg['alias'] = name
        builder['alias'] = f'{name}:builder'

    return pkg, builder


package = [
    vllm_omni('0.14.0', depends=['vllm'] , repo='vllm-project/vllm-omni',default=True),
]
